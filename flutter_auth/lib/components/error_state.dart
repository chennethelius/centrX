import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../theme/theme_extensions.dart';

/// A reusable error state widget for displaying error messages with retry functionality.
///
/// Use this widget consistently across the app when operations fail and the user
/// should be given the option to retry.
class ErrorState extends StatelessWidget {
  /// The main error message to display.
  final String message;

  /// Optional detailed error description.
  final String? details;

  /// The icon to display. Defaults to IconlyLight.danger.
  final IconData icon;

  /// Text for the retry button. Defaults to 'Try Again'.
  final String retryText;

  /// Callback when the retry button is pressed.
  final VoidCallback? onRetry;

  /// Optional secondary action text.
  final String? secondaryActionText;

  /// Callback for the secondary action.
  final VoidCallback? onSecondaryAction;

  /// Size of the icon. Defaults to 64.
  final double iconSize;

  /// Color of the icon. Defaults to errorRed.
  final Color? iconColor;

  /// Whether to use compact layout.
  final bool compact;

  const ErrorState({
    super.key,
    required this.message,
    this.details,
    this.icon = IconlyLight.danger,
    this.retryText = 'Try Again',
    this.onRetry,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.iconSize = 64,
    this.iconColor,
    this.compact = false,
  });

  /// Creates an error state for network/connection errors.
  factory ErrorState.network({
    VoidCallback? onRetry,
  }) {
    return ErrorState(
      icon: IconlyLight.shield_fail,
      message: 'Connection Error',
      details: 'Please check your internet connection and try again.',
      onRetry: onRetry,
    );
  }

  /// Creates an error state for server errors.
  factory ErrorState.server({
    VoidCallback? onRetry,
  }) {
    return ErrorState(
      icon: IconlyLight.danger,
      message: 'Server Error',
      details: 'Something went wrong on our end. Please try again later.',
      onRetry: onRetry,
    );
  }

  /// Creates an error state for permission/access denied errors.
  factory ErrorState.accessDenied({
    VoidCallback? onGoBack,
  }) {
    return ErrorState(
      icon: IconlyLight.lock,
      message: 'Access Denied',
      details: 'You don\'t have permission to view this content.',
      retryText: 'Go Back',
      onRetry: onGoBack,
    );
  }

  /// Creates an error state for content not found.
  factory ErrorState.notFound({
    VoidCallback? onGoBack,
  }) {
    return ErrorState(
      icon: IconlyLight.search,
      message: 'Not Found',
      details: 'The content you\'re looking for doesn\'t exist or has been removed.',
      retryText: 'Go Back',
      onRetry: onGoBack,
    );
  }

  /// Creates an error state for loading failures.
  factory ErrorState.loadFailed({
    String? contentType,
    VoidCallback? onRetry,
  }) {
    return ErrorState(
      icon: IconlyLight.info_circle,
      message: 'Failed to Load',
      details: contentType != null
          ? 'Unable to load $contentType. Please try again.'
          : 'Unable to load content. Please try again.',
      onRetry: onRetry,
    );
  }

  /// Creates an error state for timeout errors.
  factory ErrorState.timeout({
    VoidCallback? onRetry,
  }) {
    return ErrorState(
      icon: IconlyLight.time_circle,
      message: 'Request Timed Out',
      details: 'The request took too long to complete. Please try again.',
      onRetry: onRetry,
    );
  }

  /// Creates a generic error state from an exception.
  factory ErrorState.fromException(
    Object error, {
    VoidCallback? onRetry,
  }) {
    String message = 'An Error Occurred';
    String? details;

    if (error is Exception) {
      details = error.toString().replaceAll('Exception: ', '');
    } else {
      details = error.toString();
    }

    // Truncate very long error messages
    if (details.length > 150) {
      details = '${details.substring(0, 147)}...';
    }

    return ErrorState(
      message: message,
      details: details,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = compact ? iconSize * 0.7 : iconSize;
    final effectiveIconContainerSize = compact ? 80.0 : 110.0;
    final effectiveTitleSize = compact ? 16.0 : 20.0;
    final effectiveDetailsSize = compact ? 13.0 : 14.0;
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
            // Icon container with error-themed background
            Container(
              width: effectiveIconContainerSize,
              height: effectiveIconContainerSize,
              decoration: BoxDecoration(
                color: (iconColor ?? context.errorRed).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: effectiveIconSize,
                  color: iconColor ?? context.errorRed,
                ),
              ),
            ),

            SizedBox(height: effectiveSpacing),

            // Error message
            Text(
              message,
              style: TextStyle(
                fontSize: effectiveTitleSize,
                fontWeight: FontWeight.w600,
                color: context.neutralBlack,
              ),
              textAlign: TextAlign.center,
            ),

            // Details
            if (details != null) ...[
              SizedBox(height: context.spacingS),
              Text(
                details!,
                style: TextStyle(
                  fontSize: effectiveDetailsSize,
                  fontWeight: FontWeight.w400,
                  color: context.neutralMedium,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Action buttons
            if (onRetry != null || onSecondaryAction != null) ...[
              SizedBox(height: effectiveSpacing),
              _ErrorActionButtons(
                retryText: retryText,
                onRetry: onRetry,
                secondaryActionText: secondaryActionText,
                onSecondaryAction: onSecondaryAction,
                compact: compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorActionButtons extends StatelessWidget {
  final String retryText;
  final VoidCallback? onRetry;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;
  final bool compact;

  const _ErrorActionButtons({
    required this.retryText,
    this.onRetry,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary retry button
        if (onRetry != null)
          _RetryButton(
            text: retryText,
            onPressed: onRetry!,
            compact: compact,
          ),

        // Secondary action button
        if (secondaryActionText != null && onSecondaryAction != null) ...[
          SizedBox(height: context.spacingM),
          _SecondaryButton(
            text: secondaryActionText!,
            onPressed: onSecondaryAction!,
            compact: compact,
          ),
        ],
      ],
    );
  }
}

class _RetryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool compact;

  const _RetryButton({
    required this.text,
    required this.onPressed,
    this.compact = false,
  });

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? context.spacingL : context.spacingXL,
          vertical: widget.compact ? context.spacingS : context.spacingM,
        ),
        decoration: BoxDecoration(
          color: _isPressed
              ? context.accentNavyDark
              : context.accentNavy,
          borderRadius: BorderRadius.circular(context.radiusL),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: context.accentNavy.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconlyLight.arrow_left_circle,
              size: widget.compact ? 16 : 18,
              color: Colors.white,
            ),
            SizedBox(width: context.spacingS),
            Text(
              widget.text,
              style: TextStyle(
                fontSize: widget.compact ? 13 : 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool compact;

  const _SecondaryButton({
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
            border: Border.all(
              color: context.neutralGray,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(context.radiusL),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w500,
              color: context.neutralDark,
            ),
          ),
        ),
      ),
    );
  }
}

/// A simple inline error state for use in smaller spaces.
class InlineErrorState extends StatelessWidget {
  /// The error message.
  final String message;

  /// Callback when tapped to retry.
  final VoidCallback? onRetry;

  const InlineErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: context.spacingM,
          horizontal: context.spacingL,
        ),
        decoration: BoxDecoration(
          color: context.errorRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(context.radiusM),
          border: Border.all(
            color: context.errorRed.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconlyLight.danger,
              size: 18,
              color: context.errorRed,
            ),
            SizedBox(width: context.spacingS),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: context.errorRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(width: context.spacingS),
              Icon(
                IconlyLight.arrow_right_circle,
                size: 18,
                color: context.errorRed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
