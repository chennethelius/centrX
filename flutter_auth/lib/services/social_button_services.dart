import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/comments_sheet.dart';

class SocialButtonServices {
  static final _firestore = FirebaseFirestore.instance;

  /// Show comments sheet for the given event
  static void showComments(BuildContext context, String eventId, {String? eventTitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(
        eventId: eventId,
        eventTitle: eventTitle ?? 'Event',
      ),
    );
  }

  /// Toggle RSVP for the current user on a media document.
  static Future<void> toggleRsvp(String mediaId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final docRef = _firestore.collection('media').doc(mediaId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final attendance = List<String>.from(data['attendanceList'] as List<dynamic>? ?? []);

      if (attendance.contains(userId)) {
        attendance.remove(userId);
      } else {
        attendance.add(userId);
      }

      tx.update(docRef, {'attendanceList': attendance});
    });
  }

  /// Toggle like for an event
  static Future<void> toggleEventLike(String eventId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final docRef = _firestore.collection('events').doc(eventId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final likedBy = List<String>.from(data['likedBy'] as List<dynamic>? ?? []);
      
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }

      tx.update(docRef, {
        'likedBy': likedBy,
        'likeCount': likedBy.length,
      });
    });
  }
}
