import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CanvasStudentService {
  static final _secureStorage = FlutterSecureStorage();

  /// Test Canvas connection with API token
  static Future<bool> testCanvasConnection({
    required String canvasUrl,
    required String apiToken,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$canvasUrl/api/v1/users/self'),
            headers: {
              'Authorization': 'Bearer $apiToken',
            },
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fetch all student's enrolled courses from Canvas
  static Future<List<Map<String, dynamic>>> fetchStudentCourses({
    required String canvasUrl,
    required String apiToken,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$canvasUrl/api/v1/courses?enrollment_type=student&include=total_students&per_page=100',
            ),
            headers: {
              'Authorization': 'Bearer $apiToken',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw 'Failed to fetch courses: ${response.statusCode}';
      }

      final courses = jsonDecode(response.body) as List<dynamic>;
      return courses
          .map((course) => {
                'canvasId': course['id'].toString(),
                'name': course['name'] as String? ?? 'Unknown',
                'code': course['course_code'] as String? ?? '',
                'term': course['enrollment_term_id'].toString(),
                'enrollmentState': course['enrollment_state'] as String? ?? 'active',
              })
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Save Canvas credentials securely
  static Future<void> saveCanvasCredentials({
    required String canvasUrl,
    required String apiToken,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Store sensitive data in secure storage
      await _secureStorage.write(
        key: 'student_canvas_url_$userId',
        value: canvasUrl,
      );
      await _secureStorage.write(
        key: 'student_canvas_token_$userId',
        value: apiToken,
      );

      // Update Firestore (without storing token)
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'canvasUrl': canvasUrl,
        'canvasConnected': true,
        'canvasLastSynced': DateTime.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get Canvas credentials from secure storage
  static Future<Map<String, String>?> getCanvasCredentials() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    try {
      final canvasUrl = await _secureStorage.read(
        key: 'student_canvas_url_$userId',
      );
      final apiToken = await _secureStorage.read(
        key: 'student_canvas_token_$userId',
      );

      if (canvasUrl == null || apiToken == null) return null;

      return {
        'canvasUrl': canvasUrl,
        'apiToken': apiToken,
      };
    } catch (e) {
      return null;
    }
  }

  /// Import courses to Firestore
  static Future<void> importCoursesToFirestore(
    List<Map<String, dynamic>> courses,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Convert to canvasClasses format with synced flag
      final canvasClasses = courses
          .map((course) => {
                ...course,
                'synced': true,
                'syncedAt': DateTime.now().toIso8601String(),
              })
          .toList();

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'canvasClasses': canvasClasses,
        'canvasLastSynced': DateTime.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh courses from Canvas (re-sync)
  static Future<void> refreshCoursesFromCanvas() async {
    try {
      final credentials = await getCanvasCredentials();
      if (credentials == null) {
        throw 'Canvas credentials not found';
      }

      final courses = await fetchStudentCourses(
        canvasUrl: credentials['canvasUrl']!,
        apiToken: credentials['apiToken']!,
      );

      await importCoursesToFirestore(courses);
    } catch (e) {
      rethrow;
    }
  }

  /// Remove a Canvas class from Firestore (doesn't unenroll from Canvas)
  static Future<void> removeCanvasClass(String canvasId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return;

      final data = userDoc.data() as Map<String, dynamic>;
      final canvasClasses =
          List<Map<String, dynamic>>.from(data['canvasClasses'] ?? []);

      canvasClasses.removeWhere((c) => c['canvasId'] == canvasId);

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'canvasClasses': canvasClasses,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Add a manual class (fallback if not in Canvas)
  static Future<void> addManualClass({
    required String code,
    required String name,
    required String instructor,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final data = userDoc.data() as Map<String, dynamic>;
      final manualClasses =
          List<Map<String, dynamic>>.from(data['manualClasses'] ?? []);

      manualClasses.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'code': code,
        'name': name,
        'instructor': instructor,
        'addedAt': DateTime.now().toIso8601String(),
        'synced': false,
      });

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'manualClasses': manualClasses,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Remove a manual class
  static Future<void> removeManualClass(String classId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return;

      final data = userDoc.data() as Map<String, dynamic>;
      final manualClasses =
          List<Map<String, dynamic>>.from(data['manualClasses'] ?? []);

      manualClasses.removeWhere((c) => c['id'] == classId);

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'manualClasses': manualClasses,
      });
    } catch (e) {
      rethrow;
    }
  }
}
