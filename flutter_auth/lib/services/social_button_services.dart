import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialButtonServices {
  static final _firestore = FirebaseFirestore.instance;

  /// Show comments sheet for the given media.
  static void showComments(BuildContext context, String mediaId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Comments for $mediaId'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
}
