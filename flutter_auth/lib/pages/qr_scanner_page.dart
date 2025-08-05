import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_auth/services/rsvp_service.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({Key? key}) : super(key: key);

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );

  Future<void> _showMessage(String title, String msg) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    setState(() => _isProcessing = true);
    _controller.stop();

    final raw = barcodes.first.rawValue?.trim() ?? '';
    try {
      // Expect exactly 4 parts: clubId|eventId|timestamp|mediaId
      final parts = raw.split('|');
      if (parts.length != 4) {
        throw FormatException('Expected clubId|eventId|timestamp|mediaId, got ${parts.length} parts instead.');
      }
      final clubId   = parts[0];
      final eventId  = parts[1];
      final timeStamp = parts[2];
      final mediaId  = parts[3];
      // We ignore the timestamp for now (parts[2])

      // Perform the RSVP
      await RsvpService.checkInEvent(clubId: clubId, eventId: eventId, mediaId: mediaId);

      await _showMessage('Check-In Successful', 'Your RSVP has been recorded!');
    } catch (err) {
      await _showMessage('Error', 'could not process QR code:\n$err');
    }

    // Reset for next scan
    if (mounted) {
      setState(() => _isProcessing = false);
      _controller.start();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Event QR'),
        actions: [
          IconButton(icon: const Icon(Icons.flash_on),    onPressed: _controller.toggleTorch),
          IconButton(icon: const Icon(Icons.cameraswitch), onPressed: _controller.switchCamera),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}
