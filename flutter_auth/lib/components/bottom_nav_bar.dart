import 'package:flutter/material.dart';
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
    // Dark mode when on calendar page (index 1) or scan page (index 3)
    final isDarkMode = currentIndex == 1 || currentIndex == 3;
    
    return Container(
      margin: EdgeInsets.only(
        left: context.spacingL,
        right: context.spacingL,
        bottom: context.spacingL,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.spacingS,
        vertical: context.spacingM,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? context.neutralBlack : context.neutralWhite,
        borderRadius: BorderRadius.circular(context.radiusXL),
        border: Border.all(
          color: isDarkMode 
              ? context.neutralGray.withValues(alpha: 0.3)
              : context.neutralGray.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavBarItem(
            icon: IconlyBold.home,
            unselectedIcon: IconlyLight.home,
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
            selectedColor: context.accentNavy,
            isDarkMode: isDarkMode,
          ),
          _NavBarItem(
            icon: IconlyBold.calendar,
            unselectedIcon: IconlyLight.calendar,
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
            selectedColor: context.errorRed,
            isDarkMode: isDarkMode,
          ),
          _NavBarItem(
            icon: IconlyBold.star,
            unselectedIcon: IconlyLight.star,
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
            selectedColor: context.infoBlue,
            isDarkMode: isDarkMode,
          ),
          _NavBarItem(
            icon: IconlyBold.scan,
            unselectedIcon: IconlyLight.scan,
            isSelected: currentIndex == 3,
            onTap: () => onTap(3),
            selectedColor: context.warningOrange,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final IconData icon;
  final IconData unselectedIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final bool isDarkMode;

  const _NavBarItem({
    required this.icon,
    required this.unselectedIcon,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    required this.isDarkMode,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? widget.selectedColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Icon with animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.isSelected ? widget.icon : widget.unselectedIcon,
                key: ValueKey(widget.isSelected),
                color: widget.isSelected
                    ? widget.selectedColor
                    : widget.isDarkMode 
                        ? context.neutralWhite.withValues(alpha: 0.7)
                        : context.neutralBlack.withValues(alpha: 0.5),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
