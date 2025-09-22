import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconly/iconly.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';
import '../theme/theme_extensions.dart';
import 'comment_tile.dart';

class CommentsSheet extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  
  const CommentsSheet({
    required this.eventId,
    required this.eventTitle,
    super.key,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  
  String? _replyingToCommentId;
  String? _replyingToAuthor;
  bool _isPosting = false;
  
  // Add local state for optimistic updates and error handling
  List<Comment> _localComments = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Comment>>? _commentsSubscription;

  @override
  void initState() {
    super.initState();
    _setupCommentsStream();
  }

  void _setupCommentsStream() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _commentsSubscription?.cancel();
    _commentsSubscription = CommentService.getCommentsStream(widget.eventId).listen(
      (comments) {
        if (mounted) {
          setState(() {
            _localComments = comments;
            _isLoading = false;
            _errorMessage = null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = error.toString();
          });
        }
      },
    );
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _commentsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildCommentsList(scrollController),
              ),
              _buildCommentInput(),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          
          // Header row
          Row(
            children: [
              Icon(
                IconlyBold.chat,
                size: 20,
                color: context.accentNavy,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              // Event title
              Flexible(
                child: Text(
                  widget.eventTitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Close button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCommentsList(ScrollController scrollController) {
    // Show loading state
    if (_isLoading && _localComments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Show error state with retry option
    if (_errorMessage != null && _localComments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load comments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your internet connection',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _setupCommentsStream,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    

    
    // Show comments or empty state
    return _buildCommentList(scrollController, _localComments);
  }

  Widget _buildCommentList(ScrollController scrollController, List<Comment> comments) {
    if (comments.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        return CommentTile(
          comment: comments[index],
          eventId: widget.eventId,
          onReply: _startReply,
          onEdit: _editComment,
          onDelete: _deleteComment,
        );
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconlyLight.chat,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your thoughts!',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCommentInput() {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply indicator
          if (_replyingToCommentId != null) _buildReplyIndicator(),
          
          // Input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // User avatar
              CircleAvatar(
                radius: 16,
                backgroundImage: currentUser?.photoURL != null
                    ? NetworkImage(currentUser!.photoURL!)
                    : null,
                child: currentUser?.photoURL == null
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Text input
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: _replyingToCommentId != null 
                          ? 'Reply to $_replyingToAuthor...'
                          : 'Add a comment...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}), // Update send button state
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Send button
              GestureDetector(
                onTap: _canSendComment() ? _postComment : null,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _canSendComment() 
                        ? context.accentNavy
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _isPosting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.send,
                          color: _canSendComment() 
                              ? Colors.white
                              : Colors.grey[500],
                          size: 16,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildReplyIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 16,
            color: Colors.blue[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Replying to $_replyingToAuthor',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: _cancelReply,
            child: Icon(
              Icons.close,
              size: 16,
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }
  
  bool _canSendComment() {
    return _commentController.text.trim().isNotEmpty && !_isPosting;
  }
  
  void _startReply(Comment comment) {
    setState(() {
      _replyingToCommentId = comment.commentId;
      _replyingToAuthor = comment.authorName;
    });
    
    // Focus the text field
    _focusNode.requestFocus();
  }
  
  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToAuthor = null;
    });
  }
  
  Future<void> _postComment() async {
    if (!_canSendComment()) return;
    
    final content = _commentController.text.trim();
    final currentUser = FirebaseAuth.instance.currentUser!;
    
    setState(() {
      _isPosting = true;
    });
    
    // Create optimistic comment for immediate UI update
    final optimisticComment = Comment(
      commentId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      authorId: currentUser.uid,
      authorName: currentUser.displayName ?? 'Anonymous User',
      authorAvatar: currentUser.photoURL ?? '',
      eventId: widget.eventId,
      content: content,
      createdAt: DateTime.now(),
      parentCommentId: _replyingToCommentId,
    );
    
    // Add optimistic comment to local cache
    if (_replyingToCommentId == null) {
      setState(() {
        _localComments = [..._localComments, optimisticComment];
      });
    }
    
    try {
      // Haptic feedback
      HapticFeedback.lightImpact();
      
      final commentId = await CommentService.postComment(
        eventId: widget.eventId,
        content: content,
        parentCommentId: _replyingToCommentId,
      );
      
      // Clear input and cancel reply
      _commentController.clear();
      _cancelReply();
      
      // Remove optimistic comment and let the stream handle the real one
      if (_replyingToCommentId == null && commentId != null) {
        setState(() {
          _localComments = _localComments.where((c) => c.commentId != optimisticComment.commentId).toList();
        });
      }
      
      // Auto-scroll to bottom for new comments
      if (_replyingToCommentId == null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
      
    } catch (e) {
      // Remove optimistic comment on error
      if (_replyingToCommentId == null) {
        setState(() {
          _localComments = _localComments.where((c) => c.commentId != optimisticComment.commentId).toList();
        });
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: ${e.toString()}'),
            backgroundColor: context.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }
  
  void _editComment(Comment comment) {
    final TextEditingController editController = TextEditingController(text: comment.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            hintText: 'Edit your comment...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newContent = editController.text.trim();
              if (newContent.isEmpty) {
                return;
              }
              
              Navigator.pop(context);
              
              try {
                await CommentService.editComment(
                  eventId: widget.eventId,
                  commentId: comment.commentId,
                  newContent: newContent,
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comment updated'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update comment: ${e.toString()}'),
                      backgroundColor: context.errorRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _deleteComment(Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text(
          'Are you sure you want to delete this comment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await CommentService.deleteComment(widget.eventId, comment.commentId);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comment deleted'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete comment: ${e.toString()}'),
                      backgroundColor: context.errorRed,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}