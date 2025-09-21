import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';
import '../theme/theme_extensions.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final String eventId;
  final Function(Comment) onReply;
  final Function(Comment) onEdit;
  final Function(Comment) onDelete;
  
  const CommentTile({
    required this.comment,
    required this.eventId,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User avatar
              CircleAvatar(
                radius: 18,
                backgroundImage: comment.authorAvatar.isNotEmpty
                    ? NetworkImage(comment.authorAvatar)
                    : null,
                child: comment.authorAvatar.isEmpty
                    ? const Icon(Icons.person, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Comment content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author and timestamp row
                    Row(
                      children: [
                        Text(
                          comment.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimeAgo(comment.createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        if (comment.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(edited)',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Comment text
                    Text(
                      comment.content,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    
                    // Action buttons row
                    Row(
                      children: [
                        _buildLikeButton(context),
                        const SizedBox(width: 16),
                        _buildReplyButton(context),
                        const Spacer(),
                        if (_canEdit()) _buildEditButton(context),
                        if (_canDelete()) _buildDeleteButton(context),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Show replies if this is a top-level comment
          if (comment.parentCommentId == null)
            _buildRepliesSection(context),
        ],
      ),
    );
  }
  
  Widget _buildLikeButton(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = comment.isLikedByUser(currentUserId);
    
    return GestureDetector(
      onTap: () => _toggleLike(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            size: 14,
            color: isLiked ? Colors.red : Colors.grey[600],
          ),
          if (comment.likeCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              comment.likeCount.toString(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildReplyButton(BuildContext context) {
    return GestureDetector(
      onTap: () => onReply(comment),
      child: Text(
        'Reply',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildEditButton(BuildContext context) {
    return GestureDetector(
      onTap: () => onEdit(comment),
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.edit_outlined,
          size: 16,
          color: Colors.grey[500],
        ),
      ),
    );
  }
  
  Widget _buildDeleteButton(BuildContext context) {
    return GestureDetector(
      onTap: () => onDelete(comment),
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.delete_outline,
          size: 16,
          color: Colors.grey[500],
        ),
      ),
    );
  }
  
  Widget _buildRepliesSection(BuildContext context) {
    return StreamBuilder<List<Comment>>(
      stream: CommentService.getRepliesStream(eventId, comment.commentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final replies = snapshot.data!;
        
        return Container(
          margin: const EdgeInsets.only(left: 42, top: 12),
          child: Column(
            children: replies.map((reply) => CommentTile(
              comment: reply,
              eventId: eventId,
              onReply: onReply,
              onEdit: onEdit,
              onDelete: onDelete,
            )).toList(),
          ),
        );
      },
    );
  }
  
  bool _canEdit() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return comment.isAuthoredByUser(currentUserId) && !comment.isDeleted;
  }
  
  bool _canDelete() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return comment.isAuthoredByUser(currentUserId) && !comment.isDeleted;
  }
  
  Future<void> _toggleLike(BuildContext context) async {
    try {
      await CommentService.toggleCommentLike(eventId, comment.commentId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like comment: ${e.toString()}'),
            backgroundColor: context.errorRed,
          ),
        );
      }
    }
  }
  
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return '1d';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '${weeks}w';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '${months}mo';
      } else {
        final years = (difference.inDays / 365).floor();
        return '${years}y';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}