import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventQrPage extends StatefulWidget {
  final String clubId;
  final String eventId;
  final String mediaId;

  const EventQrPage({
    Key? key,
    required this.clubId,
    required this.eventId,
    required this.mediaId,
  }) : super(key: key);

  @override
  _EventQrPageState createState() => _EventQrPageState();
}

class _EventQrPageState extends State<EventQrPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLive = false;
  String _qrData = '';

  @override
  void initState() {
    super.initState();
    // load existing “live” flag & token
    _loadQrState();
  }

  Future<void> _loadQrState() async {
    final doc = await _firestore
        .collection('clubs')
        .doc(widget.clubId)
        .collection('events')
        .doc(widget.eventId)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _isLive = data['qrLive'] as bool? ?? false;
        _qrData = data['qrToken'] as String? ?? '';
      });
    } else {
      _generateQr(); // fallback
    }
  }

  Future<void> _toggleLive(bool live) async {
    setState(() => _isLive = live);
    if (live && _qrData.isEmpty) {
      _generateQr();
    }
    await _firestore
        .collection('clubs')
        .doc(widget.clubId)
        .collection('events')
        .doc(widget.eventId)
        .update({
      'qrLive': _isLive,
      'qrToken': _qrData,
    });
  }

  void _generateQr() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final token = '${widget.clubId}|${widget.eventId}|$ts|${widget.mediaId}';
    setState(() => _qrData = token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event QR Code')),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Live switch
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

            const SizedBox(height: 24),

            // QR or placeholder
            if (_isLive && _qrData.isNotEmpty) ...[
              QrImageView(
                data: _qrData,
                version: QrVersions.auto,
                size: 250.0,
              ),
            ] else ...[
              const Text(
                'No QR currently enabled.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],

            const Spacer(),

            // Regenerate button
            ElevatedButton.icon(
              onPressed: () async {
                _generateQr();
                // persist new token if currently live
                if (_isLive) {
                  await _firestore
                      .collection('clubs')
                      .doc(widget.clubId)
                      .collection('events')
                      .doc(widget.eventId)
                      .update({'qrToken': _qrData});
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Regenerate QR'),
            ),
          ],
        ),
      ),
    );
  }
}
