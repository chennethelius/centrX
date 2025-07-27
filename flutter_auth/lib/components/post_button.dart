import 'dart:ui';
import 'package:flutter/material.dart';

class PostEventButton extends StatelessWidget {
  /// The callback invoked when the button is pressed
  final VoidCallback onPressed;

  /// Icon to show inside the FAB
  final IconData icon;

  /// Size of the icon
  final double iconSize;

  const PostEventButton({
    Key? key,
    required this.onPressed,
    this.icon = Icons.add,
    this.iconSize = 28,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(255, 255, 255, 0.3),
                Color.fromRGBO(255, 255, 255, 0.2),
              ],
            ),
            borderRadius: BorderRadius.all(Radius.circular(16)),
            border: Border.fromBorderSide(
              BorderSide(
                color: Color.fromRGBO(255, 255, 255, 0.4),
                width: 1,
              ),
            ),
          ),
          child: FloatingActionButton(
            onPressed: onPressed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Icon(
              icon,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
