import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/rsvp_service.dart';

class RsvpDetailsPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final title = eventData['title'] as String? ?? 'Event';
    final desc = eventData['description'] as String? ?? '';
    final host = eventData['hostClubName'] as String? ?? '';
    final ts = (eventData['eventDate'] as Timestamp).toDate();
    final loc = eventData['location'] as String? ?? '';
    final formatted = DateFormat.yMMMd().add_jm().format(ts);
    final rsvpCount = (eventData['rsvpList'] as List<dynamic>? ?? []).length;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 0, 0, 0.3),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color.fromRGBO(255, 255, 255, 0.25),
                    width: 2.5,
                  ),
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(255, 255, 255, 0.18),
                      Color.fromRGBO(255, 255, 255, 0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(title,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: const Icon(Icons.close, color: Colors.white, size: 28),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Text(formatted, style: const TextStyle(color: Colors.white, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Text(loc, style: const TextStyle(color: Colors.white, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.people_outline, color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Text('RSVPs: $rsvpCount', style: const TextStyle(color: Colors.white, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.account_balance_outlined, color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Text('Host: $host', style: const TextStyle(color: Colors.white, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isRsvped ? null : () async {
                                await RsvpService.rsvpToEvent(
                                  clubId: clubId,
                                  eventId: eventId,
                                );
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromRGBO(138, 255, 128, 0.85),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                isRsvped ? 'Already RSVPed' : 'RSVP to Event',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
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
  }
}
