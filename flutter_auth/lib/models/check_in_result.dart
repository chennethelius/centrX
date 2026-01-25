/// Result of a check-in operation containing success status and points info
class CheckInResult {
  final bool success;
  final int pointsEarned;
  final String? courseName;
  final String? courseCode;
  final String message;
  final List<PointAward> allPointsAwarded;

  CheckInResult({
    required this.success,
    required this.pointsEarned,
    this.courseName,
    this.courseCode,
    required this.message,
    this.allPointsAwarded = const [],
  });

  /// Create a successful check-in result with no points
  factory CheckInResult.successNoPoints() {
    return CheckInResult(
      success: true,
      pointsEarned: 0,
      message: 'Check-in successful!',
    );
  }

  /// Create a successful check-in result with points earned
  factory CheckInResult.successWithPoints({
    required int points,
    required String courseName,
    required String courseCode,
    List<PointAward> allAwards = const [],
  }) {
    return CheckInResult(
      success: true,
      pointsEarned: points,
      courseName: courseName,
      courseCode: courseCode,
      message: 'Check-in successful! You earned $points points for $courseCode.',
      allPointsAwarded: allAwards,
    );
  }

  /// Create a failed check-in result
  factory CheckInResult.failure(String errorMessage) {
    return CheckInResult(
      success: false,
      pointsEarned: 0,
      message: errorMessage,
    );
  }

  /// Total points earned across all courses
  int get totalPointsEarned => allPointsAwarded.fold(
        0,
        (total, award) => total + award.points,
      );

  /// Whether any points were earned
  bool get hasPointsEarned => pointsEarned > 0 || allPointsAwarded.isNotEmpty;

  @override
  String toString() {
    return 'CheckInResult(success: $success, pointsEarned: $pointsEarned, '
        'courseName: $courseName, message: $message)';
  }
}

/// Represents a single point award for a specific course
class PointAward {
  final int points;
  final String courseCode;
  final String courseName;
  final String courseId;
  final int eventNumber;
  final bool alreadyAwarded;

  PointAward({
    required this.points,
    required this.courseCode,
    required this.courseName,
    required this.courseId,
    required this.eventNumber,
    this.alreadyAwarded = false,
  });

  @override
  String toString() {
    return 'PointAward(points: $points, courseCode: $courseCode, '
        'eventNumber: $eventNumber, alreadyAwarded: $alreadyAwarded)';
  }
}
