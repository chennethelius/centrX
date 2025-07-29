// lib/widgets/like_button.dart

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikeButton extends StatelessWidget {
  final String mediaId;

  const LikeButton({Key? key, required this.mediaId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection('media').doc(mediaId);

    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (context, snap) {
        // default UI while loading or missing
        if (!snap.hasData || !snap.data!.exists) {
          return Column(
            children: const [
              Icon(IconlyBold.heart, size: 30, color: Colors.white),
              SizedBox(height: 4),
              Text('0', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          );
        }

        final data      = snap.data!.data()! as Map<String, dynamic>;
        final likeCount = (data['likeCount']   as int?)    ?? 0;
        final likedBy   = List<String>.from(data['likedBy'] as List? ?? []);
        final isLiked   = likedBy.contains(uid);

        return GestureDetector(
          onTap: () {
            FirebaseFirestore.instance.runTransaction((tx) async {
              final fresh = await tx.get(docRef);
              final map   = fresh.data()!;
              final currentLikes = (map['likeCount'] as int?) ?? 0;

              if (isLiked) {
                // unlike
                tx.update(docRef, {
                  'likeCount': currentLikes - 1,
                  'likedBy': FieldValue.arrayRemove([uid]),
                });
              } else {
                // like
                tx.update(docRef, {
                  'likeCount': currentLikes + 1,
                  'likedBy': FieldValue.arrayUnion([uid]),
                });
              }
            });
          },
          child: Container(
             decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  IconlyBold.heart,
                  size: 38,
                  color: isLiked ? Colors.red : Colors.white,
                ),
                const SizedBox(height: 4),
                Text(
                  '$likeCount',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
