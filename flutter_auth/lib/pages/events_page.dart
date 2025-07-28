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
    _firestore
        .collection('media')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(_onMediaSnapshot);
  }

  void _onMediaSnapshot(QuerySnapshot snap) {
    final urls = snap.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['mediaUrl'] as String?)
        .whereType<String>()
        .toList();
    _rebuildControllers(urls);
  }

  void _rebuildControllers(List<String> urls) {
    for (var c in _videoControllers) {
      c.pause();
      c.dispose();
    }
    _videoControllers.clear();

    for (var url in urls) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url))
        ..setLooping(true);
      controller.initialize().then((_) {
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
    // While loading or if empty, show a spinner
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
          // Pause all except the current one
          for (var c in _videoControllers) {
            c.pause();
          }
          _videoControllers[index].play();
        },
        itemBuilder: (context, index) {
          final controller = _videoControllers[index];

          return GestureDetector(
            onTap: () {
              setState(() {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              });
            },
            child: Container(
              color: Colors.black, // black background
              child: Center(
                child: controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller),
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          );
        },
      ),
    );
  }
}
