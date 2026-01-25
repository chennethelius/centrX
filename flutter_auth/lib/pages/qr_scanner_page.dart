import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_auth/services/rsvp_service.dart';
import '../theme/theme_extensions.dart';

/// Custom exception types for QR check-in errors
enum QrCheckInErrorType {
  invalidFormat,
  eventNotFound,
  qrNotActive,
  alreadyCheckedIn,
  notAuthenticated,
  networkError,
  unknownError,
}

class QrCheckInException implements Exception {
  final QrCheckInErrorType type;
  final String? details;

  QrCheckInException(this.type, [this.details]);

  String get title {
    switch (type) {
      case QrCheckInErrorType.invalidFormat:
        return 'Invalid QR Code';
      case QrCheckInErrorType.eventNotFound:
        return 'Event Not Found';
      case QrCheckInErrorType.qrNotActive:
        return 'Check-In Not Available';
      case QrCheckInErrorType.alreadyCheckedIn:
        return 'Already Checked In';
      case QrCheckInErrorType.notAuthenticated:
        return 'Sign In Required';
      case QrCheckInErrorType.networkError:
        return 'Connection Error';
      case QrCheckInErrorType.unknownError:
        return 'Something Went Wrong';
    }
  }

  String get message {
    switch (type) {
      case QrCheckInErrorType.invalidFormat:
        return 'This QR code is not a valid CentrX event code. Please make sure you are scanning a QR code from an event check-in screen.';
      case QrCheckInErrorType.eventNotFound:
        return 'We could not find this event. It may have been cancelled or removed.';
      case QrCheckInErrorType.qrNotActive:
        return 'Check-in for this event is not currently active. Please wait for the event organizer to enable check-in.';
      case QrCheckInErrorType.alreadyCheckedIn:
        return 'You have already checked in to this event. No need to scan again!';
      case QrCheckInErrorType.notAuthenticated:
        return 'Please sign in to your account to check in to events.';
      case QrCheckInErrorType.networkError:
        return 'Unable to connect to the server. Please check your internet connection and try again.';
      case QrCheckInErrorType.unknownError:
        return 'An unexpected error occurred. Please try again or contact support if the problem persists.';
    }
  }

  String get suggestion {
    switch (type) {
      case QrCheckInErrorType.invalidFormat:
        return 'Try scanning the QR code displayed on the event check-in screen.';
      case QrCheckInErrorType.eventNotFound:
        return 'Contact the event organizer for assistance.';
      case QrCheckInErrorType.qrNotActive:
        return 'Ask the event organizer to activate check-in.';
      case QrCheckInErrorType.alreadyCheckedIn:
        return 'Enjoy the event!';
      case QrCheckInErrorType.notAuthenticated:
        return 'Go to the profile tab to sign in.';
      case QrCheckInErrorType.networkError:
        return 'Move to an area with better signal and try again.';
      case QrCheckInErrorType.unknownError:
        return 'Try scanning again in a few moments.';
    }
  }

  IconData get icon {
    switch (type) {
      case QrCheckInErrorType.invalidFormat:
        return Icons.qr_code_2;
      case QrCheckInErrorType.eventNotFound:
        return Icons.event_busy;
      case QrCheckInErrorType.qrNotActive:
        return Icons.timer_off;
      case QrCheckInErrorType.alreadyCheckedIn:
        return Icons.check_circle_outline;
      case QrCheckInErrorType.notAuthenticated:
        return Icons.person_off;
      case QrCheckInErrorType.networkError:
        return Icons.wifi_off;
      case QrCheckInErrorType.unknownError:
        return Icons.error_outline;
    }
  }
}

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Shows a success dialog with celebratory styling
  Future<void> _showSuccessDialog(String eventName) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radiusL),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.successGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: context.successGreen,
                size: 48,
              ),
            ),
            SizedBox(height: context.spacingL),
            Text(
              'Check-In Successful!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.neutralBlack,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacingM),
            Text(
              'Welcome to the event!',
              style: TextStyle(
                fontSize: 16,
                color: context.neutralDark,
              ),
              textAlign: TextAlign.center,
            ),
            if (eventName.isNotEmpty) ...[
              SizedBox(height: context.spacingS),
              Text(
                eventName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.accentNavy,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: context.spacingS),
            Text(
              'Your attendance has been recorded.',
              style: TextStyle(
                fontSize: 14,
                color: context.neutralGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.successGreen,
                foregroundColor: context.neutralWhite,
                padding: EdgeInsets.symmetric(vertical: context.spacingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.radiusM),
                ),
              ),
              child: const Text(
                'Great!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        actionsPadding: EdgeInsets.all(context.spacingM),
      ),
    );
  }

  /// Shows an error dialog with user-friendly messaging
  Future<void> _showErrorDialog(QrCheckInException error) async {
    if (!mounted) return;

    // For "already checked in", use a friendlier color scheme
    final bool isAlreadyCheckedIn = error.type == QrCheckInErrorType.alreadyCheckedIn;
    final Color iconBgColor = isAlreadyCheckedIn
        ? context.infoBlue.withValues(alpha: 0.15)
        : context.errorRed.withValues(alpha: 0.15);
    final Color iconColor = isAlreadyCheckedIn ? context.infoBlue : context.errorRed;
    final Color buttonColor = isAlreadyCheckedIn ? context.infoBlue : context.accentNavy;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radiusL),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                error.icon,
                color: iconColor,
                size: 48,
              ),
            ),
            SizedBox(height: context.spacingL),
            Text(
              error.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.neutralBlack,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacingM),
            Text(
              error.message,
              style: TextStyle(
                fontSize: 14,
                color: context.neutralDark,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacingM),
            Container(
              padding: EdgeInsets.all(context.spacingM),
              decoration: BoxDecoration(
                color: context.neutralLight,
                borderRadius: BorderRadius.circular(context.radiusM),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: context.warningOrange,
                    size: 20,
                  ),
                  SizedBox(width: context.spacingS),
                  Expanded(
                    child: Text(
                      error.suggestion,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.neutralDark,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: context.neutralWhite,
                padding: EdgeInsets.symmetric(vertical: context.spacingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.radiusM),
                ),
              ),
              child: Text(
                isAlreadyCheckedIn ? 'Got It' : 'Try Again',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        actionsPadding: EdgeInsets.all(context.spacingM),
      ),
    );
  }

  /// Validates QR code and checks event status before check-in
  Future<void> _validateAndCheckIn(String clubId, String eventId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw QrCheckInException(QrCheckInErrorType.notAuthenticated);
    }

    // Get event document from clubs collection
    final clubEventRef = _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('events')
        .doc(eventId);

    final eventDoc = await clubEventRef.get();

    // Check if event exists
    if (!eventDoc.exists) {
      throw QrCheckInException(QrCheckInErrorType.eventNotFound);
    }

    final eventData = eventDoc.data()!;

    // Check if QR is active (qrLive = true)
    final qrLive = eventData['qrLive'] as bool? ?? false;
    if (!qrLive) {
      throw QrCheckInException(QrCheckInErrorType.qrNotActive);
    }

    // Check if user already checked in
    final attendanceList = List<String>.from(eventData['attendanceList'] ?? []);
    if (attendanceList.contains(uid)) {
      throw QrCheckInException(QrCheckInErrorType.alreadyCheckedIn);
    }

    // Perform the check-in
    await RsvpService.checkInEvent(clubId: clubId, eventId: eventId);
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    setState(() => _isProcessing = true);
    _controller.stop();

    final raw = barcodes.first.rawValue?.trim() ?? '';
    String eventName = '';

    try {
      // Expect exactly 3 parts: clubId|eventId|timestamp
      final parts = raw.split('|');
      if (parts.length != 3) {
        throw QrCheckInException(
          QrCheckInErrorType.invalidFormat,
          'Expected 3 parts, got ${parts.length}',
        );
      }

      final clubId = parts[0];
      final eventId = parts[1];
      // parts[2] is timestamp, ignored

      // Validate IDs are not empty
      if (clubId.isEmpty || eventId.isEmpty) {
        throw QrCheckInException(
          QrCheckInErrorType.invalidFormat,
          'Missing club or event ID',
        );
      }

      // Try to get event name for success message
      try {
        final eventDoc = await _firestore
            .collection('clubs')
            .doc(clubId)
            .collection('events')
            .doc(eventId)
            .get();
        if (eventDoc.exists) {
          eventName = eventDoc.data()?['name'] as String? ?? '';
        }
      } catch (_) {
        // Ignore - event name is optional for success message
      }

      // Validate and perform check-in
      await _validateAndCheckIn(clubId, eventId);

      await _showSuccessDialog(eventName);
    } on QrCheckInException catch (e) {
      await _showErrorDialog(e);
    } on FirebaseException catch (e) {
      // Handle Firebase-specific errors
      QrCheckInException error;
      if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        error = QrCheckInException(QrCheckInErrorType.networkError, e.message);
      } else if (e.code == 'not-found') {
        error = QrCheckInException(QrCheckInErrorType.eventNotFound, e.message);
      } else if (e.code == 'permission-denied') {
        error = QrCheckInException(QrCheckInErrorType.notAuthenticated, e.message);
      } else {
        error = QrCheckInException(QrCheckInErrorType.unknownError, e.message);
      }
      await _showErrorDialog(error);
    } catch (e) {
      // Handle any other unexpected errors
      await _showErrorDialog(
        QrCheckInException(QrCheckInErrorType.unknownError, e.toString()),
      );
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
