import 'package:flutter/material.dart';
import '../theme/theme_extensions.dart';

class CommentButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const CommentButton({
    Key? key,
    required this.icon,
    required this.count,
    required this.onTap,
    required this.color,
    this.active = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Match sizing with like button and RSVP button
    final iconSize = 38.0; // Match like button and RSVP button
    final fontSize = 12.0; // Match like button and RSVP button

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
              size: iconSize,
              color: active ? context.accentNavy : color,
            ),
            const SizedBox(height: 4),
            if (count >= 0)
              Text(
                _formatCount(count),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: fontSize,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}
