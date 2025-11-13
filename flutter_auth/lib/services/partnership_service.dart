import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/partnership.dart';

/// Service for managing club partnerships and extra credit opportunities
class PartnershipService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new club partnership
  /// 
  /// [teacherId] - ID of the teacher creating the partnership
  /// [teacherName] - Name of the teacher
  /// [clubId] - ID of the club being partnered with
  /// [clubName] - Name of the club
  /// [courses] - List of courses this partnership applies to
  /// [semester] - Semester identifier (e.g., "Fall2024")
  /// [approvalMode] - 'auto' for immediate points, 'manual' for review
  /// [expiresAt] - When the partnership expires (typically end of semester)
  static Future<String> createPartnership({
    required String teacherId,
    required String teacherName,
    required String clubId,
    required String clubName,
    required List<PartnershipCourse> courses,
    required String semester,
    required String approvalMode,
    required DateTime expiresAt,
  }) async {
    if (courses.isEmpty) {
      throw Exception('At least one course must be selected');
    }

    final batch = _firestore.batch();

    // Create partnership document
    final partnershipRef = _firestore.collection('club_partnerships').doc();
    final partnershipId = partnershipRef.id;

    final partnership = Partnership(
      partnershipId: partnershipId,
      teacherId: teacherId,
      teacherName: teacherName,
      clubId: clubId,
      clubName: clubName,
      courses: courses,
      semester: semester,
      approvalMode: approvalMode,
      status: 'active',
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      stats: PartnershipStats.empty(),
    );

    batch.set(partnershipRef, partnership.toJson());

    // Update club document to reference partnership
    final clubRef = _firestore.collection('clubs').doc(clubId);
    final clubDoc = await clubRef.get();
    final clubData = clubDoc.data() ?? {};
    final partnerships = List<Map<String, dynamic>>.from(
      clubData['partnerships'] ?? [],
    );

    partnerships.add({
      'partnershipId': partnershipId,
      'teacherId': teacherId,
      'courseCodes': courses.map((c) => c.courseCode).toList(),
      'status': 'active',
    });

    batch.update(clubRef, {'partnerships': partnerships});

    await batch.commit();
    return partnershipId;
  }

  /// Get all active partnerships for a teacher
  static Stream<List<Partnership>> getTeacherPartnerships(String teacherId) {
    return _firestore
        .collection('club_partnerships')
        .where('teacherId', isEqualTo: teacherId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Partnership.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Get all active partnerships for a specific club
  static Future<List<Partnership>> getClubPartnerships(String clubId) async {
    final snapshot = await _firestore
        .collection('club_partnerships')
        .where('clubId', isEqualTo: clubId)
        .where('status', isEqualTo: 'active')
        .get();

    return snapshot.docs
        .map((doc) => Partnership.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// Get partnership by ID
  static Future<Partnership?> getPartnership(String partnershipId) async {
    final doc = await _firestore
        .collection('club_partnerships')
        .doc(partnershipId)
        .get();

    if (!doc.exists) return null;
    return Partnership.fromJson(doc.data()!, doc.id);
  }

  /// Update partnership (e.g., add more courses, change max events)
  static Future<void> updatePartnership({
    required String partnershipId,
    List<PartnershipCourse>? courses,
    String? approvalMode,
    String? status,
  }) async {
    final updates = <String, dynamic>{};

    if (courses != null) {
      updates['courses'] = courses.map((c) => c.toJson()).toList();
    }
    if (approvalMode != null) {
      updates['approvalMode'] = approvalMode;
    }
    if (status != null) {
      updates['status'] = status;
    }

    if (updates.isEmpty) return;

    await _firestore
        .collection('club_partnerships')
        .doc(partnershipId)
        .update(updates);
  }

  /// Deactivate a partnership
  static Future<void> deactivatePartnership(String partnershipId) async {
    final batch = _firestore.batch();

    // Update partnership status
    final partnershipRef = _firestore
        .collection('club_partnerships')
        .doc(partnershipId);
    final partnershipDoc = await partnershipRef.get();
    final partnership = Partnership.fromJson(
        partnershipDoc.data()!, partnershipDoc.id);

    batch.update(partnershipRef, {'status': 'inactive'});

    // Remove from club's partnerships list
    final clubRef = _firestore.collection('clubs').doc(partnership.clubId);
    final clubDoc = await clubRef.get();
    final clubData = clubDoc.data() ?? {};
    final partnerships = List<Map<String, dynamic>>.from(
      clubData['partnerships'] ?? [],
    );

    partnerships.removeWhere((p) => p['partnershipId'] == partnershipId);
    batch.update(clubRef, {'partnerships': partnerships});

    await batch.commit();
  }

  /// Check if a student has reached the cap for a partnership course
  /// Returns the number of events used and whether they can attend more
  static Future<Map<String, dynamic>> checkStudentCap({
    required String studentId,
    required String partnershipId,
    required String courseId,
  }) async {
    final userDoc = await _firestore.collection('users').doc(studentId).get();
    final userData = userDoc.data() ?? {};
    final ecByClass = userData['extraCreditByClass'] as Map<String, dynamic>? ?? {};
    final courseData = ecByClass[courseId] as Map<String, dynamic>? ?? {};
    final partnershipUsage = courseData['partnershipUsage'] as Map<String, dynamic>? ?? {};
    final usage = partnershipUsage[partnershipId] as Map<String, dynamic>? ?? {};

    final eventsUsed = usage['eventsUsed'] as int? ?? 0;
    final maxEvents = usage['maxEvents'] as int? ?? -1; // -1 means unlimited

    return {
      'eventsUsed': eventsUsed,
      'maxEvents': maxEvents,
      'canAttend': maxEvents == -1 || eventsUsed < maxEvents,
      'remaining': maxEvents == -1 ? -1 : (maxEvents - eventsUsed),
    };
  }

  /// Get student's partnership usage for a course
  static Future<Map<String, dynamic>> getStudentPartnershipUsage({
    required String studentId,
    required String courseId,
  }) async {
    final userDoc = await _firestore.collection('users').doc(studentId).get();
    final userData = userDoc.data() ?? {};
    final ecByClass = userData['extraCreditByClass'] as Map<String, dynamic>? ?? {};
    final courseData = ecByClass[courseId] as Map<String, dynamic>? ?? {};
    return courseData['partnershipUsage'] as Map<String, dynamic>? ?? {};
  }
}

