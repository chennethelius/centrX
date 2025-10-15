import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

/// Helper for conditional logging
void _log(String message) {
  if (kDebugMode) {
    debugPrint('VideoControllerPool: $message');
  }
  // In production, you could send to Firebase Crashlytics or other logging service
  // FirebaseCrashlytics.instance.log('VideoControllerPool: $message');
}

/// A small pool that keeps VideoPlayerControllers hot across screens.
///
/// - Controllers are keyed by the video URL.
/// - Files are cached on disk via flutter_cache_manager.
/// - Limits max active controllers to avoid memory bloat.
/// - Evicts LRU controllers when over capacity.
class VideoControllerPool {
  VideoControllerPool._();
  static final VideoControllerPool instance = VideoControllerPool._();

  /// Tune this based on target devices. Start small.
  int maxControllers = 4;
  
  /// Delay before disposing non-sticky controllers (in seconds)
  int disposalDelay = 3;
  
  /// Timer for delayed disposal
  Timer? _disposalTimer;

  /// Persist lightweight UI state: last viewed video in the feed.
  int? lastIndex;
  String? lastUrl;

  final _map = <String, _Entry>{};
  final _lru = <String>[]; // most recent at end
  final _initLocks = <String, Future<VideoPlayerController>>{}; // coalesce inits

  /// Get (and warm) a controller for the URL. Reuses if available.
  Future<VideoPlayerController> getController(String url) async {
    // Existing, return fast.
    final existing = _map[url];
    if (existing != null) {
      _touch(url);
      return existing.controller;
    }

    // If an init is already in-flight for this url, await it.
    final inflight = _initLocks[url];
    if (inflight != null) {
      return inflight;
    }

    final completer = Completer<VideoPlayerController>();
    _initLocks[url] = completer.future;

    try {
      // Fetch file from cache (or network). This ensures disk cache.
      final fileInfo = await DefaultCacheManager().getFileFromCache(url) ??
          await DefaultCacheManager().downloadFile(url);
      final File file = fileInfo.file;

      // Prefer file controller (seeks start faster and survives temp offline).
      final controller = VideoPlayerController.file(file)
        ..setLooping(true);
      await controller.initialize();

      // Store in pool.
  _map[url] = _Entry(controller: controller);
      _touch(url);
      _enforceLimit();

      completer.complete(controller);
      return controller;
    } catch (e) {
      _log('Init error for $url: $e');
      // Fallback to network controller if cache/file failed.
      try {
        final controller = VideoPlayerController.networkUrl(Uri.parse(url))
          ..setLooping(true);
        await controller.initialize();
  _map[url] = _Entry(controller: controller);
        _touch(url);
        _enforceLimit();
        completer.complete(controller);
        return controller;
      } catch (e2) {
        _log('Network fallback failed for $url: $e2');
        completer.completeError(e2);
        rethrow;
      }
    } finally {
      _initLocks.remove(url);
    }
  }

  /// Mark one as recently used
  void _touch(String url) {
    _lru.remove(url);
    _lru.add(url);
  }

  void _enforceLimit() {
    while (_lru.length > maxControllers) {
      final evictUrl = _lru.first;
      _lru.removeAt(0);
      final entry = _map.remove(evictUrl);
      entry?.controller.dispose();
    }
  }

  /// Optionally prefetch a list of URLs ahead of time (silent warmup).
  Future<void> prefetch(List<String> urls) async {
    for (final url in urls) {
      // Fire and forget, but coalesce via _initLocks
      unawaited(getController(url));
    }
  }

  /// Pause all controllers except for the provided active one (if any).
  void pauseAllExcept(String? activeUrl) {
    _map.forEach((url, entry) {
      if (url != activeUrl) {
        try {
          if (_isControllerValid(entry.controller) && entry.controller.value.isPlaying) {
            entry.controller.pause();
            _log('Paused controller for: $url');
          }
        } catch (e) {
          _log('Error pausing controller for $url: $e');
        }
      }
    });
  }

  /// Dispose a single controller (e.g., video deleted) and remove from pool.
  void evict(String url) {
    final entry = _map.remove(url);
    _lru.remove(url);
    entry?.controller.dispose();
  }

  /// Dispose everything (e.g., on logout). Avoid calling on normal nav pops.
  void clear() {
    _disposalTimer?.cancel();
    for (final e in _map.values) {
      e.controller.dispose();
    }
    _map.clear();
    _lru.clear();
  }

  // Sticky support: keep only the current video's controller across routes.

  /// Make a url sticky (others become non-sticky).
  void makeSticky(String url) {
    _map.forEach((k, v) => v.sticky = (k == url));
  }

  /// Get if present without initializing.
  VideoPlayerController? lookup(String url) => _map[url]?.controller;

  /// Pause the sticky controller (if any).
  Future<void> pauseSticky() async {
    for (final e in _map.values) {
      if (e.sticky) {
        try {
          await e.controller.pause();
        } catch (_) {}
      }
    }
  }

  /// Pause all controllers (including sticky ones) when leaving the page
  Future<void> pauseNonSticky() async {
    _log('Pausing ALL ${_map.length} controllers when leaving page');

    for (final entry in _map.entries) {
      try {
        final controller = entry.value.controller;
        if (_isControllerValid(controller) && controller.value.isPlaying) {
          await controller.pause();
          _log('Paused controller for: ${entry.key}');
        }
      } catch (e) {
        _log('Error pausing controller for ${entry.key}: $e');
      }
    }

    _log('Paused all controllers, kept ${_map.length} controllers in memory');
  }
  
  /// Immediately dispose all non-sticky controllers (for immediate cleanup)
  Future<void> disposeNonStickyImmediate() async {
    _disposalTimer?.cancel();
    final toDispose = _map.entries.where((e) => !e.value.sticky).toList();
    for (final e in toDispose) {
      try {
        await e.value.controller.dispose();
      } catch (_) {}
      _map.remove(e.key);
      _lru.remove(e.key);
    }
  }
  
  /// Cancel any pending pause operations (when user returns quickly)
  void cancelPendingPause() {
    _disposalTimer?.cancel();
    _disposalTimer = null;
    _log('Cancelled pending pause operation');
  }
  
  /// Immediately pause all controllers (emergency stop)
  void pauseAll() {
    _log('Emergency pause of all ${_map.length} controllers');
    _map.forEach((url, entry) {
      try {
        if (_isControllerValid(entry.controller) && entry.controller.value.isPlaying) {
          entry.controller.pause();
          _log('Emergency paused: $url');
        }
      } catch (e) {
        _log('Error in emergency pause for $url: $e');
      }
    });
  }
  
  /// Helper method to check if controller is valid and not disposed
  bool _isControllerValid(VideoPlayerController? controller) {
    if (controller == null) return false;
    
    try {
      // Try to access the value - this will throw if disposed
      controller.value;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Configure the disposal delay (in seconds)
  void setDisposalDelay(int seconds) {
    disposalDelay = seconds;
    _log('Disposal delay set to ${seconds}s');
  }
}

class _Entry {
  _Entry({required this.controller});
  final VideoPlayerController controller;
  bool sticky = false;
}
