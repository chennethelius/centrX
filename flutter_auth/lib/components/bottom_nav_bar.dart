import 'package:flutter/material.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:iconly/iconly.dart';
import '../theme/theme_extensions.dart';

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
          selectedColor: context.accentNavy,
        ),
        CrystalNavigationBarItem(
          icon: IconlyBold.calendar,
          unselectedIcon: IconlyLight.calendar,
          selectedColor: context.errorRed,
        ),
        CrystalNavigationBarItem(
          icon: IconlyBold.star,
          unselectedIcon: IconlyLight.star,
          selectedColor: context.infoBlue,
        ),
        CrystalNavigationBarItem(
          icon: IconlyBold.scan,
          unselectedIcon: IconlyBold.scan,
          selectedColor: context.warningOrange,
        ),
      ],
      backgroundColor: context.neutralBlack.withValues(alpha: 0.3),
      unselectedItemColor: context.neutralMedium,
      outlineBorderColor: context.neutralGray,
      borderWidth: 2,
    );
  }
}
