// lib/widgets/event_card.dart

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../pages/event_details_page.dart';
import '../pages/edit_event_page.dart';
import '../theme/theme_extensions.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onDeleted;
  final VoidCallback? onUpdated;

  const EventCard({
    super.key,
    required this.event,
    this.onDeleted,
    this.onUpdated,
  });

  bool get _isOwner {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && event.ownerId == currentUser.uid;
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
          'Are you sure you want to delete this event? This action cannot be undone. All RSVPs and comments will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: context.errorRed)),
          ),
        ],
      ),
    );

    if (shouldDelete == true && context.mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await EventService().deleteEvent(event: event);
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          onDeleted?.call();
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting event: $e'),
              backgroundColor: context.errorRed,
            ),
          );
        }
      }
    }
  }

  void _openEditPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditEventPage(event: event),
      ),
    ).then((updated) {
      if (updated == true) {
        onUpdated?.call();
      }
    });
  }

  void _openDetailsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsPage(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetailsPage(context),
      child: Container(
        margin: EdgeInsets.only(bottom: context.spacingL),
        decoration: BoxDecoration(
          color: context.secondaryLight,
          borderRadius: BorderRadius.circular(context.radiusL),
          border: Border.all(
            color: context.neutralGray,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.neutralGray.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(context.spacingXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: context.neutralBlack,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.spacingS,
                          vertical: context.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: context.accentNavy,
                          borderRadius: BorderRadius.circular(context.radiusM),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              IconlyBold.user_3,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: context.spacingXS),
                            Text(
                              '${event.rsvpList.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacingM),
                  Row(
                    children: [
                      Icon(
                        IconlyBold.calendar,
                        color: context.neutralMedium,
                        size: 16,
                      ),
                      SizedBox(width: context.spacingS),
                      Text(
                        // format as yyyy-MM-dd
                        '${event.eventDate.toLocal()}'.split(' ')[0],
                        style: TextStyle(
                          color: context.neutralDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacingS),
                  Row(
                    children: [
                      Icon(
                        IconlyBold.location,
                        color: context.neutralMedium,
                        size: 16,
                      ),
                      SizedBox(width: context.spacingS),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(
                            color: context.neutralDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Edit & Delete Icons (only show for event owners)
            if (_isOwner)
              Positioned(
                bottom: context.spacingM,
                right: context.spacingM,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit Button
                    GestureDetector(
                      onTap: () => _openEditPage(context),
                      child: Container(
                        padding: EdgeInsets.all(context.spacingS),
                        margin: EdgeInsets.only(right: context.spacingS),
                        decoration: BoxDecoration(
                          color: context.accentNavy,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: context.accentNavy.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          IconlyBold.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    // Delete Button
                    GestureDetector(
                      onTap: () => _confirmAndDelete(context),
                      child: Container(
                        padding: EdgeInsets.all(context.spacingS),
                        decoration: BoxDecoration(
                          color: context.errorRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: context.errorRed.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          IconlyBold.delete,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
