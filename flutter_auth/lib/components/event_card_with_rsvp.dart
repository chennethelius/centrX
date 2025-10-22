import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconly/iconly.dart';
import '../models/event.dart';
import '../services/rsvp_service.dart';
import '../theme/theme_extensions.dart';

class EventCardWithRsvp extends StatefulWidget {
  final Event event;
  final Function(bool)? onRsvpChanged;

  const EventCardWithRsvp({
    super.key,
    required this.event,
    this.onRsvpChanged,
  });

  @override
  State<EventCardWithRsvp> createState() => _EventCardWithRsvpState();
}

class _EventCardWithRsvpState extends State<EventCardWithRsvp> {
  late bool _isRsvped;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkIfRsvped();
  }

  void _checkIfRsvped() {
    final userId = _auth.currentUser?.uid;
    _isRsvped = userId != null && widget.event.rsvpList.contains(userId);
  }

  Future<void> _handleRsvpToggle() async {
    if (_isLoading) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to RSVP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await RsvpService.rsvpToEvent(
        clubId: widget.event.ownerId,
        eventId: widget.event.eventId,
      );

      setState(() => _isRsvped = true);
      widget.onRsvpChanged?.call(true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ RSVP confirmed!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final dateStr = '${event.eventDate.toLocal()}'.split(' ')[0];

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.spacingL,
        vertical: context.spacingM,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and RSVP count
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.neutralBlack,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: context.spacingS),
                      Text(
                        event.clubname,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.neutralMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.spacingM),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacingS,
                    vertical: context.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: context.accentNavy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.radiusM),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconlyBold.user_3,
                        color: context.accentNavy,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${event.rsvpList.length}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.accentNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacingL),
            child: Column(
              children: [
                _buildDetailRow(
                  context: context,
                  icon: IconlyBold.calendar,
                  label: dateStr,
                  color: context.accentNavy,
                ),
                SizedBox(height: context.spacingM),
                _buildDetailRow(
                  context: context,
                  icon: IconlyBold.location,
                  label: event.location,
                  color: context.successGreen,
                ),
                if (event.description.isNotEmpty) ...[
                  SizedBox(height: context.spacingM),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.neutralDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: context.spacingL),

          // Points and rating info
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacingL),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacingM,
                    vertical: context.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: context.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.radiusM),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconlyBold.star,
                        color: context.successGreen,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '+10 pts',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.successGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.spacingM),
                if ((widget.event as dynamic).rating != null && (widget.event as dynamic).rating > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.spacingM,
                      vertical: context.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(context.radiusM),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconlyBold.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '${((widget.event as dynamic).rating).toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: context.spacingL),

          // Large RSVP button with full width
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: SizedBox(
              width: double.infinity,
              height: 56, // Larger hitbox
              child: ElevatedButton(
                onPressed: _isRsvped || _isLoading ? null : _handleRsvpToggle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRsvped
                      ? context.successGreen.withValues(alpha: 0.5)
                      : context.accentNavy,
                  disabledBackgroundColor:
                      context.successGreen.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.radiusL),
                  ),
                  elevation: _isRsvped ? 0 : 4,
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isRsvped ? context.successGreen : Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isRsvped ? IconlyBold.tick_square : IconlyBold.plus,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: context.spacingM),
                          Text(
                            _isRsvped ? '✓ RSVP Confirmed' : 'RSVP to Event',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 18,
        ),
        SizedBox(width: context.spacingS),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: context.neutralDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
