import 'package:flutter/material.dart';
import 'package:flutter_auth/components/like_button.dart';
import 'package:iconly/iconly.dart';

class VideoOverlay extends StatelessWidget {
  final String clubName;
  final String description;
  final String location;
  final int likeCount;
  final int commentCount;
  final bool isRsvped;
  final VoidCallback onCommentTap;
  final VoidCallback onRsvpTap;
  final String mediaId;

  const VideoOverlay({
    Key? key,
    required this.mediaId,
    required this.clubName,
    required this.description,
    required this.location,
    required this.likeCount,
    required this.commentCount,
    required this.isRsvped,
    required this.onCommentTap,
    required this.onRsvpTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        // Bottom‑left info panel
        Positioned(
          left: 16,
          bottom: 90,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clubName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white),
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
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
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
          right: 16,
          top: screenHeight * 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LikeButton(mediaId: mediaId),
              const SizedBox(height: 10),
              _OverlayButton(
                icon: IconlyBold.chat,
                count: commentCount,
                color: Colors.white,
                onTap: onCommentTap,
              ),
              const SizedBox(height: 90),
              _OverlayButton(
                icon: isRsvped ? IconlyBold.tick_square : IconlyBold.calendar,
                count: 0,
                color: Colors.red,
                active: isRsvped,
                onTap: onRsvpTap,
              ),
              Text(
                "RSVP",
                style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                color: Color.fromARGB(255, 255, 255, 255),
                fontSize: 13,
              ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, -5),
                ),
              ],
            ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 38,
              color: active ? Colors.greenAccent : color,
            ),
            if (count >= 0) ...[
              const SizedBox(height: 2),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
