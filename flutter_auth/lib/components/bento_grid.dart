import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

class BentoItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const BentoItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class BentoGrid extends StatelessWidget {
  final List<BentoItem> items;
  final double spacing;

  const BentoGrid({
    Key? key,
    required this.items,
    this.spacing = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 360;
        final isVerySmall = constraints.maxWidth < 120; // For side panel usage
        final columns = (isSmallScreen || isVerySmall) ? 1 : 2;
        final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: _BentoCard(item: item, isCompact: isVerySmall),
            );
          }).toList(),
        );
      },
    );
  }
}

class _BentoCard extends StatelessWidget {
  final BentoItem item;
  final bool isCompact;

  const _BentoCard({Key? key, required this.item, this.isCompact = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderRadius = isCompact ? 16.0 : 24.0;
    final padding = isCompact ? 12.0 : 20.0;
    final iconSize = isCompact ? 16.0 : 24.0;
    final iconPadding = isCompact ? 8.0 : 12.0;
    final valueSize = isCompact ? 20.0 : 28.0;
    final titleSize = isCompact ? 11.0 : 14.0;
    final subtitleSize = isCompact ? 9.0 : 12.0;
    final spacing = isCompact ? 6.0 : 12.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: item.color,
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.3),
            blurRadius: isCompact ? 10 : 20,
            offset: Offset(0, isCompact ? 5 : 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                ),
                child: Icon(item.icon, color: Colors.white, size: iconSize),
              ),
              SizedBox(height: spacing),
              Text(
                item.value,
                style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (!isCompact) const SizedBox(height: 4),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: titleSize,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (item.subtitle.isNotEmpty) ...[
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: subtitleSize,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
