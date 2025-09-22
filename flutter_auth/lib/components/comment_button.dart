import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/theme_extensions.dart';
import 'comments_sheet.dart';

class CommentButton extends StatelessWidget {
  final String eventId;
  final String eventTitle;
  final IconData? icon;
  final Color? color;
  final bool active;

  const CommentButton({
    Key? key,
    required this.eventId,
    required this.eventTitle,
    this.icon,
    this.color,
    this.active = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Match sizing with like button and RSVP button
    const iconSize = 38.0;
    const fontSize = 12.0;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .collection('comments')
          .snapshots(),
      builder: (context, snapshot) {
        // Default UI while loading or on error
        if (!snapshot.hasData) {
          return _buildButton(context, 0, iconSize, fontSize);
        }

        // Count total comments (including replies)
        final commentCount = snapshot.data!.docs.length;

        return _buildButton(context, commentCount, iconSize, fontSize);
      },
    );
  }

  Widget _buildButton(BuildContext context, int commentCount, double iconSize, double fontSize) {
    return GestureDetector(
      onTap: () => _showCommentsSheet(context),
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
              icon ?? IconlyBold.chat,
              size: iconSize,
              color: active ? context.accentNavy : (color ?? Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              _formatCount(commentCount),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color ?? Colors.white,
                fontSize: fontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(
        eventId: eventId,
        eventTitle: eventTitle,
      ),
    );
  }
  
  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}
