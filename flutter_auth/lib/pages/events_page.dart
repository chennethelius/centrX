// lib/pages/events_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PageController _pageController = PageController();
  final List<VideoPlayerController> _videoControllers = [];

  @override
  void initState() {
    super.initState();
    // Listen to /media collection and always rebuild controllers on change
    _firestore
        .collection('media')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(_onMediaSnapshot);
  }

  void _onMediaSnapshot(QuerySnapshot snap) {
    // Extract mediaUrl from each doc (no extension filter)
    final urls = snap.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['mediaUrl'] as String?)
        .whereType<String>()
        .toList();

    print('Extracted media URLs: $urls'); // debug

    // Rebuild controllers from whatever we found
    _rebuildControllers(urls);
  }

  void _rebuildControllers(List<String> urls) {
    // Dispose old controllers
    for (var c in _videoControllers) {
      c.pause();
      c.dispose();
    }
    _videoControllers.clear();

    // Create new controllers
    for (var url in urls) {
      print('Initializing controller for $url'); // debug
      final controller = VideoPlayerController.networkUrl(Uri.parse(url))
        ..setLooping(true);
      controller.initialize().then((_) {
        // Auto‑play the first video once ready
        if (_videoControllers.isEmpty) {
          controller.play();
        }
        setState(() {});
      });
      _videoControllers.add(controller);
    }

    setState(() {});
  }

  @override
  void dispose() {
    for (var c in _videoControllers) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoControllers.isEmpty) {
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
          // Pause all, then play the visible one
          for (var c in _videoControllers) {
            c.pause();
          }
          _videoControllers[index].play();
        },
        itemBuilder: (context, index) {
          final controller = _videoControllers[index];
          return GestureDetector(
            onTap: () {
              // Toggle play/pause
              setState(() {
                controller.value.isPlaying ? controller.pause() : controller.play();
              });
            },
            child: controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  )
                : const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
