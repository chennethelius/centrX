import 'package:flutter/material.dart';
import 'package:flutter_auth/components/like_button.dart';
import 'package:flutter_auth/components/rsvp_button.dart';
import 'package:flutter_auth/components/comment_button.dart';
import 'package:iconly/iconly.dart';
import '../theme/theme_extensions.dart';

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
    
    // Responsive sizing based on screen proportions
    final horizontalPadding = width * 0.04; // 4% of screen width
    final bottomOffset = height * 0.12; // 12% from bottom
    final actionButtonsOffset = height * 0.45; // 45% from top
    
    return Stack(
      children: [
        // Bottom‑left info panel with backdrop
        Positioned(
          left: horizontalPadding,
          right: width * 0.25, // Leave space for action buttons
          bottom: bottomOffset,
          child: Container(
            padding: EdgeInsets.all(width * 0.03),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(width * 0.03),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: width * 0.045, // Proportional to screen width
                    height: 1.2,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: height * 0.005),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: width * 0.035,
                    height: 1.3,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: height * 0.008),
                Row(
                  children: [
                    Icon(
                      IconlyBold.location,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: width * 0.035,
                    ),
                    SizedBox(width: width * 0.01),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: width * 0.03,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ],
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

        // Right side action buttons with improved layout
        Positioned(
          right: horizontalPadding,
          top: actionButtonsOffset,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LikeButton(eventId: eventId),
              SizedBox(height: height * 0.02),
              CommentButton(
                icon: IconlyBold.chat,
                count: commentCount,
                color: Colors.white,
                onTap: onCommentTap,
              ),
              SizedBox(height: height * 0.04),
              // RSVP button positioned at bottom of action column
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
