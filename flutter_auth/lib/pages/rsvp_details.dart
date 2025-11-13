import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:iconly/iconly.dart';
import '../services/rsvp_service.dart';
import '../theme/theme_extensions.dart';

class RsvpDetailsPage extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final String clubId;
  final String eventId;
  final bool isRsvped;

  const RsvpDetailsPage({
    super.key,
    required this.eventData,
    required this.clubId,
    required this.eventId,
    required this.isRsvped,
  });

  @override
  State<RsvpDetailsPage> createState() => _RsvpDetailsPageState();
}

class _RsvpDetailsPageState extends State<RsvpDetailsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.eventData['title'] as String? ?? 'Event';
    final desc = widget.eventData['description'] as String? ?? '';
    final ts = (widget.eventData['eventDate'] as Timestamp).toDate();
    final loc = widget.eventData['location'] as String? ?? '';
    final formattedDate = DateFormat('EEEE, MMMM d').format(ts);
    final formattedTime = DateFormat('h:mm a').format(ts);
    final rsvpCount = (widget.eventData['rsvpList'] as List<dynamic>? ?? []).length;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(context.spacingXL),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      decoration: BoxDecoration(
                        color: context.neutralWhite,
                        borderRadius: BorderRadius.circular(context.radiusXL),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 32,
                            offset: const Offset(0, 8),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: context.accentNavy.withValues(alpha: 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with close button
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              context.spacingXL,
                              context.spacingXL,
                              context.spacingL,
                              context.spacingL,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: context.neutralBlack,
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    padding: EdgeInsets.all(context.spacingXS),
                                    decoration: BoxDecoration(
                                      color: context.neutralGray.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      IconlyBold.close_square,
                                      color: context.neutralBlack.withValues(alpha: 0.6),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Description
                          if (desc.isNotEmpty) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: context.spacingXL),
                              child: Text(
                                desc,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: context.neutralBlack.withValues(alpha: 0.7),
                                  height: 1.5,
                                ),
                              ),
                            ),
                            SizedBox(height: context.spacingXL),
                          ],

                          // Event Details - Sleek
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: context.spacingXL),
                            child: Column(
                              children: [
                                _buildSleekDetail(
                                  context,
                                  icon: IconlyBold.calendar,
                                  text: '$formattedDate',
                                  subtitle: formattedTime,
                                ),
                                SizedBox(height: context.spacingL),
                                _buildSleekDetail(
                                  context,
                                  icon: IconlyBold.location,
                                  text: loc,
                                ),
                                SizedBox(height: context.spacingL),
                                _buildSleekDetail(
                                  context,
                                  icon: IconlyBold.user_2,
                                  text: '$rsvpCount ${rsvpCount == 1 ? 'person' : 'people'} going',
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: context.spacingXXL),

                          // RSVP Button - Sleek
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              context.spacingXL,
                              0,
                              context.spacingXL,
                              context.spacingXL,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: widget.isRsvped
                                    ? null
                                    : () async {
                                        await RsvpService.rsvpToEvent(
                                          clubId: widget.clubId,
                                          eventId: widget.eventId,
                                        );
                                        if (context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: widget.isRsvped
                                      ? context.neutralGray.withValues(alpha: 0.2)
                                      : context.accentNavy,
                                  foregroundColor: widget.isRsvped
                                      ? context.neutralBlack.withValues(alpha: 0.5)
                                      : Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    vertical: context.spacingL + 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(context.radiusM),
                                  ),
                                  elevation: widget.isRsvped ? 0 : 2,
                                  shadowColor: context.accentNavy.withValues(alpha: 0.3),
                                ),
                                child: Text(
                                  widget.isRsvped ? 'Already RSVPed' : 'RSVP',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSleekDetail(
    BuildContext context, {
    required IconData icon,
    required String text,
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(context.spacingM),
      decoration: BoxDecoration(
        color: context.secondaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(context.radiusM),
        border: Border.all(
          color: context.neutralGray.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.spacingS),
            decoration: BoxDecoration(
              color: context.accentNavy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(context.radiusS),
            ),
            child: Icon(
              icon,
              size: 18,
              color: context.accentNavy,
            ),
          ),
          SizedBox(width: context.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    color: context.neutralBlack,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: context.spacingXS / 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.neutralBlack.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
