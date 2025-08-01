import 'package:flutter/material.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:iconly/iconly.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CrystalNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        CrystalNavigationBarItem(
          icon: IconlyBold.home,
          unselectedIcon: IconlyLight.home,
          selectedColor: Colors.white,
        ),
        CrystalNavigationBarItem(
          icon: IconlyBold.calendar,
          unselectedIcon: IconlyLight.calendar,
          selectedColor: Colors.red.withValues(alpha: 0.7),
        ),
        CrystalNavigationBarItem(
          icon: IconlyBold.star,
          unselectedIcon: IconlyLight.star,
          selectedColor: const Color.fromARGB(255, 102, 201, 247),
        ),
        CrystalNavigationBarItem(
          icon: IconlyBold.scan,
          unselectedIcon: IconlyBold.scan,
          selectedColor: Colors.yellow,
        ),
      ],
      backgroundColor: Colors.black.withValues(alpha: 0.3),
      unselectedItemColor: Colors.white70,
      outlineBorderColor: Colors.white,
      borderWidth: 2,
    );
  }
}
