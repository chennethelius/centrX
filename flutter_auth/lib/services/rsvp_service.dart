import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'partnership_service.dart';
import 'point_service.dart';

/// Handles RSVP business logic: updates both the event attendance list
/// and the user's registered events in a single batch.
/// Also checks for club partnerships and awards extra credit points.
class RsvpService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Atomically adds the current user to the event's rsvpList
  /// and adds the eventId to the user's events_registered array.
  static Future<void> rsvpToEvent({
    required String clubId,
    required String eventId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User must be signed in to RSVP.',
      );
    }

    final eventRef = _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('events')
        .doc(eventId);

    final userRef = _firestore.collection('users').doc(uid);

    final batch = _firestore.batch();

    // 1) Add to rsvpList on the event doc
    batch.update(eventRef, {
      'rsvpList': FieldValue.arrayUnion([uid]),
    });

    // 2) Add to user's registered events
    batch.update(userRef, {
      'events_registered': FieldValue.arrayUnion([eventId]),
    });

    await batch.commit();
  }

  /// Called when scanning the QR code to "check in."
  /// Adds the current user to the event's attendance list and checks
  /// for club partnerships to award extra credit points.
  static Future<void> checkInEvent({
    required String clubId,
    required String eventId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User must be signed in to check in.',
      );
    }

    final eventRef = _firestore.collection('events').doc(eventId);
    final clubEventRef = _firestore
        .collection("clubs")
        .doc(clubId)
        .collection("events")
        .doc(eventId);

    final batch = _firestore.batch();

    // Add to attendance lists
    batch.update(clubEventRef, {
      'attendanceList': FieldValue.arrayUnion([uid]),
    });

    batch.update(eventRef, {
      'attendanceList': FieldValue.arrayUnion([uid]),
    });

    await batch.commit();

    // Check for club partnerships and award points if eligible
    await _checkPartnershipEligibility(
      studentId: uid,
      clubId: clubId,
      eventId: eventId,
    );
  }

  /// Check if student is eligible for partnership points and award them
  static Future<void> _checkPartnershipEligibility({
    required String studentId,
    required String clubId,
    required String eventId,
  }) async {
    try {
      // Get active partnerships for this club
      final partnerships = await PartnershipService.getClubPartnerships(clubId);
      if (partnerships.isEmpty) return;

      // Get student's enrolled courses
      final studentDoc = await _firestore.collection('users').doc(studentId).get();
      final studentData = studentDoc.data() ?? {};
      final enrolledClasses = List<Map<String, dynamic>>.from(
        studentData['enrolledClasses'] ?? [],
      );

      // Get event details
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return;

      // Check each partnership
      for (final partnership in partnerships) {
        if (partnership.status != 'active') continue;
        if (partnership.approvalMode != 'auto') continue; // Skip manual approval

        // Find matching courses
        for (final course in partnership.courses) {
          final isEnrolled = enrolledClasses.any(
            (ec) => ec['courseCode'] == course.courseCode,
          );

          if (!isEnrolled) continue;

          // Check cap
          final capCheck = await PartnershipService.checkStudentCap(
            studentId: studentId,
            partnershipId: partnership.partnershipId,
            courseId: course.courseId,
          );

          if (!(capCheck['canAttend'] as bool)) {
            // Cap reached, skip
            continue;
          }

          // Award points
          final eventNumber = (capCheck['eventsUsed'] as int) + 1;
          await PointService.awardPartnershipPoints(
            studentId: studentId,
            eventId: eventId,
            partnershipId: partnership.partnershipId,
            course: course,
            eventNumber: eventNumber,
          );
        }
      }
    } catch (e) {
      // Log error but don't fail the check-in
      print('Error checking partnership eligibility: $e');
    }
  }
}
