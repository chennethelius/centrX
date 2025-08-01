import 'dart:convert';

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
    // enable torch, front/back camera toggling, etc.
    detectionSpeed: DetectionSpeed.normal,
  );

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    setState(() => _isProcessing = true);
    _controller.stop();

    final raw = barcodes.first.rawValue ?? '';
    try {
      // 1) Parse JSON payload
      final data = json.decode(raw) as Map<String, dynamic>;
      final clubId  = data['clubId']  as String;
      final eventId = data['eventId'] as String;
      // final token = data['token'] as String; // if you embedded one

      // 2) (optional) verify/decrypt token here...

      // 3) Perform RSVP
      await RsvpService.rsvpToEvent(
        clubId:  clubId,
        eventId: eventId,
      );

      // 4) Show success dialog
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Check-In Successful'),
          content: const Text('Your RSVP has been recorded!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (err) {
      // Handle parse/auth errors
      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Text('Could not process QR code:\n$err'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }

    // reset for next scan
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
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          // optionally draw a semi-transparent overlay and a framing rectangle
        ],
      ),
    );
  }
}
