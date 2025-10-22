import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'canvas_student_service.dart';

class CanvasBackgroundSync {
  static const int _syncIntervalDays = 7;

  /// Check if Canvas sync is needed (runs every app launch)
  static Future<void> checkAndSyncIfNeeded() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final canvasConnected = userData['canvasConnected'] as bool? ?? false;

      // Skip if not connected
      if (!canvasConnected) return;

      // Check last sync time
      final lastSynced = userData['canvasLastSynced'] as dynamic;
      if (lastSynced == null) {
        // Never synced, do it now
        await _performSync();
        return;
      }

      // Parse last sync time
      final lastSyncTime = (lastSynced is Timestamp)
          ? lastSynced.toDate()
          : DateTime.tryParse(lastSynced.toString()) ?? DateTime.now();

      // Check if 7+ days have passed
      final daysSinceSync = DateTime.now().difference(lastSyncTime).inDays;
      if (daysSinceSync >= _syncIntervalDays) {
        await _performSync();
      }
    } catch (e) {
      // Silently fail - background sync is not critical
      print('Background sync failed (non-critical): $e');
    }
  }

  /// Perform the actual sync
  static Future<void> _performSync() async {
    try {
      await CanvasStudentService.refreshCoursesFromCanvas();
      // Success - user will see updated courses on home page
    } catch (e) {
      // Silently fail - user can manually refresh if needed
      print('Canvas background sync error (non-critical): $e');
    }
  }
}
