import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles RSVP business logic: updates both the event attendance list
/// and the user's registered events in a single batch.
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

  /// Called when scanning the QR code to “check in.”
  /// Adds the current user to the event's rsvpList **only** under
  /// /clubs/{clubId}/events/{eventId}.
  static Future<void> checkInEvent({
    required String clubId,
    required String eventId,
    required String mediaId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User must be signed in to check in.',
      );
    }

    final mediaRef = _firestore
        .collection('media')
        .doc(mediaId);
    
    final eventRef = _firestore
        .collection("clubs")
        .doc(clubId)
        .collection("events")
        .doc(eventId);

    // You could also update the user here again if needed, but
    // typically rsvpToEvent has already done that.

    final batch = _firestore.batch();

    batch.update(mediaRef, {
      'attendanceList': FieldValue.arrayUnion([uid]),
    });

        batch.update(eventRef, {
      'attendanceList': FieldValue.arrayUnion([uid]),
    });

    await batch.commit();
  }
}
