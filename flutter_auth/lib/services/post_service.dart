// lib/services/post_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';

class PostService {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  PostService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Creates an event under /clubs/{clubId}/events/{eventId}
  /// and adds entries under the top‑level /media collection for each media URL.
  Future<void> createEventWithMedia({
    required String clubId,
    required Event event,
  }) async {
    // Reference to the event document
    final eventRef = _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('events')
        .doc(event.eventId);

    // Use a batch for atomic writes
    final batch = _firestore.batch();

    // 1) Write the event document
    batch.set(eventRef, event.toJson());

    // 2) Write each media URL into the top‑level /media collection
    for (final mediaUrl in event.mediaUrls) {
      final mediaId = _uuid.v4();
      final mediaRef = _firestore.collection('media').doc(mediaId);
      batch.set(mediaRef, {
        'mediaId':   mediaId,
        'postId':    event.eventId,
        'clubId':    clubId,
        'ownerId':   event.ownerId,
        'clubname':  event.clubname,
        'eventDate': Timestamp.fromDate(event.eventDate),
        'mediaUrl':  mediaUrl,
        'createdAt': Timestamp.fromDate(event.createdAt),
        'description': event.description,
        'location': event.location,
        'title': event.title,
      });
    }

    // Commit both writes together
    await batch.commit();
  }
}
