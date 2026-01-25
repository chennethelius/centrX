import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../theme/theme_extensions.dart';

/// A reusable empty state widget for displaying when lists or content areas are empty.
///
/// Displays an icon, title, optional subtitle, and optional action button.
/// Use this widget consistently across the app for empty list/content states.
class EmptyState extends StatelessWidget {
  /// The icon to display. Defaults to IconlyLight.folder.
  final IconData icon;

  /// The main title text.
  final String title;

  /// Optional subtitle text for additional context.
  final String? subtitle;

  /// Optional action button text.
  final String? actionText;

  /// Callback when the action button is pressed.
  final VoidCallback? onAction;

  /// Size of the icon. Defaults to 80.
  final double iconSize;

  /// Color of the icon. Defaults to neutralMedium.
  final Color? iconColor;

  /// Background color for the icon container. Defaults to neutralLight.
  final Color? iconBackgroundColor;

  /// Whether to use compact layout (smaller sizes).
  final bool compact;

  const EmptyState({
    super.key,
    this.icon = IconlyLight.folder,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.iconSize = 80,
    this.iconColor,
    this.iconBackgroundColor,
    this.compact = false,
  });

  /// Creates an empty state for when no events are found.
  factory EmptyState.noEvents({
    VoidCallback? onCreateEvent,
  }) {
    return EmptyState(
      icon: IconlyLight.calendar,
      title: 'No Events Yet',
      subtitle: 'Events you create or join will appear here.',
      actionText: onCreateEvent != null ? 'Create Event' : null,
      onAction: onCreateEvent,
    );
  }

  /// Creates an empty state for when no RSVPs are found.
  factory EmptyState.noRsvps() {
    return const EmptyState(
      icon: IconlyLight.ticket,
      title: 'No RSVPs',
      subtitle: 'No one has RSVP\'d to this event yet.',
    );
  }

  /// Creates an empty state for when no comments are found.
  factory EmptyState.noComments() {
    return const EmptyState(
      icon: IconlyLight.chat,
      title: 'No Comments',
      subtitle: 'Be the first to leave a comment!',
      compact: true,
    );
  }

  /// Creates an empty state for when no search results are found.
  factory EmptyState.noSearchResults({
    String? searchTerm,
  }) {
    return EmptyState(
      icon: IconlyLight.search,
      title: 'No Results Found',
      subtitle: searchTerm != null
          ? 'No results for "$searchTerm". Try a different search.'
          : 'Try adjusting your search terms.',
    );
  }

  /// Creates an empty state for when no students/attendance records are found.
  factory EmptyState.noStudents() {
    return const EmptyState(
      icon: IconlyLight.user_1,
      title: 'No Students',
      subtitle: 'No students found for this selection.',
    );
  }

  /// Creates an empty state for when no notifications are found.
  factory EmptyState.noNotifications() {
    return const EmptyState(
      icon: IconlyLight.notification,
      title: 'No Notifications',
      subtitle: 'You\'re all caught up!',
    );
  }

  /// Creates an empty state for when no clubs are found.
  factory EmptyState.noClubs({
    VoidCallback? onJoinClub,
  }) {
    return EmptyState(
      icon: IconlyLight.discovery,
      title: 'No Clubs',
      subtitle: 'Join a club to see events and activities.',
      actionText: onJoinClub != null ? 'Browse Clubs' : null,
      onAction: onJoinClub,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = compact ? iconSize * 0.6 : iconSize;
    final effectiveIconContainerSize = compact ? 100.0 : 140.0;
    final effectiveTitleSize = compact ? 16.0 : 20.0;
    final effectiveSubtitleSize = compact ? 13.0 : 14.0;
    final effectiveSpacing = compact ? context.spacingM : context.spacingL;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacingXXL,
          vertical: compact ? context.spacingL : context.spacingHuge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container with subtle background
            Container(
              width: effectiveIconContainerSize,
              height: effectiveIconContainerSize,
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? context.neutralLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: effectiveIconSize,
                  color: iconColor ?? context.neutralMedium,
                ),
              ),
            ),

            SizedBox(height: effectiveSpacing),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: effectiveTitleSize,
                fontWeight: FontWeight.w600,
                color: context.neutralBlack,
              ),
              textAlign: TextAlign.center,
            ),

            // Subtitle
            if (subtitle != null) ...[
              SizedBox(height: context.spacingS),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: effectiveSubtitleSize,
                  fontWeight: FontWeight.w400,
                  color: context.neutralMedium,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Action button
            if (actionText != null && onAction != null) ...[
              SizedBox(height: effectiveSpacing),
              _ActionButton(
                text: actionText!,
                onPressed: onAction!,
                compact: compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool compact;

  const _ActionButton({
    required this.text,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(context.radiusL),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? context.spacingL : context.spacingXL,
            vertical: compact ? context.spacingS : context.spacingM,
          ),
          decoration: BoxDecoration(
            color: context.accentNavy,
            borderRadius: BorderRadius.circular(context.radiusL),
            boxShadow: [
              BoxShadow(
                color: context.accentNavy.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// A simple inline empty state for use in smaller spaces like cards or sections.
class InlineEmptyState extends StatelessWidget {
  /// The icon to display.
  final IconData icon;

  /// The message text.
  final String message;

  const InlineEmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.spacingL,
        horizontal: context.spacingM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: context.neutralMedium,
          ),
          SizedBox(width: context.spacingS),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: context.neutralMedium,
            ),
          ),
        ],
      ),
    );
  }
}
