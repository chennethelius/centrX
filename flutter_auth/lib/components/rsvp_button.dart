import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import '../services/rsvp_service.dart';

/// A button that shows RSVP status and count, and invokes RsvpService.
class RsvpButton extends StatefulWidget {
  final String clubId;
  final String eventId;
  final String mediaId;

  const RsvpButton({
    Key? key,
    required this.mediaId,
    required this.clubId,
    required this.eventId,
  }) : super(key: key);

  @override
  State<RsvpButton> createState() => _RsvpButtonState();
}

class _RsvpButtonState extends State<RsvpButton> {
  final _firestore = FirebaseFirestore.instance;
  late final DocumentReference _eventRef;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _eventRef = _firestore
        .collection('clubs')
        .doc(widget.clubId)
        .collection('events')
        .doc(widget.eventId);
  }

  Future<void> _confirmAndRsvp(Map<String, dynamic> data) async {
    final title = data['title'] as String? ?? 'Event';
    final desc = data['description'] as String? ?? '';
    final host = data['hostClubName'] as String? ?? '';
    final ts = (data['eventDate'] as Timestamp).toDate();
    final loc = data['location'] as String? ?? '';
    final formatted = DateFormat.yMMMd().add_jm().format(ts);

    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(desc),
            const SizedBox(height: 8),
            Text('Host: $host'),
            Text('When: $formatted'),
            Text('Where: $loc'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    if (yes != true) return;

    setState(() => _busy = true);
    try {
      await RsvpService.rsvpToEvent(
        clubId: widget.clubId,
        eventId: widget.eventId,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not RSVP: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _eventRef.snapshots(),
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
          onTap: (_busy || isRsvped) ? null : () => _confirmAndRsvp(data),
          child: _buildIcon(isRsvped),
        );
      },
    );
  }

  Widget _buildIcon(bool active) {
    return Column(
      children: [
        Icon(
          active ? IconlyBold.tick_square : IconlyBold.calendar,
          size: 38,
          color: active ? Colors.greenAccent : Colors.redAccent,
        ),
        const SizedBox(height: 4),
        Text(
          'RSVP',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
