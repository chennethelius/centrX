import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../components/video_overlay.dart';
import '../services/social_button_services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PageController _pageController = PageController();
  late final StreamSubscription<QuerySnapshot> _mediaSub;

  // Keep both the raw docs and the player controllers
  final List<QueryDocumentSnapshot> _mediaDocs = [];
  final List<VideoPlayerController> _videoControllers = [];
  List<String> _videoUrls = []; 

  @override
  void initState() {
    super.initState();
    // Listen to /media and rebuild on every change
    _mediaSub = _firestore
        .collection('media')
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
  // 1) Tear down old controllers
  for (var c in _videoControllers) {
    c.pause();
    c.dispose();
  }
  _videoControllers.clear();

  // 2) Build new controllers
  for (var url in urls) {
    final controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..setLooping(true);

    controller.initialize().then((_) {
      // Only update UI if still in the tree
      if (!mounted) return;

      // Auto‑play the first video
      if (_videoControllers.isEmpty) {
        controller.play();
      }
      setState(() {});
    });

    _videoControllers.add(controller);
  }
  // 3) Trigger a rebuild so PageView picks up the new length
  if (!mounted) return;
  setState(() {});
}


  @override
  void dispose() {
    for (var c in _videoControllers) {
      c.dispose();
    }
    _mediaSub.cancel(); 
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // show spinner until we have both docs and controllers
    if (_mediaDocs.isEmpty || _videoControllers.isEmpty) {
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
        itemCount: _videoControllers.length,
        onPageChanged: (index) {
          // pause all except the current one
          for (var c in _videoControllers) {
            c.pause();
          }
          _videoControllers[index].play();
        },
        itemBuilder: (context, index) {
          final controller = _videoControllers[index];
          final data = _mediaDocs[index].data() as Map<String, dynamic>;

          // Extract the overlay fields from your media doc:
          final title   = data['title']    as String? ?? 'Unknown Club';
          final desc       = data['description'] as String? ?? '';
          final location  = data['location']     as String? ?? '';
          final likeCount = data['likeCount']    as int? ?? 0;
          final commentCount = data['commentCount']    as int? ?? 0;
          final mediaId = data['mediaId'] as String? ?? '';
          final clubId = data['ownerId'] as String? ?? '';
          final eventId = data['eventId'] as String? ?? '';

          /*
          final attendance = List<String>.from(data['attendanceList'] as List<dynamic>? ?? []);
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          final isRsvped = currentUserId != null && attendance.contains(currentUserId);*/
          return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                // toggle play/pause
                controller.value.isPlaying
                  ? controller.pause()
                  : controller.play();
              },
            child: Stack(
              children: [
                // 1) Letterboxed, centered video
                Container(
                  color: Colors.black,
                  child: Center(
                    child: controller.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: VideoPlayer(controller),
                          )
                        : const CircularProgressIndicator(),
                  ),
                ),
            
                // 2) Simple overlay at bottom
                VideoOverlay(
                  eventId: eventId,
                  clubId: clubId,
                  mediaId: mediaId,
                  title:    title,
                  description: desc,
                  location:    location,
                  likeCount: likeCount,
                  commentCount: commentCount,
                  onCommentTap:() => (SocialButtonServices.showComments(context, mediaId)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
