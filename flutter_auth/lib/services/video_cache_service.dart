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
        entry.controller.pause();
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

  /// Dispose all non-sticky controllers with a delay (e.g., on page dispose or page change).
  Future<void> disposeNonSticky() async {
    // Cancel any existing disposal timer
    _disposalTimer?.cancel();
    
    final nonStickyCount = _map.entries.where((e) => !e.value.sticky).length;
    if (nonStickyCount == 0) {
      _log('No non-sticky controllers to dispose');
      return;
    }
    
    _log('Scheduling disposal of $nonStickyCount controllers in ${disposalDelay}s');
    
    // Start a new timer for delayed disposal
    _disposalTimer = Timer(Duration(seconds: disposalDelay), () async {
      _log('Disposing non-sticky controllers after ${disposalDelay}s delay');
      final toDispose = _map.entries.where((e) => !e.value.sticky).toList();
      for (final e in toDispose) {
        try {
          await e.value.controller.dispose();
        } catch (_) {}
        _map.remove(e.key);
        _lru.remove(e.key);
      }
      _log('Disposed ${toDispose.length} controllers');
    });
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
  
  /// Cancel any pending disposal (useful when user returns quickly)
  void cancelPendingDisposal() {
    _disposalTimer?.cancel();
    _log('Cancelled pending disposal');
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
