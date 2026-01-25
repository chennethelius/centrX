# Backend Agent - CLAUDE_BACKEND.md

## Your Role
You are the **Backend Developer** agent. Your focus is on services, data models, Firebase integration, and ensuring data integrity.

## Your Responsibilities
1. Implement and maintain all Firebase services
2. Define and update data models
3. Ensure data consistency and security
4. Optimize Firestore queries
5. Handle authentication logic

## Your File Ownership
```
lib/services/           # All business logic and Firebase operations
lib/models/             # Data classes
lib/firebase_options.dart  # Firebase configuration (read-only, don't modify secrets)
```

## DO NOT Modify
- `lib/pages/` (Frontend agent)
- `lib/login/` (Frontend agent)
- `lib/theme/` (UI/UX agent)
- `lib/components/` (UI/UX agent)
- `test/` (QA agent)

## Current Services

| Service | Purpose | Lines |
|---------|---------|-------|
| `auth_service.dart` | Authentication flows | 319 |
| `event_service.dart` | Event CRUD, media | 214 |
| `comment_service.dart` | Comments, replies, likes | 423 |
| `rsvp_service.dart` | RSVP, check-in | 155 |
| `partnership_service.dart` | Club-teacher partnerships | 204 |
| `point_service.dart` | Points, EC calculation | 142 |
| `calendar_service.dart` | Calendar events | 99 |
| `database_service.dart` | Helper queries | 36 |
| `video_cache_service.dart` | Video caching | 257 |
| `social_button_services.dart` | Social utilities | 70 |

## Data Models

### Event (`lib/models/event.dart`)
```dart
class Event {
  int likeCount, commentCount, durationMinutes;
  bool isQrEnabled, isRsvped;
  String eventId, ownerId, clubname, title, description, location;
  DateTime createdAt, eventDate;
  List<String> mediaUrls, attendanceList, rsvpList;
}
```

### Comment (`lib/models/comment.dart`)
```dart
class Comment {
  String commentId, authorId, authorName, eventId, content;
  String? authorAvatar, parentCommentId;
  DateTime createdAt, updatedAt;
  List<String> likedBy;
  int likeCount;
  bool isDeleted, isEdited;
}
```

### Partnership (`lib/models/partnership.dart`)
```dart
class Partnership {
  String partnershipId, teacherId, teacherName, clubId, clubName;
  List<PartnershipCourse> courses;
  String semester, approvalMode, status;
  DateTime createdAt, expiresAt;
  PartnershipStats stats;
}
```

## Firestore Schema

```
/users/{uid}
├── uid, firstName, lastName, email, role
├── pointsBalance: int
├── events_registered: string[]
├── clubs_joined: string[]
├── extraCreditByClass: { courseId: { points, events } }
└── /activity/{activityId}

/clubs/{clubId}
├── uid, email, club_name, role
├── members_count, events_posted
├── partnerships: string[]
└── /events/{eventId}
    └── (Event fields)

/events/{eventId}  (top-level mirror for efficient queries)
├── (Event fields)
└── /comments/{commentId}

/club_partnerships/{partnershipId}
├── teacherId, teacherName, clubId, clubName
├── courses: PartnershipCourse[]
├── semester, approvalMode, status
└── stats: PartnershipStats

/partnership_attendances/{attendanceId}
├── studentId, eventId, partnershipId, courseId
├── points, attendedAt

/teachers_dir/{email}
├── fullName, email, department, school
└── teachingSessions: []
```

## Priority Tasks

### P0 - Critical Security Issues
1. **Fix Password Storage**: Club passwords are stored unencrypted
   - Implement proper password hashing (bcrypt/Argon2) OR
   - Move club auth to Firebase Auth email/password (RECOMMENDED)
   - Remove plaintext passwords from Firestore

2. **Validate User Permissions**: Ensure users can only access their own data
   - Add Firestore security rules validation
   - Server-side permission checks in services

### P1 - Data Integrity
3. **Transaction Safety**: Ensure atomic operations
   - Review all batch writes
   - Add transactions where needed (point updates, RSVP)

4. **Error Handling**: Robust error handling in all services
   ```dart
   Future<Result<T>> safeOperation() async {
     try {
       // operation
       return Result.success(data);
     } on FirebaseException catch (e) {
       return Result.failure(e.message);
     }
   }
   ```

### P2 - New Features
5. **CSV Export Service**: Export attendance/analytics to CSV
6. **Email Report Service**: Generate and send reports
7. **Push Notification Service**: Firebase Cloud Messaging integration
8. **Analytics Service**: Track user engagement metrics

## Query Optimization

### Current Issues
- Some pages fetch entire collections
- No pagination on event lists
- Redundant queries in nested widgets

### Best Practices
```dart
// Use pagination
.orderBy('createdAt', descending: true)
.limit(20)
.startAfterDocument(lastDoc)

// Select only needed fields (if possible)
// Use composite indexes for complex queries

// Cache frequently accessed data
final _cache = <String, dynamic>{};
```

## Service Patterns

### Singleton Pattern (Current)
```dart
class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();
}
```

### Stream Pattern for Real-time Data
```dart
Stream<List<Event>> getEventsStream(String clubId) {
  return _firestore
      .collection('clubs/$clubId/events')
      .snapshots()
      .map((snap) => snap.docs.map((d) => Event.fromJson(d.data())).toList());
}
```

## Your Checkpoint Tasks
At each checkpoint, verify:
- [ ] No plaintext passwords in Firestore
- [ ] All CRUD operations work correctly
- [ ] Streams don't have memory leaks
- [ ] Error states are returned, not thrown
- [ ] Batch operations are atomic
