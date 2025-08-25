import 'package:flutter/material.dart';
import 'package:flutter_auth/components/like_button.dart';
import 'package:flutter_auth/components/rsvp_button.dart';
import 'package:flutter_auth/components/comment_button.dart';
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
  final bool isPlaying;
  final VoidCallback onPlayPauseTap;
  // Mini controller inputs
  final Duration position;
  final Duration totalDuration;
  final ValueChanged<Duration> onSeek;

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
    required this.isPlaying,
    required this.onPlayPauseTap,
  required this.position,
  required this.totalDuration,
  required this.onSeek,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    
    // Responsive sizing based on screen proportions
    final horizontalPadding = width * 0.04; // 4% of screen width
    final leftPadding = width * 0.02; // 2% of screen width for description panel
    final bottomOffset = height * 0.12; // 12% from bottom
    final actionButtonsOffset = height * 0.45; // 45% from top
    
  return Stack(
      children: [
        // Center play icon
        Positioned.fill(
          child: Center(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: isPlaying ? 0.0 : 0.7, // Hide when playing, show when paused
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: width * 0.2, // Larger size - 20% of screen width
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Bottom‑left info panel with backdrop
        Positioned(
          left: leftPadding,
          right: width * 0.2, // Reduced from 0.25 to give more space for description
          bottom: bottomOffset,
          child: Container(
            padding: EdgeInsets.all(width * 0.03),
            decoration: BoxDecoration(
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

  // Bottom mini controller (TikTok-style)
        Positioned(
          left: 0,
          right: 0,
          bottom: height * 0.075,
          child: _MiniController(
            position: position,
            total: totalDuration,
            onSeek: onSeek,
          ),
        ),
      ],
    );
  }
}

class _MiniController extends StatelessWidget {
  const _MiniController({
    required this.position,
    required this.total,
    required this.onSeek,
  });

  final Duration position;
  final Duration total;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final totalMs = total.inMilliseconds;
    final posMs = position.inMilliseconds.clamp(0, totalMs == 0 ? 1 : totalMs);
    final canScrub = totalMs > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      // Transparent background for a cleaner, TikTok-like look
      color: Colors.transparent,
  child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
              ),
              child: Slider(
                value: posMs.toDouble(),
                min: 0,
                max: (totalMs == 0 ? 1 : totalMs).toDouble(),
                onChanged: canScrub
                    ? (v) => onSeek(Duration(milliseconds: v.round()))
                    : null,
              ),
            ),
          ],
        ),
    );
  }
}
