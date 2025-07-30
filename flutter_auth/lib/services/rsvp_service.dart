import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles RSVP business logic: updates both the event attendance list
/// and the user's registered events in a single batch.
class RsvpService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Atomically adds the current user to the event's attendanceList
  /// and increments their user document's events_registered.
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
    batch.update(eventRef, {
      'rsvpList': FieldValue.arrayUnion([uid]),
    });
    batch.update(userRef, {
      'events_registered': FieldValue.arrayUnion([eventId]),
    });

    await batch.commit();
  }
}
