import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';
import '../theme/theme_extensions.dart';

class CommentTile extends StatefulWidget {
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
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _showReplies = false;
  List<Comment> _replies = [];
  StreamSubscription<List<Comment>>? _repliesSubscription;
  
  @override
  void initState() {
    super.initState();
    _loadReplies();
  }
  
  void _loadReplies() {
    _repliesSubscription?.cancel();
    _repliesSubscription = CommentService.getRepliesStream(widget.eventId, widget.comment.commentId).listen((replies) {
      if (mounted) {
        setState(() {
          _replies = replies;
          // Auto-show replies if there are any
          if (replies.isNotEmpty && !_showReplies) {
            _showReplies = true;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _repliesSubscription?.cancel();
    super.dispose();
  }

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
                backgroundImage: widget.comment.authorAvatar.isNotEmpty
                    ? NetworkImage(widget.comment.authorAvatar)
                    : null,
                child: widget.comment.authorAvatar.isEmpty
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
                          widget.comment.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimeAgo(widget.comment.createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        if (widget.comment.isEdited) ...[
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
                      widget.comment.content,
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
                        if (_canEdit) _buildEditButton(context),
                        if (_canDelete) _buildDeleteButton(context),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Show replies if this is a top-level comment
          if (widget.comment.parentCommentId == null && _replies.isNotEmpty)
            _buildRepliesSection(context),
        ],
      ),
    );
  }
  
  Widget _buildLikeButton(BuildContext context) {
    final isLiked = widget.comment.isLikedByUser(FirebaseAuth.instance.currentUser?.uid);
    
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
          if (widget.comment.likeCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              widget.comment.likeCount.toString(),
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
      onTap: () => widget.onReply(widget.comment),
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
      onTap: () => widget.onEdit(widget.comment),
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
      onTap: () => widget.onDelete(widget.comment),
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
    return Column(
      children: [
        const SizedBox(height: 8),
        ..._replies.map((reply) => Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0),
          child: CommentTile(
            comment: reply,
            eventId: widget.eventId,
            onReply: widget.onReply,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
          ),
        )).toList(),
      ],
    );
  }  bool get _canEdit {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return widget.comment.isAuthoredByUser(currentUserId) && !widget.comment.isDeleted;
  }

  bool get _canDelete {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return widget.comment.isAuthoredByUser(currentUserId) && !widget.comment.isDeleted;
  }
  
  Future<void> _toggleLike(BuildContext context) async {
    print('DEBUG: Attempting to like comment ${widget.comment.commentId}');
    print('DEBUG: Comment author: ${widget.comment.authorId}');
    print('DEBUG: Current user: ${FirebaseAuth.instance.currentUser?.uid}');
    print('DEBUG: Currently liked: ${widget.comment.isLikedByUser(FirebaseAuth.instance.currentUser?.uid)}');
    
    try {
      await CommentService.toggleCommentLike(widget.eventId, widget.comment.commentId);
      print('DEBUG: Like toggle successful');
    } catch (e) {
      print('DEBUG: Like toggle failed: $e');
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