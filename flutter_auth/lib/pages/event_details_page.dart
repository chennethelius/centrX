import 'package:flutter/material.dart';
import '../models/event.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventDetailsPage extends StatefulWidget {
  final Event event;

  const EventDetailsPage({super.key, required this.event});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLive = false;
  String _qrData = '';

  @override
  void initState() {
    super.initState();
    _loadQrState();
  }

  Future<void> _loadQrState() async {
    final doc = await _firestore
        .collection('clubs')
        .doc(widget.event.ownerId)
        .collection('events')
        .doc(widget.event.eventId)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _isLive = data['qrLive'] as bool? ?? false;
        _qrData = data['qrToken'] as String? ?? '';
      });
    } else {
      _generateQr();
    }
  }

  Future<void> _toggleLive(bool live) async {
    setState(() => _isLive = live);
    if (live && _qrData.isEmpty) {
      _generateQr();
    }
    await _firestore
        .collection('clubs')
        .doc(widget.event.ownerId)
        .collection('events')
        .doc(widget.event.eventId)
        .update({
      'qrLive': _isLive,
      'qrToken': _qrData,
    });
  }

  Future<void> _regenerateQr() async {
    _generateQr();
    if (_isLive) {
      await _firestore
          .collection('clubs')
          .doc(widget.event.ownerId)
          .collection('events')
          .doc(widget.event.eventId)
          .update({'qrToken': _qrData});
    }
  }

  void _generateQr() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final token = '${widget.event.ownerId}|${widget.event.eventId}|$ts';
    setState(() => _qrData = token);
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final dateStr = '${event.eventDate.toLocal()}'.split(' ')[0];
    final timeStr = TimeOfDay.fromDateTime(event.eventDate).format(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero image or banner (placeholder)
            Container(
              height: 220,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                color: Color(0xFFE3E6EA),
              ),
              child: const Center(
                child: Icon(Icons.event, size: 80, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text('$dateStr • $timeStr',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 20, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text(event.location, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(event.description,
                      style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 20, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text('RSVPs: ${event.rsvpList.length}', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('QR Live:', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Switch(
                                value: _isLive,
                                onChanged: (val) => _toggleLive(val),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_isLive && _qrData.isNotEmpty) ...[
                            QrImageView(
                              data: _qrData,
                              version: QrVersions.auto,
                              size: 180.0,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text('Scan to check in or view event', style: TextStyle(color: Colors.grey[600])),
                          ] else ...[
                            const Text(
                              'No QR currently enabled.',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _regenerateQr,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Regenerate QR'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
