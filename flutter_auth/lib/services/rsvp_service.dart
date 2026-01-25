import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/check_in_result.dart';
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

  /// Atomically removes the current user from the event's rsvpList
  /// and removes the eventId from the user's events_registered array.
  static Future<void> cancelRsvp({
    required String clubId,
    required String eventId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User must be signed in to cancel RSVP.',
      );
    }

    final eventRef = _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('events')
        .doc(eventId);

    final userRef = _firestore.collection('users').doc(uid);

    final batch = _firestore.batch();

    // 1) Remove from rsvpList on the event doc
    batch.update(eventRef, {
      'rsvpList': FieldValue.arrayRemove([uid]),
    });

    // 2) Remove from user's registered events
    batch.update(userRef, {
      'events_registered': FieldValue.arrayRemove([eventId]),
    });

    await batch.commit();
  }

  /// Called when scanning the QR code to "check in."
  /// Adds the current user to the event's attendance list and checks
  /// for club partnerships to award extra credit points.
  ///
  /// Returns a [CheckInResult] containing:
  /// - success: whether the check-in succeeded
  /// - pointsEarned: total points earned (0 if none)
  /// - courseName/courseCode: the course that got credit (if any)
  /// - message: human-readable status message
  /// - allPointsAwarded: list of all point awards (for multiple courses)
  static Future<CheckInResult> checkInEvent({
    required String clubId,
    required String eventId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return CheckInResult.failure('User must be signed in to check in.');
    }

    try {
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
      final pointAwards = await _checkPartnershipEligibility(
        studentId: uid,
        clubId: clubId,
        eventId: eventId,
      );

      // Build the result based on points awarded
      if (pointAwards.isEmpty) {
        return CheckInResult.successNoPoints();
      }

      // Filter out already-awarded points
      final newAwards = pointAwards.where((a) => !a.alreadyAwarded).toList();

      if (newAwards.isEmpty) {
        return CheckInResult(
          success: true,
          pointsEarned: 0,
          message: 'Check-in successful! Points were already awarded for this event.',
          allPointsAwarded: pointAwards,
        );
      }

      // Calculate total new points
      final totalPoints = newAwards.fold(0, (total, a) => total + a.points);

      // Use the first award for the primary course info
      final primaryAward = newAwards.first;

      return CheckInResult(
        success: true,
        pointsEarned: totalPoints,
        courseName: primaryAward.courseName,
        courseCode: primaryAward.courseCode,
        message: newAwards.length == 1
            ? 'Check-in successful! You earned $totalPoints points for ${primaryAward.courseCode}.'
            : 'Check-in successful! You earned $totalPoints points across ${newAwards.length} courses.',
        allPointsAwarded: newAwards,
      );
    } catch (e) {
      return CheckInResult.failure('Check-in failed: ${e.toString()}');
    }
  }

  /// Check if student is eligible for partnership points and award them.
  /// Returns a list of [PointAward] for all points awarded during this check-in.
  static Future<List<PointAward>> _checkPartnershipEligibility({
    required String studentId,
    required String clubId,
    required String eventId,
  }) async {
    final List<PointAward> pointAwards = [];

    try {
      // Get active partnerships for this club
      final partnerships = await PartnershipService.getClubPartnerships(clubId);
      if (partnerships.isEmpty) return pointAwards;

      // Get student's enrolled courses
      final studentDoc = await _firestore.collection('users').doc(studentId).get();
      final studentData = studentDoc.data() ?? {};
      final enrolledClasses = List<Map<String, dynamic>>.from(
        studentData['enrolledClasses'] ?? [],
      );

      // Get event details
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return pointAwards;

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

          // Award points and collect the result
          final eventNumber = (capCheck['eventsUsed'] as int) + 1;
          final pointAward = await PointService.awardPartnershipPoints(
            studentId: studentId,
            eventId: eventId,
            partnershipId: partnership.partnershipId,
            course: course,
            eventNumber: eventNumber,
          );

          if (pointAward != null) {
            pointAwards.add(pointAward);
          }
        }
      }
    } catch (e) {
      // Log error but don't fail the check-in
      print('Error checking partnership eligibility: $e');
    }

    return pointAwards;
  }
}
