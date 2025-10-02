# Comment System Integration Guide

This guide shows how to integrate the new comment system into your existing CentrX app components.

## Quick Integration Examples

### 1. Update Event Cards to Use New Comment Button

Replace the old comment button in your event cards:

```dart
// OLD - in your event card widget
CommentButton(
  icon: IconlyBold.chat,
  count: event.commentCount,
  onTap: () => SocialButtonServices.showComments(context, event.eventId),
  color: Colors.white,
)

// NEW - enhanced comment button
CommentButton(
  eventId: event.eventId,
  eventTitle: event.title,
  commentCount: event.commentCount,
  color: Colors.white,
)
```

### 2. Update Events Page Video Overlay

In `lib/pages/events_page.dart`, update the video overlay to use the new comment system:

```dart
// OLD - line 174 in events_page.dart
onCommentTap: () => (SocialButtonServices.showComments(context, eventId)),

// NEW - use the enhanced method
onCommentTap: () => SocialButtonServices.showComments(
  context, 
  eventId, 
  eventTitle: title,
),
```

### 3. Add Comment Functionality to Event Details Page

In `lib/pages/event_details_page.dart`, add a comment section:

```dart
// Add this to your event details page
Row(
  children: [
    // Existing RSVP button
    // ...
    
    // Add comment button
    CommentButton(
      eventId: widget.event.eventId,
      eventTitle: widget.event.title,
      commentCount: widget.event.commentCount,
      color: Colors.grey[600],
    ),
  ],
)
```

### 4. Real-time Comment Count Updates

Update your event model to listen for real-time comment count changes:

```dart
// In your event card or details widget
StreamBuilder<int>(
  stream: CommentService.getCommentCountStream(event.eventId),
  builder: (context, snapshot) {
    final commentCount = snapshot.data ?? event.commentCount;
    return CommentButton(
      eventId: event.eventId,
      eventTitle: event.title,
      commentCount: commentCount,
    );
  },
)
```

## Required Firestore Security Rules

Add these rules to your Firestore security rules file:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Comment rules
    match /events/{eventId}/comments/{commentId} {
      // Anyone can read comments
      allow read: if true;
      
      // Only authenticated users can create comments
      allow create: if request.auth != null 
                   && request.auth.uid == resource.data.authorId
                   && validateCommentData(resource.data);
      
      // Only comment author can update/delete
      allow update, delete: if request.auth != null 
                           && request.auth.uid == resource.data.authorId;
    }
    
    // Helper function to validate comment data
    function validateCommentData(data) {
      return data.keys().hasAll(['commentId', 'authorId', 'authorName', 'eventId', 'content', 'createdAt']) &&
             data.content is string &&
             data.content.size() > 0 &&
             data.content.size() <= 1000; // Max 1000 characters
    }
    
    // Event rules (add comment count updates)
    match /events/{eventId} {
      allow read: if true;
      allow update: if request.auth != null && 
                   (resource.data.ownerId == request.auth.uid || 
                    onlyUpdatingCommentCount());
    }
    
    function onlyUpdatingCommentCount() {
      return request.resource.data.diff(resource.data).affectedKeys().hasOnly(['commentCount']);
    }
    
    // User activity tracking
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Reports collection for moderation
    match /reports/{reportId} {
      allow create: if request.auth != null && 
                   request.auth.uid == resource.data.reporterId;
      allow read, update: if request.auth != null; // Admin access only in production
    }
  }
}
```

## Component Features

### CommentsSheet Features:
- ✅ Real-time comment updates
- ✅ Threaded replies support
- ✅ Like/unlike comments
- ✅ Edit/delete own comments
- ✅ Drag-to-resize sheet
- ✅ Auto-scroll to new comments
- ✅ Empty state handling
- ✅ Error state handling
- ✅ Haptic feedback

### CommentService Features:
- ✅ Real-time streams
- ✅ Atomic batch operations
- ✅ Comment validation
- ✅ User activity tracking
- ✅ Comment statistics
- ✅ Search functionality
- ✅ Report system
- ✅ Soft delete

### Comment Model Features:
- ✅ Firestore serialization
- ✅ Type-safe properties
- ✅ Helper methods
- ✅ Equality operators
- ✅ Copy with functionality

## Migration Notes

1. **Existing Comments**: The new system stores comments in a different structure. You may need to migrate existing comments from your current system.

2. **Event Model Updates**: Update your Event model to include `commentCount` field if it doesn't exist.

3. **User Collection**: The system tracks user activity in the `users` collection. Ensure your user documents have proper structure.

4. **Permissions**: Update your Firestore rules as shown above before deploying.

## Performance Considerations

- Comments use Firestore subcollections for better organization
- Real-time listeners are automatically managed by Flutter
- Pagination can be added to `CommentService` methods if needed
- Consider implementing comment caching for offline support

## Testing

Test the comment system with:
1. Post comments and replies
2. Like/unlike comments
3. Edit and delete comments
4. Real-time updates across devices
5. Error handling (network issues, permissions)
6. Empty states and loading states