import 'package:cloud_firestore/cloud_firestore.dart';

/// A collection of concise helper methods for Firestore operations.
class DatabaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final CollectionReference<Map<String, dynamic>> _users =
      _db.collection('users');

  /// Get the user's full name (first + last).
  static Future<String> getUserName(String? uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return 'Unknown User';
    final data = snap.data()!;
    final first = data['firstName'] as String? ?? '';
    final last  = data['lastName']  as String? ?? '';
    return '$first $last';
  }

  /// Get the user's email.
  static Future<String> getUserEmail(String uid) async {
    final snap = await _users.doc(uid).get();
    return snap.data()?['email'] as String? ?? '';
  }

  /// Get the user's role (e.g., student, teacher).
  static Future<String> getUserRole(String uid) async {
    final snap = await _users.doc(uid).get();
    return snap.data()?['role'] as String? ?? '';
  }

  /// Get the user's points balance.
  static Future<int> getPointsBalance(String uid) async {
    final snap = await _users.doc(uid).get();
    return snap.data()?['pointsBalance'] as int? ?? 0;
  }
}
