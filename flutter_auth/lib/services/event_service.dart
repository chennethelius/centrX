import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventService {
  final FirebaseFirestore _firestore;
  //final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  EventService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Creates an event under /clubs/{clubId}/events/{eventId}
  /// and adds entries under the top‑level /media collection for each media URL.
  Future<void> createEventWithMedia({
    required String clubId,
    required Event event,
  }) async {
    // Reference to the event document
    final clubEventRef = _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('events')
        .doc(event.eventId);

    // Use a batch for atomic writes
    final batch = _firestore.batch();

    // 1) Write the event document
    batch.set(clubEventRef, event.toJson());

    // 2) Write each media URL into the top‑level /event collection
    for (final mediaUrl in event.mediaUrls) {
      final eventId = event.eventId;
      final eventRef = _firestore.collection('events').doc(eventId);
      final map = event.toJson();
      map['mediaUrl'] = mediaUrl;
      batch.set(eventRef, map);
    }

    // Commit both writes together
    await batch.commit();
  }
Future<void> deleteEvent({
  required Event event,
  bool deleteStorageMedia = true,
}) async {
  final String clubId = event.ownerId;
  final String eventId = event.eventId;
  final List<String> rsvpList = event.rsvpList;

  final clubEventRef = _firestore.collection('clubs').doc(clubId).collection('events').doc(eventId);
  final eventRef = _firestore.collection('events').doc(eventId);

  final batch = _firestore.batch();

  // a. Delete event document from club
  batch.delete(clubEventRef);

  // b. Delete associated media document
  if (eventId.isNotEmpty) {
    batch.delete(eventRef);
  }

  // c. Delete event ID key from each user's events_registered map field
  for (final userId in rsvpList) {
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'events_registered.$eventId': FieldValue.delete(),
    });
  }

  // Commit all deletions
  await batch.commit();

  // d. Optionally delete from Firebase Storage
  /*
  if (deleteStorageMedia && mediaId.isNotEmpty) {
    try {
      final storageRef = _storage.ref().child('media/$mediaId');
      await storageRef.delete();
    } catch (e) {
      print('Warning: failed to delete media from storage: $e');
    }
  }
  */
}
}
