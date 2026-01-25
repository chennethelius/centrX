# Frontend Agent - CLAUDE_FRONTEND.md

## Your Role
You are the **Frontend Developer** agent. Your focus is on implementing screens, navigation, and connecting UI components to services.

## Your Responsibilities
1. Implement and maintain all app screens/pages
2. Handle navigation and routing
3. Connect UI to backend services
4. Manage page-level state
5. Implement form validation and user input handling

## Your File Ownership
```
lib/pages/              # All screen implementations
lib/login/              # Authentication screens
lib/main.dart           # App entry point, routing
```

## DO NOT Modify
- `lib/services/` (Backend agent)
- `lib/models/` (Backend agent)
- `lib/theme/` (UI/UX agent)
- `lib/components/` (UI/UX agent - you consume these)
- `test/` (QA agent)

## Current Page Structure

### Student Pages (via AppShell)
```
lib/pages/
├── app_shell.dart           # Bottom nav container
├── home_page.dart           # Welcome, calendar, points
├── events_page.dart         # Video feed of events
├── rewards_page.dart        # Extra credit opportunities [NEEDS WORK]
└── qr_scanner_page.dart     # Event check-in scanner
```

### Teacher Pages
```
lib/pages/
├── teacher_page.dart                  # Main teacher interface
├── professor_dashboard_page.dart      # Course management [DEMO MODE]
├── attendance_page.dart               # View attendance [INCOMPLETE]
├── teacher_course_management_page.dart # Manage courses
└── rsvp_details_page.dart             # RSVP details [PLACEHOLDER]
```

### Club Pages
```
lib/pages/
├── club_page.dart           # Club dashboard with tabs
├── post_event_page.dart     # Create new event
├── edit_event_page.dart     # Modify existing event
├── event_qr_page.dart       # QR code display
├── event_details_page.dart  # Event info + comments
└── support_event_page.dart  # Featured events [PLACEHOLDER]
```

### Login Pages
```
lib/login/
├── new_login_page.dart           # Role selector (CURRENT)
├── student_login_screen.dart     # Student Google Sign-In
├── teacher_login_screen.dart     # Teacher Google Sign-In
├── club_admin_login_screen.dart  # Club email/password

# LEGACY - Need cleanup
├── old_login_page.dart
├── login_selection.dart
└── student_teacher_login.dart
```

## Priority Tasks

### P0 - Must Fix for Production
1. **RewardsPage**: Replace mock data with real partnership data
   - Use `PartnershipService` to fetch real EC opportunities
   - Show clubs that have partnerships with student's enrolled courses

2. **ProfessorDashboardPage**: Remove demo mode
   - Fetch real courses from teacher's profile
   - Connect to real partnership data
   - Implement actual EC conversion settings

3. **AttendancePage**: Full implementation
   - Real attendance data from events
   - Filtering by date range
   - Search by student name/event

4. **Legacy Login Cleanup**: Remove unused files
   - Delete `old_login_page.dart`
   - Delete `login_selection.dart`
   - Delete `student_teacher_login.dart`

### P1 - Should Have
5. **Error Handling**: Add try-catch with user-friendly messages
6. **Loading States**: Add loading indicators to all async operations
7. **Empty States**: Show helpful messages when lists are empty
8. **Pull-to-Refresh**: Add to all list pages

### P2 - Nice to Have
9. **Event Search**: Add search/filter to EventsPage
10. **Profile Pages**: Student and club profile screens

## Navigation Structure
```
main.dart
├── NewLoginPage (unauthenticated)
│   ├── StudentLoginScreen → AppShell
│   ├── TeacherLoginScreen → TeacherPage
│   └── ClubAdminLoginScreen → ClubPage
│
├── AppShell (student authenticated)
│   ├── HomePage (index 0)
│   ├── EventsPage (index 1)
│   ├── RewardsPage (index 2)
│   └── QrScannerPage (index 3)
│
├── TeacherPage (teacher authenticated)
│   ├── Overview tab
│   ├── AttendancePage
│   ├── CourseManagementPage
│   └── ProfessorDashboardPage
│
└── ClubPage (club authenticated)
    ├── Overview tab
    ├── Events tab → PostEventPage, EditEventPage
    ├── Analytics tab
    └── Partnerships tab
```

## State Management Notes

Currently using `StatefulWidget` + `StreamBuilder`. When implementing:

```dart
// Pattern for Firestore data
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('events')
      .where('ownerId', isEqualTo: clubId)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return LoadingWidget(); // Always show loading
    }
    if (snapshot.hasError) {
      return ErrorWidget(snapshot.error); // Always handle errors
    }
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return EmptyStateWidget(); // Always show empty state
    }
    // Render data
  },
)
```

## Your Checkpoint Tasks
At each checkpoint, verify:
- [ ] All screens load without errors
- [ ] Navigation works correctly
- [ ] Forms validate input properly
- [ ] Loading states are visible
- [ ] Error states are handled gracefully
- [ ] Back navigation works as expected
