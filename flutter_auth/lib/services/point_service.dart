import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/partnership.dart';
import '../models/check_in_result.dart';

/// Service for awarding points and managing extra credit
class PointService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Award points to a student from a partnership event attendance
  ///
  /// This is called automatically when a student scans QR at an event
  /// that's part of an active partnership with auto-approve enabled.
  ///
  /// Returns a [PointAward] with details about points awarded, or null
  /// if points were already awarded for this event.
  static Future<PointAward?> awardPartnershipPoints({
    required String studentId,
    required String eventId,
    required String partnershipId,
    required PartnershipCourse course,
    required int eventNumber,
  }) async {
    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(studentId);

    // Get current user data
    final userDoc = await userRef.get();
    final currentData = userDoc.data() ?? {};
    final ecByClass = Map<String, dynamic>.from(
      currentData['extraCreditByClass'] ?? {},
    );

    // Initialize course data if needed
    if (!ecByClass.containsKey(course.courseId)) {
      ecByClass[course.courseId] = {
        'points': 0,
        'eventsAttended': [],
        'partnershipUsage': {},
      };
    }

    final courseData = Map<String, dynamic>.from(ecByClass[course.courseId]);

    // Update points
    final currentPoints = courseData['points'] as int? ?? 0;
    final newPoints = currentPoints + course.pointsPerEvent;

    // Add event to attended list
    final attendedEvents = List<Map<String, dynamic>>.from(
      courseData['eventsAttended'] ?? [],
    );

    // Check if already attended this event
    final alreadyAttended = attendedEvents.any(
      (e) => e['eventId'] == eventId && e['partnershipId'] == partnershipId,
    );

    if (alreadyAttended) {
      // Already got points for this event, return indicator
      return PointAward(
        points: 0,
        courseCode: course.courseCode,
        courseName: course.courseName,
        courseId: course.courseId,
        eventNumber: eventNumber,
        alreadyAwarded: true,
      );
    }

    attendedEvents.add({
      'eventId': eventId,
      'points': course.pointsPerEvent,
      'attendedAt': FieldValue.serverTimestamp(),
      'partnershipId': partnershipId,
      'eventNumber': eventNumber,
      'autoApproved': true,
    });

    // Update partnership usage
    final partnershipUsage = Map<String, dynamic>.from(
      courseData['partnershipUsage'] ?? {},
    );

    if (!partnershipUsage.containsKey(partnershipId)) {
      partnershipUsage[partnershipId] = {
        'eventsUsed': 0,
        'maxEvents': course.maxEventsPerStudent,
      };
    }

    final usage = Map<String, dynamic>.from(partnershipUsage[partnershipId]);
    usage['eventsUsed'] = (usage['eventsUsed'] as int? ?? 0) + 1;
    partnershipUsage[partnershipId] = usage;

    // Update course data
    courseData['points'] = newPoints;
    courseData['eventsAttended'] = attendedEvents;
    courseData['partnershipUsage'] = partnershipUsage;
    ecByClass[course.courseId] = courseData;

    // Update user document
    batch.update(userRef, {
      'pointsBalance': FieldValue.increment(course.pointsPerEvent),
      'extraCreditByClass': ecByClass,
    });

    // Create attendance record for analytics
    final attendanceRef = _firestore
        .collection('partnership_attendances')
        .doc();
    batch.set(attendanceRef, {
      'studentId': studentId,
      'eventId': eventId,
      'partnershipId': partnershipId,
      'courseId': course.courseId,
      'courseCode': course.courseCode,
      'points': course.pointsPerEvent,
      'eventNumber': eventNumber,
      'attendedAt': FieldValue.serverTimestamp(),
      'autoApproved': true,
    });

    await batch.commit();

    // Return the point award information
    return PointAward(
      points: course.pointsPerEvent,
      courseCode: course.courseCode,
      courseName: course.courseName,
      courseId: course.courseId,
      eventNumber: eventNumber,
      alreadyAwarded: false,
    );
  }

  /// Get student's points for a specific course
  static Future<int> getPointsForCourse({
    required String studentId,
    required String courseId,
  }) async {
    final userDoc = await _firestore.collection('users').doc(studentId).get();
    final userData = userDoc.data() ?? {};
    final ecByClass = userData['extraCreditByClass'] as Map<String, dynamic>? ?? {};
    final courseData = ecByClass[courseId] as Map<String, dynamic>? ?? {};
    return courseData['points'] as int? ?? 0;
  }

  /// Calculate extra credit percentage from points
  /// 
  /// [points] - Total points earned
  /// [pointsPerPercent] - How many points = 1% (default: 10)
  /// [maxPercent] - Maximum EC percentage cap (default: 5.0)
  static double calculateECPercent({
    required int points,
    int pointsPerPercent = 10,
    double maxPercent = 5.0,
  }) {
    if (pointsPerPercent <= 0) return 0.0;
    final percent = points / pointsPerPercent;
    return percent > maxPercent ? maxPercent : percent;
  }
}

