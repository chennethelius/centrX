import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a club partnership where a professor approves a club
/// for extra credit opportunities in their course(s)
class Partnership {
  final String partnershipId;
  final String teacherId;
  final String teacherName;
  final String clubId;
  final String clubName;
  final List<PartnershipCourse> courses;
  final String semester;
  final String approvalMode; // 'auto' or 'manual'
  final String status; // 'active', 'inactive', 'expired'
  final DateTime createdAt;
  final DateTime expiresAt;
  final PartnershipStats stats;

  Partnership({
    required this.partnershipId,
    required this.teacherId,
    required this.teacherName,
    required this.clubId,
    required this.clubName,
    required this.courses,
    required this.semester,
    required this.approvalMode,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.stats,
  });

  factory Partnership.fromJson(Map<String, dynamic> json, String id) {
    return Partnership(
      partnershipId: id,
      teacherId: json['teacherId'] as String,
      teacherName: json['teacherName'] as String,
      clubId: json['clubId'] as String,
      clubName: json['clubName'] as String,
      courses: (json['courses'] as List<dynamic>?)
              ?.map((c) => PartnershipCourse.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      semester: json['semester'] as String,
      approvalMode: json['approvalMode'] as String? ?? 'auto',
      status: json['status'] as String? ?? 'active',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      expiresAt: (json['expiresAt'] as Timestamp).toDate(),
      stats: json['stats'] != null
          ? PartnershipStats.fromJson(json['stats'] as Map<String, dynamic>)
          : PartnershipStats.empty(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teacherId': teacherId,
      'teacherName': teacherName,
      'clubId': clubId,
      'clubName': clubName,
      'courses': courses.map((c) => c.toJson()).toList(),
      'semester': semester,
      'approvalMode': approvalMode,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'stats': stats.toJson(),
    };
  }

  Partnership copyWith({
    String? status,
    List<PartnershipCourse>? courses,
    PartnershipStats? stats,
  }) {
    return Partnership(
      partnershipId: partnershipId,
      teacherId: teacherId,
      teacherName: teacherName,
      clubId: clubId,
      clubName: clubName,
      courses: courses ?? this.courses,
      semester: semester,
      approvalMode: approvalMode,
      status: status ?? this.status,
      createdAt: createdAt,
      expiresAt: expiresAt,
      stats: stats ?? this.stats,
    );
  }
}

/// Course configuration within a partnership
class PartnershipCourse {
  final String courseId;
  final String courseCode;
  final String courseName;
  final int pointsPerEvent;
  final int maxEventsPerStudent; // 1 to unlimited (use -1 for unlimited)

  PartnershipCourse({
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.pointsPerEvent,
    required this.maxEventsPerStudent,
  });

  factory PartnershipCourse.fromJson(Map<String, dynamic> json) {
    return PartnershipCourse(
      courseId: json['courseId'] as String,
      courseCode: json['courseCode'] as String,
      courseName: json['courseName'] as String,
      pointsPerEvent: json['pointsPerEvent'] as int? ?? 10,
      maxEventsPerStudent: json['maxEventsPerStudent'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseCode': courseCode,
      'courseName': courseName,
      'pointsPerEvent': pointsPerEvent,
      'maxEventsPerStudent': maxEventsPerStudent,
    };
  }

  /// Check if student has reached the cap for this course
  bool isUnlimited() => maxEventsPerStudent == -1;
}

/// Statistics for a partnership
class PartnershipStats {
  final int totalStudents;
  final int totalEventsAttended;
  final double averageEventsPerStudent;

  PartnershipStats({
    required this.totalStudents,
    required this.totalEventsAttended,
    required this.averageEventsPerStudent,
  });

  factory PartnershipStats.empty() {
    return PartnershipStats(
      totalStudents: 0,
      totalEventsAttended: 0,
      averageEventsPerStudent: 0.0,
    );
  }

  factory PartnershipStats.fromJson(Map<String, dynamic> json) {
    return PartnershipStats(
      totalStudents: json['totalStudents'] as int? ?? 0,
      totalEventsAttended: json['totalEventsAttended'] as int? ?? 0,
      averageEventsPerStudent: (json['averageEventsPerStudent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalStudents': totalStudents,
      'totalEventsAttended': totalEventsAttended,
      'averageEventsPerStudent': averageEventsPerStudent,
    };
  }
}

