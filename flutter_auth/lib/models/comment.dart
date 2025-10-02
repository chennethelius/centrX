import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String commentId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String eventId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> likedBy;
  final int likeCount;
  final String? parentCommentId; // For replies
  final bool isDeleted;
  final bool isEdited;
  
  Comment({
    required this.commentId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.eventId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.likedBy = const [],
    this.likeCount = 0,
    this.parentCommentId,
    this.isDeleted = false,
    this.isEdited = false,
  });

  /// Create Comment from Firestore DocumentSnapshot
  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      commentId: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Anonymous',
      authorAvatar: data['authorAvatar'] as String? ?? '',
      eventId: data['eventId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      likedBy: List<String>.from(data['likedBy'] as List<dynamic>? ?? []),
      likeCount: data['likeCount'] as int? ?? 0,
      parentCommentId: data['parentCommentId'] as String?,
      isDeleted: data['isDeleted'] as bool? ?? false,
      isEdited: data['isEdited'] as bool? ?? false,
    );
  }

  /// Create Comment from JSON map
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['commentId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Anonymous',
      authorAvatar: json['authorAvatar'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] is Timestamp 
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : json['updatedAt'] != null 
              ? DateTime.tryParse(json['updatedAt'] as String)
              : null,
      likedBy: List<String>.from(json['likedBy'] as List<dynamic>? ?? []),
      likeCount: json['likeCount'] as int? ?? 0,
      parentCommentId: json['parentCommentId'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      isEdited: json['isEdited'] as bool? ?? false,
    );
  }

  /// Convert Comment to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'eventId': eventId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'likedBy': likedBy,
      'likeCount': likeCount,
      'parentCommentId': parentCommentId,
      'isDeleted': isDeleted,
      'isEdited': isEdited,
    };
  }

  /// Create a copy of this Comment with updated fields
  Comment copyWith({
    String? commentId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? eventId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? likedBy,
    int? likeCount,
    String? parentCommentId,
    bool? isDeleted,
    bool? isEdited,
  }) {
    return Comment(
      commentId: commentId ?? this.commentId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      eventId: eventId ?? this.eventId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likedBy: likedBy ?? this.likedBy,
      likeCount: likeCount ?? this.likeCount,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  /// Check if current user liked this comment
  bool isLikedByUser(String? userId) {
    return userId != null && likedBy.contains(userId);
  }

  /// Check if current user is the author
  bool isAuthoredByUser(String? userId) {
    return userId != null && authorId == userId;
  }

  @override
  String toString() {
    return 'Comment(commentId: $commentId, authorName: $authorName, content: $content, likeCount: $likeCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment && other.commentId == commentId;
  }

  @override
  int get hashCode => commentId.hashCode;
}