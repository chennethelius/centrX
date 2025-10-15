import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../components/video_overlay.dart';
import '../services/video_cache_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class EventsPage extends StatefulWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final PageController _pageController;
  late final StreamSubscription<QuerySnapshot> _eventSub;
  
  /// Safely checks if a video controller is still usable
  bool _isControllerValid(VideoPlayerController? controller) {
    if (controller == null || !mounted) return false;
    try {
      // Try to access the value property - this will throw if disposed
      controller.value;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Safely executes a controller operation
  void _safeControllerOperation(VideoPlayerController? controller, VoidCallback operation) {
    if (!_isControllerValid(controller)) return;
    try {
      operation();
    } catch (e) {
      if (kDebugMode) debugPrint('Video controller operation failed: $e');
    }
  }

  // Keep both the raw docs and the player controllers
  final List<QueryDocumentSnapshot> _mediaDocs = [];
  // We keep only the URLs and fetch controllers from the pool.
  List<String> _videoUrls = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    
    if (kDebugMode) {
      debugPrint('EventsPage initialized - cancelling pending pause operations');
    }
    
    // Cancel any pending pause operations when returning to page
    VideoControllerPool.instance.cancelPendingPause();
    
  final savedIndex = VideoControllerPool.instance.lastIndex ?? 0;
  _currentIndex = savedIndex;
  _pageController = PageController(initialPage: savedIndex);
    // After first frame, if saved index differs from controller's page, try to jump.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final idx = (VideoControllerPool.instance.lastIndex ?? 0);
      if (_pageController.hasClients && _pageController.page?.round() != idx) {
        _pageController.jumpToPage(idx);
      }
    });
    // Listen to /media and rebuild on every change
    _eventSub = _firestore
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(_onMediaSnapshot);
  }

  void _onMediaSnapshot(QuerySnapshot snap) {
    _mediaDocs.clear();
    _mediaDocs.addAll(snap.docs);
    // 1) Build the new list of URLs
    final newUrls = snap.docs
        .map((doc) => 
          (doc.data() as Map<String, dynamic>)['mediaUrl'] as String?
        )
        .whereType<String>()
        .toList();

    // 2) If URLs haven’t actually changed, do nothing
    if (listEquals(newUrls, _videoUrls)) return;

    // 3) Otherwise update your stored list and rebuild controllers
    _videoUrls = newUrls;
    _rebuildControllers(_videoUrls);
  }


  void _rebuildControllers(List<String> urls) {
    // Prefetch new URLs into the pool; let the UI bind lazily.
    VideoControllerPool.instance.prefetch(urls);
    if (!mounted) return;
    setState(() {});
    // Auto-play the first item if present.
    if (urls.isNotEmpty) {
      // Determine which url to activate: saved last or first.
      final initialIndex = (VideoControllerPool.instance.lastIndex ?? 0)
          .clamp(0, urls.length - 1);
      final initialUrl = urls[initialIndex];
      VideoControllerPool.instance.lastIndex = initialIndex;
      VideoControllerPool.instance.lastUrl = initialUrl;
      VideoControllerPool.instance.makeSticky(initialUrl);
      VideoControllerPool.instance.getController(initialUrl).then((c) {
        if (!mounted) return;
        // Always start from beginning when (re)activating within the feed
        c.pause();
        c.seekTo(Duration.zero);
        c.play();
        // Pause the rest just in case some were warm already.
        VideoControllerPool.instance.pauseAllExcept(initialUrl);
      });
    }
  }


  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('EventsPage disposing - immediately pausing all videos');
    }
    
    // Immediately pause all videos when leaving the page
    VideoControllerPool.instance.pauseAll();
    _eventSub.cancel(); 
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // show spinner until we have both docs and controllers
  if (_mediaDocs.isEmpty || _videoUrls.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videoUrls.length,
        onPageChanged: (index) {
          final prev = _currentIndex;
          _currentIndex = index;
          if (index < 0 || index >= _videoUrls.length) return;
          final activeUrl = _videoUrls[index];
          VideoControllerPool.instance.lastIndex = index;
          VideoControllerPool.instance.lastUrl = activeUrl;
          VideoControllerPool.instance.makeSticky(activeUrl);
          VideoControllerPool.instance.pauseAllExcept(activeUrl);

          // Reset previous page so revisiting starts from 0
          if (prev >= 0 && prev < _videoUrls.length) {
            final prevUrl = _videoUrls[prev];
            final prevCtrl = VideoControllerPool.instance.lookup(prevUrl);
            if (prevCtrl != null) {
              prevCtrl.pause();
              prevCtrl.seekTo(Duration.zero);
            }
          }

          // Start the active one from the beginning
          VideoControllerPool.instance.getController(activeUrl).then((c) {
            if (!mounted) return;
            c.pause();
            c.seekTo(Duration.zero);
            c.play();
          });
        },
        itemBuilder: (context, index) {
          final url = _videoUrls[index];
          final data = _mediaDocs[index].data() as Map<String, dynamic>;

          // Extract the overlay fields from your media doc:
          final title   = data['title']    as String? ?? 'Unknown Club';
          final desc       = data['description'] as String? ?? '';
          final location  = data['location']     as String? ?? '';
          final likeCount = data['likeCount']    as int? ?? 0;
          final clubId = data['ownerId'] as String? ?? '';
          final eventId = data['eventId'] as String? ?? '';

          /*
          final attendance = List<String>.from(data['attendanceList'] as List<dynamic>? ?? []);
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          final isRsvped = currentUserId != null && attendance.contains(currentUserId);*/
          return FutureBuilder<VideoPlayerController>(
              future: VideoControllerPool.instance.getController(url),
              builder: (context, snapshot) {
                final controller = snapshot.data;
                final isControllerValid = _isControllerValid(controller);
                final isReady = controller != null && 
                               isControllerValid && 
                               controller.value.isInitialized;
                
                // Don't create ValueListenableBuilder with disposed controller
                if (!isControllerValid) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    final c = controller;
                    if (c == null) return;
                    _safeControllerOperation(c, () {
                      final isPlaying = c.value.isPlaying;
                      isPlaying ? c.pause() : c.play();
                    });
                  },
                  child: isReady
                      ? ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: controller,
                          builder: (context, value, _) {
                            // Additional safety check inside builder
                            if (!mounted) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            return Stack(
                              children: [
                                // 1) Letterboxed, centered video
                                Container(
                                  color: Colors.black,
                                  child: Center(
                                    child: AspectRatio(
                                      aspectRatio: value.aspectRatio,
                                      child: VideoPlayer(controller),
                                    ),
                                  ),
                                ),
                                // 2) Simple overlay at bottom
                                VideoOverlay(
                                  eventId: eventId,
                                  clubId: clubId,
                                  title: title,
                                  description: desc,
                                  location: location,
                                  likeCount: likeCount,
                                  isPlaying: value.isPlaying,
                                  onPlayPauseTap: () {
                                    _safeControllerOperation(controller, () {
                                      value.isPlaying ? controller.pause() : controller.play();
                                    });
                                  },
                                  position: value.position,
                                  totalDuration: value.duration,
                                  onSeek: (to) {
                                    _safeControllerOperation(controller, () {
                                      controller.seekTo(to);
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        )
                      : const Stack(
                          children: [
                            Center(child: CircularProgressIndicator()),
                          ],
                        ),
                );
              },
            );
        },
      ),
    );
  }
}
