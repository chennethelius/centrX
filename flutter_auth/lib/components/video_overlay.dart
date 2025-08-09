import 'package:flutter/material.dart';
import 'package:flutter_auth/components/like_button.dart';
import 'package:flutter_auth/components/rsvp_button.dart';
import 'package:iconly/iconly.dart';

class VideoOverlay extends StatelessWidget {
  final String title;
  final String clubId;
  final String eventId;
  final String description;
  final String location;
  final int likeCount;
  final int commentCount;
  final VoidCallback onCommentTap;

  const VideoOverlay({
    Key? key,
    required this.clubId,
    required this.eventId,
    required this.title,
    required this.description,
    required this.location,
    required this.likeCount,
    required this.commentCount,
    required this.onCommentTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    final isSmallScreen = width < 360;

    return Stack(
      children: [
        // Bottom‑left info panel
        Positioned(
          left: isSmallScreen ? 12 : 16,
          right: isSmallScreen ? 12 : 16,
          bottom: isSmallScreen ? 70 : 90,
          child: Container(
            padding: const EdgeInsets.all(12),
            /*decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(8),
            ),*/
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 16 : 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isSmallScreen ? 11 : 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Middle‑right action buttons
        Positioned(
          right: isSmallScreen ? 12 : 16,
          top: height * 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LikeButton(eventId: eventId,),
              const SizedBox(height: 10),
              _OverlayButton(
                icon: IconlyBold.chat,
                count: commentCount,
                color: Colors.white,
                onTap: onCommentTap,
              ),
              SizedBox(height: isSmallScreen ? 70 : 90),
              RsvpButton(
                clubId: clubId,
                eventId: eventId,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _OverlayButton({
    Key? key,
    required this.icon,
    required this.count,
    required this.onTap,
    required this.color,
    this.active = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 360;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: isSmallScreen ? 32 : 38,
              color: active ? Colors.greenAccent : color,
            ),
            if (count >= 0) ...[
              const SizedBox(height: 2),
              Text(
                count.toString(),
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  fontSize: isSmallScreen ? 11 : 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
