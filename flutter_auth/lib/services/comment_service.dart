import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/comment.dart';

class CommentService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Get real-time stream of top-level comments for an event
  static Stream<List<Comment>> getCommentsStream(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('comments')
        .where('parentCommentId', isNull: true) // Top-level comments only
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Comment.fromFirestore(doc))
              .where((comment) => !comment.isDeleted) // Filter out deleted comments in UI
              .toList();
        });
  }

  /// Get real-time stream of replies for a specific comment
  static Stream<List<Comment>> getRepliesStream(String eventId, String parentCommentId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('comments')
        .where('parentCommentId', isEqualTo: parentCommentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Comment.fromFirestore(doc))
              .where((comment) => !comment.isDeleted) // Filter out deleted comments
              .toList();
        });
  }

  /// Post a new comment or reply
  static Future<String?> postComment({
    required String eventId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to post comments');
      }

      if (content.trim().isEmpty) {
        throw Exception('Comment content cannot be empty');
      }

      // Create comment document reference
      final commentRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('comments')
          .doc();

      // Prepare comment data
      final commentData = {
        'commentId': commentRef.id,
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Anonymous User',
        'authorAvatar': user.photoURL ?? '',
        'eventId': eventId,
        'content': content.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
        'likedBy': <String>[],
        'likeCount': 0,
        'parentCommentId': parentCommentId,
        'isDeleted': false,
        'isEdited': false,
      };

      // Use batch for atomic operations
      final batch = _firestore.batch();

      // Add the comment
      batch.set(commentRef, commentData);

      // Update event's comment count
      final eventRef = _firestore.collection('events').doc(eventId);
      batch.update(eventRef, {
        'commentCount': FieldValue.increment(1),
      });

      // Optionally update user's activity (commented events)
      final userRef = _firestore.collection('users').doc(user.uid);
      batch.update(userRef, {
        'commentedEvents': FieldValue.arrayUnion([eventId]),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      debugPrint('Comment posted successfully: ${commentRef.id}');
      return commentRef.id;

    } catch (e) {
      debugPrint('Error posting comment: $e');
      rethrow;
    }
  }

  /// Toggle like/unlike on a comment
  static Future<void> toggleCommentLike(String eventId, String commentId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User must be authenticated to like comments');
      }

      final commentRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('comments')
          .doc(commentId);

      await _firestore.runTransaction((transaction) async {
        final commentSnap = await transaction.get(commentRef);
        
        if (!commentSnap.exists) {
          throw Exception('Comment not found');
        }

        final data = commentSnap.data()!;
        final likedBy = List<String>.from(data['likedBy'] ?? []);

        bool isCurrentlyLiked = likedBy.contains(userId);

        if (isCurrentlyLiked) {
          // Unlike: remove user from likedBy
          likedBy.remove(userId);
        } else {
          // Like: add user to likedBy
          likedBy.add(userId);
        }

        transaction.update(commentRef, {
          'likedBy': likedBy,
          'likeCount': likedBy.length,
        });

        debugPrint('Comment ${isCurrentlyLiked ? 'unliked' : 'liked'}: $commentId');
      });

    } catch (e) {
      debugPrint('Error toggling comment like: $e');
      rethrow;
    }
  }

  /// Edit an existing comment
  static Future<void> editComment({
    required String eventId,
    required String commentId,
    required String newContent,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User must be authenticated to edit comments');
      }

      if (newContent.trim().isEmpty) {
        throw Exception('Comment content cannot be empty');
      }

      final commentRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('comments')
          .doc(commentId);

      await _firestore.runTransaction((transaction) async {
        final commentSnap = await transaction.get(commentRef);
        
        if (!commentSnap.exists) {
          throw Exception('Comment not found');
        }

        final data = commentSnap.data()!;
        final authorId = data['authorId'] as String;

        // Check if current user is the author
        if (authorId != userId) {
          throw Exception('Only the comment author can edit this comment');
        }

        transaction.update(commentRef, {
          'content': newContent.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isEdited': true,
        });

        debugPrint('Comment edited successfully: $commentId');
      });

    } catch (e) {
      debugPrint('Error editing comment: $e');
      rethrow;
    }
  }

  /// Delete a comment (soft delete)
  static Future<void> deleteComment(String eventId, String commentId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User must be authenticated to delete comments');
      }

      final commentRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('comments')
          .doc(commentId);

      await _firestore.runTransaction((transaction) async {
        final commentSnap = await transaction.get(commentRef);
        
        if (!commentSnap.exists) {
          throw Exception('Comment not found');
        }

        final data = commentSnap.data()!;
        final authorId = data['authorId'] as String;

        // Check if current user is the author
        if (authorId != userId) {
          throw Exception('Only the comment author can delete this comment');
        }

        // Soft delete - mark as deleted but keep the document
        transaction.update(commentRef, {
          'isDeleted': true,
          'content': '[Comment deleted]',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('Comment deleted successfully: $commentId');
      });

      // Update event comment count
      final eventRef = _firestore.collection('events').doc(eventId);
      await eventRef.update({
        'commentCount': FieldValue.increment(-1),
      });

    } catch (e) {
      debugPrint('Error deleting comment: $e');
      rethrow;
    }
  }

  /// Get comment count for an event
  static Stream<int> getCommentCountStream(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return 0;
          final data = snapshot.data()!;
          return data['commentCount'] as int? ?? 0;
        });
  }

  /// Report a comment (for moderation)
  static Future<void> reportComment({
    required String eventId,
    required String commentId,
    required String reason,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User must be authenticated to report comments');
      }

      final reportRef = _firestore.collection('reports').doc();
      
      await reportRef.set({
        'reportId': reportRef.id,
        'reporterId': userId,
        'reporterName': _auth.currentUser?.displayName ?? 'Anonymous',
        'type': 'comment',
        'eventId': eventId,
        'commentId': commentId,
        'reason': reason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Comment reported successfully: $commentId');

    } catch (e) {
      debugPrint('Error reporting comment: $e');
      rethrow;
    }
  }

  /// Get comments by user (for user profile)
  static Stream<List<Comment>> getUserCommentsStream(String userId, {int limit = 50}) {
    return _firestore
        .collectionGroup('comments')
        .where('authorId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Comment.fromFirestore(doc))
              .toList();
        });
  }

  /// Search comments within an event
  static Future<List<Comment>> searchComments({
    required String eventId,
    required String searchTerm,
    int limit = 20,
  }) async {
    try {
      if (searchTerm.trim().isEmpty) return [];

      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation - for production, consider using Algolia or similar
      final snapshot = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('comments')
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit * 3) // Get more to filter locally
          .get();

      final comments = snapshot.docs
          .map((doc) => Comment.fromFirestore(doc))
          .where((comment) => 
              comment.content.toLowerCase().contains(searchTerm.toLowerCase()) ||
              comment.authorName.toLowerCase().contains(searchTerm.toLowerCase()))
          .take(limit)
          .toList();

      return comments;

    } catch (e) {
      debugPrint('Error searching comments: $e');
      return [];
    }
  }

  /// Get comment statistics for an event
  static Future<Map<String, dynamic>> getCommentStats(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('comments')
          .where('isDeleted', isEqualTo: false)
          .get();

      final comments = snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
      
      final topLevelComments = comments.where((c) => c.parentCommentId == null).length;
      final replies = comments.where((c) => c.parentCommentId != null).length;
      final totalLikes = comments.fold<int>(0, (sum, comment) => sum + comment.likeCount);
      
      // Get unique commenters
      final uniqueCommenters = comments.map((c) => c.authorId).toSet().length;

      return {
        'totalComments': comments.length,
        'topLevelComments': topLevelComments,
        'replies': replies,
        'totalLikes': totalLikes,
        'uniqueCommenters': uniqueCommenters,
      };

    } catch (e) {
      debugPrint('Error getting comment stats: $e');
      return {
        'totalComments': 0,
        'topLevelComments': 0,
        'replies': 0,
        'totalLikes': 0,
        'uniqueCommenters': 0,
      };
    }
  }
}