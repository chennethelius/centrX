import 'package:flutter/material.dart';
import '../theme/theme_extensions.dart';

/// A shimmer effect widget for loading states.
///
/// Use this widget to show a loading placeholder that mimics the shape
/// of content that is being loaded (cards, list items, etc.).
class LoadingShimmer extends StatefulWidget {
  /// The width of the shimmer container. Defaults to double.infinity.
  final double? width;

  /// The height of the shimmer container. Defaults to 120.
  final double height;

  /// The border radius of the shimmer container. Defaults to radiusL (16).
  final double? borderRadius;

  /// The base color for the shimmer effect.
  final Color? baseColor;

  /// The highlight color for the shimmer effect.
  final Color? highlightColor;

  /// Optional child widget to use as the shimmer shape.
  final Widget? child;

  const LoadingShimmer({
    super.key,
    this.width,
    this.height = 120,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
    this.child,
  });

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? context.neutralGray;
    final highlightColor = widget.highlightColor ?? context.neutralLight;
    final radius = widget.borderRadius ?? context.radiusL;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// A pre-built card shimmer that mimics the EventCard layout.
class CardShimmer extends StatelessWidget {
  /// Number of shimmer cards to display.
  final int count;

  /// Spacing between cards. Defaults to spacingL (16).
  final double? spacing;

  const CardShimmer({
    super.key,
    this.count = 1,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final cardSpacing = spacing ?? context.spacingL;

    return Column(
      children: List.generate(count, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index < count - 1 ? cardSpacing : 0),
          child: _SingleCardShimmer(),
        );
      }),
    );
  }
}

class _SingleCardShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.spacingXL),
      decoration: BoxDecoration(
        color: context.secondaryLight,
        borderRadius: BorderRadius.circular(context.radiusL),
        border: Border.all(
          color: context.neutralGray,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with badge
          Row(
            children: [
              Expanded(
                child: LoadingShimmer(
                  height: 24,
                  borderRadius: context.radiusS,
                ),
              ),
              SizedBox(width: context.spacingL),
              LoadingShimmer(
                width: 50,
                height: 28,
                borderRadius: context.radiusM,
              ),
            ],
          ),
          SizedBox(height: context.spacingM),
          // Date row
          Row(
            children: [
              LoadingShimmer(
                width: 16,
                height: 16,
                borderRadius: context.radiusXS,
              ),
              SizedBox(width: context.spacingS),
              LoadingShimmer(
                width: 100,
                height: 16,
                borderRadius: context.radiusXS,
              ),
            ],
          ),
          SizedBox(height: context.spacingS),
          // Location row
          Row(
            children: [
              LoadingShimmer(
                width: 16,
                height: 16,
                borderRadius: context.radiusXS,
              ),
              SizedBox(width: context.spacingS),
              Expanded(
                child: LoadingShimmer(
                  height: 16,
                  borderRadius: context.radiusXS,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A list item shimmer for simple list loading states.
class ListItemShimmer extends StatelessWidget {
  /// Number of list items to display.
  final int count;

  /// Whether to show a leading circle (avatar).
  final bool showAvatar;

  /// Whether to show a trailing widget.
  final bool showTrailing;

  const ListItemShimmer({
    super.key,
    this.count = 1,
    this.showAvatar = true,
    this.showTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < count - 1 ? context.spacingM : 0,
          ),
          child: _SingleListItemShimmer(
            showAvatar: showAvatar,
            showTrailing: showTrailing,
          ),
        );
      }),
    );
  }
}

class _SingleListItemShimmer extends StatelessWidget {
  final bool showAvatar;
  final bool showTrailing;

  const _SingleListItemShimmer({
    required this.showAvatar,
    required this.showTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.spacingM),
      decoration: BoxDecoration(
        color: context.secondaryLight,
        borderRadius: BorderRadius.circular(context.radiusM),
      ),
      child: Row(
        children: [
          if (showAvatar) ...[
            LoadingShimmer(
              width: 48,
              height: 48,
              borderRadius: 24,
            ),
            SizedBox(width: context.spacingM),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingShimmer(
                  height: 16,
                  borderRadius: context.radiusXS,
                ),
                SizedBox(height: context.spacingS),
                LoadingShimmer(
                  width: 120,
                  height: 12,
                  borderRadius: context.radiusXS,
                ),
              ],
            ),
          ),
          if (showTrailing) ...[
            SizedBox(width: context.spacingM),
            LoadingShimmer(
              width: 60,
              height: 32,
              borderRadius: context.radiusS,
            ),
          ],
        ],
      ),
    );
  }
}

/// A grid shimmer for bento-style layouts.
class GridShimmer extends StatelessWidget {
  /// Number of grid items to display.
  final int count;

  /// Number of columns in the grid.
  final int columns;

  /// Spacing between items.
  final double? spacing;

  /// Aspect ratio of each grid item.
  final double aspectRatio;

  const GridShimmer({
    super.key,
    this.count = 4,
    this.columns = 2,
    this.spacing,
    this.aspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final gridSpacing = spacing ?? context.spacingL;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (gridSpacing * (columns - 1))) / columns;
        final itemHeight = itemWidth / aspectRatio;

        return Wrap(
          spacing: gridSpacing,
          runSpacing: gridSpacing,
          children: List.generate(count, (index) {
            return LoadingShimmer(
              width: itemWidth,
              height: itemHeight,
              borderRadius: context.radiusXXL,
            );
          }),
        );
      },
    );
  }
}
