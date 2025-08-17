import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/theme_extensions.dart';

//TODO: like animation, double-tap screen to like

class LikeButton extends StatelessWidget {
  final String eventId;

  const LikeButton({Key? key, required this.eventId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection('events').doc(eventId);

    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (context, snap) {
        // default UI while loading or missing
        if (!snap.hasData || !snap.data!.exists) {
          return Column(
            children: [
              Icon(IconlyBold.heart, size: 30, color: context.neutralMedium),
              SizedBox(height: 4),
              Text('0', style: TextStyle(color: context.neutralMedium, fontSize: 12)),
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
              if (!fresh.exists) return;
              
              final map = fresh.data()! as Map<String, dynamic>;
              final currentLikes = (map['likeCount'] as int?) ?? 0;
              final currentLikedBy = List<String>.from(map['likedBy'] as List? ?? []);
              final isCurrentlyLiked = currentLikedBy.contains(uid);

              if (isCurrentlyLiked) {
                // Unlike: only proceed if count > 0 to prevent negatives
                if (currentLikes > 0) {
                  tx.update(docRef, {
                    'likeCount': currentLikes - 1,
                    'likedBy': FieldValue.arrayRemove([uid]),
                  });
                }
              } else {
                // Like: safe to increment
                tx.update(docRef, {
                  'likeCount': currentLikes + 1,
                  'likedBy': FieldValue.arrayUnion([uid]),
                });
              }
            }).catchError((error) {
              // Handle any transaction errors silently
              debugPrint('Like button transaction error: $error');
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
                  color: isLiked ? context.errorRed : context.surfaceWhite,
                ),
                const SizedBox(height: 4),
                Text(
                  '$likeCount',
                  style: TextStyle(color: context.surfaceWhite, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
