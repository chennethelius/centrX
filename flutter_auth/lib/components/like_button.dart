import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconly/iconly.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/theme_extensions.dart';

class LikeButton extends StatefulWidget {
  final String eventId;

  const LikeButton({Key? key, required this.eventId}) : super(key: key);

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLike(String eventId, bool isCurrentlyLiked) async {
    if (_isAnimating) return; // Prevent multiple taps during animation

    // Haptic feedback
    HapticFeedback.mediumImpact();

    setState(() {
      _isAnimating = true;
    });

    // Start animation: expand outward then contract crisply
    _animationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 20), () {
        _animationController.reverse();
      });
    });

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection('events').doc(eventId);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final fresh = await tx.get(docRef);
        if (!fresh.exists) return;

        final map = fresh.data() as Map<String, dynamic>;
        final currentLikes = (map['likeCount'] as int?) ?? 0;
        final currentLikedBy = List<String>.from(map['likedBy'] as List? ?? []);
        final isCurrentlyLikedInDb = currentLikedBy.contains(uid);

        if (isCurrentlyLikedInDb) {
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
      });
    } catch (error) {
      debugPrint('Like button transaction error: $error');
    } finally {
      // Reset animation state after a delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isAnimating = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docRef =
        FirebaseFirestore.instance.collection('events').doc(widget.eventId);

    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (context, snap) {
        // default UI while loading or missing
        if (!snap.hasData || !snap.data!.exists) {
          return Column(
            children: [
              Icon(IconlyBold.heart, size: 30, color: context.neutralMedium),
              SizedBox(height: 4),
              Text('0',
                  style: TextStyle(color: context.neutralMedium, fontSize: 12)),
            ],
          );
        }

        final data = snap.data!.data()! as Map<String, dynamic>;
        final likeCount = (data['likeCount'] as int?) ?? 0;
        final likedBy = List<String>.from(data['likedBy'] as List? ?? []);
        final isLiked = likedBy.contains(uid);

        return GestureDetector(
          onTap: () => _handleLike(widget.eventId, isLiked),
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
                SizedBox(
                  width: 38,
                  height: 38,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Center(
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          alignment: Alignment.center,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: Alignment.center,
                            child: Icon(
                              IconlyBold.heart,
                              size: 38,
                              color: isLiked
                                  ? context.errorRed
                                  : context.surfaceWhite,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
