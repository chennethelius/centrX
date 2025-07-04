import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'dart:ui';

class EventsPage extends StatefulWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage>
    with SingleTickerProviderStateMixin {
  // Like / RSVP state
  bool isLiked = false;
  bool isRsvped = false;
  int likeCount = 234;
  int commentCount = 56;
  int shareCount = 12;

  // Animation fields
  late final AnimationController _scrollController;
  late final Animation<double> _scrollAnimation;

  // Scroll tracking
  double _scrollOffset = 0.0;
  bool _isScrolling = false;
  late PageController _pageController;

  // Sample events data
  final List<Map<String, dynamic>> events = [
    {
      'title': 'Tech Conference 2024',
      'description': 'Join us for the biggest tech event of the year! Network with industry leaders and discover the latest innovations.',
      'date': 'Dec 15, 2024 • 2:00 PM',
      'isLive': true,
      'gradient': [Colors.purple.shade300, Colors.blue.shade400, Colors.teal.shade300],
    },
    {
      'title': 'Design Workshop',
      'description': 'Learn the latest design trends and techniques from industry experts. Hands-on workshop with real projects.',
      'date': 'Dec 20, 2024 • 10:00 AM',
      'isLive': false,
      'gradient': [Colors.orange.shade300, Colors.red.shade400, Colors.pink.shade300],
    },
    {
      'title': 'Startup Pitch Night',
      'description': 'Watch innovative startups pitch their ideas to investors. Network with entrepreneurs and VCs.',
      'date': 'Dec 22, 2024 • 7:00 PM',
      'isLive': true,
      'gradient': [Colors.green.shade300, Colors.teal.shade400, Colors.blue.shade300],
    },
    {
      'title': 'Music Festival',
      'description': 'Experience the best live music performances from top artists around the world.',
      'date': 'Dec 25, 2024 • 6:00 PM',
      'isLive': false,
      'gradient': [Colors.indigo.shade300, Colors.purple.shade400, Colors.pink.shade300],
    },
    {
      'title': 'Food & Wine Expo',
      'description': 'Taste exquisite cuisines and wines from renowned chefs and sommeliers.',
      'date': 'Dec 28, 2024 • 12:00 PM',
      'isLive': true,
      'gradient': [Colors.amber.shade300, Colors.orange.shade400, Colors.deepOrange.shade300],
    },
  ];

  int currentEventIndex = 0;

  @override
  void initState() {
    super.initState();

    // Initialize PageController
    _pageController = PageController(
      initialPage: currentEventIndex,
      viewportFraction: 1.0,
    );

    // Animation controller for micro-interactions
    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scrollAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _scrollController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      currentEventIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        itemCount: events.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildEventCard(event, index);
        },
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, int index) {
    return Stack(
      children: [
        // Video/Background
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: event['gradient'],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  IconlyBold.play,
                  size: 80,
                  color: Colors.white.withOpacity(0.8),
                ),
                const SizedBox(height: 16),
                Text(
                  'Event Video',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to play',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Top overlay gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Event counter
        Positioned(
          top: 60,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${index + 1}/${events.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Bottom overlay gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 280,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
        ),

        // Side action buttons
        Positioned(
          right: 16,
          bottom: 180,
          child: Column(
            children: [
              _buildActionButton(
                icon: isLiked ? IconlyBold.heart : IconlyLight.heart,
                count: likeCount,
                color: isLiked ? Colors.red : Colors.white,
                onTap: () {
                  setState(() {
                    isLiked = !isLiked;
                    likeCount += isLiked ? 1 : -1;
                  });
                  _scrollController.forward().then((_) {
                    _scrollController.reverse();
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                icon: IconlyLight.chat,
                count: commentCount,
                color: Colors.white,
                onTap: () => _showCommentsBottomSheet(),
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                icon: IconlyLight.send,
                count: shareCount,
                color: Colors.white,
                onTap: () {
                  // Share functionality
                  _scrollController.forward().then((_) {
                    _scrollController.reverse();
                  });
                },
              ),
              const SizedBox(height: 32),
              _buildRsvpButton(),
            ],
          ),
        ),

        // Event information
        Positioned(
          bottom: 100,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event['isLive'])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade500,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE EVENT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                event['title'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    IconlyLight.calendar,
                    size: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    event['date'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Scroll indicator (optional - shows current position)
        Positioned(
          right: 8,
          top: MediaQuery.of(context).size.height * 0.3,
          child: Container(
            width: 3,
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  top: (MediaQuery.of(context).size.height * 0.4 / events.length) * index,
                  child: Container(
                    width: 3,
                    height: MediaQuery.of(context).size.height * 0.4 / events.length,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _scrollAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_scrollAnimation.value * 0.1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 48,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 28, color: color),
                      const SizedBox(height: 4),
                      Text(
                        _formatCount(count),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRsvpButton() {
    return GestureDetector(
      onTap: () {
        setState(() => isRsvped = !isRsvped);
        _scrollController.forward().then((_) {
          _scrollController.reverse();
        });
      },
      child: AnimatedBuilder(
        animation: _scrollAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_scrollAnimation.value * 0.1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 48,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isRsvped
                        ? Colors.green.withOpacity(0.3)
                        : Colors.purple.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isRsvped
                          ? Colors.green.withOpacity(0.5)
                          : Colors.purple.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isRsvped ? IconlyBold.tick_square : IconlyLight.calendar,
                        size: 24,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isRsvped ? 'RSVP\'d' : 'RSVP',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _showCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(IconlyLight.close_square, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 10, // Sample comments
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey.shade300,
                              child: Text(
                                'U${index + 1}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'User ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'This is a sample comment for the event. Looking forward to attending!',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}