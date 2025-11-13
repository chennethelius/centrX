import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/event.dart';

class EventService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  EventService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;
  
  /// Check if the current user can modify an event
  bool canModifyEvent(Event event) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    return event.ownerId == currentUser.uid;
  }

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
  /// Delete an event and clean up all associated data
  Future<void> deleteEvent({
    required Event event,
    bool deleteStorageMedia = true,
  }) async {
    // Authorization check
    if (!canModifyEvent(event)) {
      throw Exception('You do not have permission to delete this event');
    }

    final String clubId = event.ownerId;
    final String eventId = event.eventId;
    final List<String> rsvpList = event.rsvpList;
    final List<String> mediaUrls = event.mediaUrls;

    final clubEventRef = _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('events')
        .doc(eventId);
    final eventRef = _firestore.collection('events').doc(eventId);

    final batch = _firestore.batch();

    // a. Delete event document from club subcollection
    batch.delete(clubEventRef);

    // b. Delete associated media document from top-level events collection
    if (eventId.isNotEmpty) {
      batch.delete(eventRef);
    }

    // c. Delete event ID from each user's events_registered map field
    for (final userId in rsvpList) {
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'events_registered.$eventId': FieldValue.delete(),
      });
    }

    // Commit Firestore deletions
    await batch.commit();

    // d. Delete media files from Firebase Storage
    if (deleteStorageMedia && mediaUrls.isNotEmpty) {
      for (final mediaUrl in mediaUrls) {
        try {
          // Extract the storage path from the URL
          // URLs are typically: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?alt=media
          final uri = Uri.parse(mediaUrl);
          final pathSegments = uri.pathSegments;
          
          // Find the 'o' segment and get everything after it
          final oIndex = pathSegments.indexOf('o');
          if (oIndex != -1 && oIndex < pathSegments.length - 1) {
            // Decode the path (it's URL encoded)
            final encodedPath = pathSegments[oIndex + 1];
            final decodedPath = Uri.decodeComponent(encodedPath);
            final storageRef = _storage.ref(decodedPath);
            await storageRef.delete();
          }
        } catch (e) {
          // Log but don't fail the entire operation if storage deletion fails
          // The file might already be deleted or the URL format might be different
          print('Warning: failed to delete media from storage: $e');
        }
      }
    }

    // e. Delete comments subcollection (if exists)
    // Note: Firestore doesn't support recursive delete in rules, so this would need
    // a Cloud Function or manual cleanup. For MVP, we'll leave comments orphaned
    // and handle cleanup later if needed.
  }

  /// Update an existing event
  Future<void> updateEvent({
    required String clubId,
    required Event event,
    File? newMediaFile,
    bool deleteOldMedia = true,
  }) async {
    // Authorization check
    if (!canModifyEvent(event)) {
      throw Exception('You do not have permission to edit this event');
    }

    final batch = _firestore.batch();
    final clubEventRef = _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('events')
        .doc(event.eventId);
    final eventRef = _firestore.collection('events').doc(event.eventId);

    List<String> updatedMediaUrls = List.from(event.mediaUrls);

    // Handle media update if new media is provided
    if (newMediaFile != null) {
      // Delete old media from storage if requested
      if (deleteOldMedia && event.mediaUrls.isNotEmpty) {
        for (final oldMediaUrl in event.mediaUrls) {
          try {
            final uri = Uri.parse(oldMediaUrl);
            final pathSegments = uri.pathSegments;
            final oIndex = pathSegments.indexOf('o');
            if (oIndex != -1 && oIndex < pathSegments.length - 1) {
              final encodedPath = pathSegments[oIndex + 1];
              final decodedPath = Uri.decodeComponent(encodedPath);
              final storageRef = _storage.ref(decodedPath);
              await storageRef.delete();
            }
          } catch (e) {
            print('Warning: failed to delete old media: $e');
          }
        }
      }

      // Upload new media
      final storageRef = _storage.ref(
          'clubs/$clubId/events/${event.eventId}/media/${event.eventId}');
      final uploadTask = storageRef.putFile(newMediaFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      updatedMediaUrls = [downloadUrl];
    }

    // Create updated event with new media URLs
    final updatedEvent = Event(
      likeCount: event.likeCount,
      commentCount: event.commentCount,
      isRsvped: event.isRsvped,
      eventId: event.eventId,
      ownerId: event.ownerId,
      clubname: event.clubname,
      title: event.title,
      description: event.description,
      location: event.location,
      createdAt: event.createdAt, // Preserve original creation date
      eventDate: event.eventDate,
      mediaUrls: updatedMediaUrls,
      attendanceList: event.attendanceList, // Preserve attendance
      rsvpList: event.rsvpList, // Preserve RSVPs
      durationMinutes: event.durationMinutes,
      isQrEnabled: event.isQrEnabled,
    );

    // Update both documents atomically
    batch.set(clubEventRef, updatedEvent.toJson(), SetOptions(merge: false));
    
    // Update top-level events collection (for feed)
    final eventData = updatedEvent.toJson();
    if (updatedMediaUrls.isNotEmpty) {
      eventData['mediaUrl'] = updatedMediaUrls.first;
    }
    batch.set(eventRef, eventData, SetOptions(merge: false));

    await batch.commit();
  }
}
