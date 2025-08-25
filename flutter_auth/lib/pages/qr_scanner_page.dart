import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_auth/services/rsvp_service.dart';
import '../theme/theme_extensions.dart';

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
      // Expect exactly 3 parts: clubId|eventId|timestamp
      final parts = raw.split('|');
      if (parts.length != 3) {
        throw FormatException('Expected clubId|eventId|timestamp, got ${parts.length} parts instead.');
      }
      final clubId   = parts[0];
      final eventId  = parts[1];
      // We ignore the timestamp for now (parts[2])

      // Perform the RSVP
      await RsvpService.checkInEvent(clubId: clubId, eventId: eventId);

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
      backgroundColor: context.neutralBlack,
      appBar: AppBar(
        backgroundColor: context.neutralBlack,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back arrow
        title: Text(
          'Scan Event QR',
          style: TextStyle(
            color: context.neutralWhite,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.flash_on,
              color: context.neutralWhite,
            ),
            onPressed: _controller.toggleTorch,
          ),
          IconButton(
            icon: Icon(
              Icons.cameraswitch,
              color: context.neutralWhite,
            ),
            onPressed: _controller.switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera scanner
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          
          // Scanning overlay with focused square
          _buildScanningOverlay(context),
          
          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: context.accentNavy,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: context.spacingL),
                    Text(
                      'Processing QR Code...',
                      style: TextStyle(
                        color: context.neutralWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.6; // 60% of screen width
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
      ),
      child: Stack(
        children: [
          // Create the scanning frame effect
          Center(
            child: Container(
              width: scanAreaSize,
              height: scanAreaSize,
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.warningOrange,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(context.radiusL),
              ),
              child: Stack(
                children: [
                  // Corner indicators
                  ...List.generate(4, (index) {
                    return Positioned(
                      top: index < 2 ? 0 : null,
                      bottom: index >= 2 ? 0 : null,
                      left: index % 2 == 0 ? 0 : null,
                      right: index % 2 == 1 ? 0 : null,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: index < 2 ? BorderSide(color: context.warningOrange, width: 4) : BorderSide.none,
                            bottom: index >= 2 ? BorderSide(color: context.warningOrange, width: 4) : BorderSide.none,
                            left: index % 2 == 0 ? BorderSide(color: context.warningOrange, width: 4) : BorderSide.none,
                            right: index % 2 == 1 ? BorderSide(color: context.warningOrange, width: 4) : BorderSide.none,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          
          // Instruction text
          Positioned(
            bottom: size.height * 0.2,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Position QR code within the frame',
                  style: TextStyle(
                    color: context.neutralWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: context.spacingS),
                Text(
                  'The QR code will be scanned automatically',
                  style: TextStyle(
                    color: context.neutralWhite.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
