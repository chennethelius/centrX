import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import '../services/rsvp_service.dart';
import '../pages/rsvp_details.dart';
import '../theme/theme_extensions.dart';

/// A button that shows RSVP status and count, and invokes RsvpService.
class RsvpButton extends StatefulWidget {
  final String clubId;
  final String eventId;

  const RsvpButton({
    Key? key,
    required this.clubId,
    required this.eventId,
  }) : super(key: key);

  @override
  State<RsvpButton> createState() => _RsvpButtonState();
}

class _RsvpButtonState extends State<RsvpButton> {
  final _firestore = FirebaseFirestore.instance;
  late final DocumentReference _clubEventRef;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _clubEventRef = _firestore
        .collection('clubs')
        .doc(widget.clubId)
        .collection('events')
        .doc(widget.eventId);
  }

  Future<void> _openRsvpDetails(Map<String, dynamic> data, bool isRsvped) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => RsvpDetailsPage(
          eventData: data,
          clubId: widget.clubId,
          eventId: widget.eventId,
          isRsvped: isRsvped,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _clubEventRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return _buildIcon(false);
        }
        final data = snap.data!.data()! as Map<String, dynamic>;
        final attendance = List<String>.from(data['rsvpList'] as List<dynamic>? ?? []);
        //final count = attendance.length;
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final isRsvped = attendance.contains(uid);

        return GestureDetector(
          onTap: (_busy) ? null : () => _openRsvpDetails(data, isRsvped),
          child: _buildIcon(isRsvped),
        );
      },
    );
  }

  Widget _buildIcon(bool active) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            active ? IconlyBold.tick_square : IconlyBold.calendar,
            size: 38,
            color: active ? context.successGreen : context.errorRed,
          ),
          const SizedBox(height: 4),
          Text(
            'RSVP',
            style: TextStyle(color: context.surfaceWhite, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
