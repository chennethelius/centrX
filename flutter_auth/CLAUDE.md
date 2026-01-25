# CentrX Flutter App - Master CLAUDE.md

## Project Overview
CentrX is a multi-role event management and gamification platform for Saint Louis University (SLU).

### User Roles
- **Students**: Browse events, RSVP, scan QR codes for attendance, earn points for extra credit
- **Teachers/Professors**: Manage courses, create partnerships with clubs, award extra credit
- **Club Admins**: Create/manage events, generate QR codes, track attendance

### Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Auth, Storage)
- **Auth**: Google Sign-In (students/teachers), Email/Password (clubs)

## Directory Structure
```
lib/
├── main.dart              # Entry point, role-based routing
├── firebase_options.dart  # Firebase config
├── models/                # Data classes (Event, Comment, Partnership)
├── pages/                 # Full-screen pages
├── components/            # Reusable widgets
├── services/              # Business logic & Firebase operations
├── login/                 # Authentication screens
├── theme/                 # App theming (60-30-10 color system)
└── docs/                  # Project documentation
```

## Multi-Agent Development

This project uses multiple Claude agents working in parallel. Each agent has a specific focus area defined in their respective CLAUDE_*.md file.

### Agent Assignments
| Agent | File | Focus |
|-------|------|-------|
| Product | CLAUDE_PRODUCT.md | Features, user flows, requirements |
| UI/UX | CLAUDE_UIUX.md | Design system, visuals, components |
| Frontend | CLAUDE_FRONTEND.md | Screens, navigation, pages |
| Backend | CLAUDE_BACKEND.md | Services, models, Firebase |
| QA | CLAUDE_QA.md | Tests, security, code cleanup |

### Coordination Rules
1. **File Ownership**: Only modify files in your assigned directories
2. **Cross-Boundary Changes**: If you need to modify another agent's files, document it and wait for checkpoint
3. **Checkpoints**: User will run `flutter run` to test changes - pause when asked
4. **Conflicts**: If you see another agent's uncommitted changes, do not overwrite

## Current Production Blockers

### Critical (Must Fix)
- [ ] Security: Passwords stored unencrypted in Firestore (club auth)
- [ ] No state management library - scattered state, memory leak risks
- [ ] Minimal test coverage (only placeholder widget_test.dart)

### High Priority
- [ ] RewardsPage uses hardcoded mock data instead of real partnerships
- [ ] ProfessorDashboardPage is demo mode only
- [ ] CSV export not implemented
- [ ] Email reports not implemented
- [ ] Legacy login files need cleanup

### Medium Priority
- [ ] Analytics tabs in ClubPage incomplete
- [ ] AttendancePage skeleton implementation
- [ ] Video controller lifecycle edge cases

## Firestore Collections
```
/users/{uid}           - User profiles, points, enrolled events
/clubs/{clubId}        - Club profiles
/clubs/{clubId}/events - Club's events (subcollection)
/events/{eventId}      - Top-level events (for efficient queries)
/club_partnerships     - Teacher-Club partnerships
/partnership_attendances - EC attendance records
/teachers_dir          - Teacher directory for validation
```

## Key Commands
```bash
# Run app
flutter run -d "iPhone 16e"

# Clean build
flutter clean && flutter pub get

# iOS specific
cd ios && pod install && cd ..
```

## App Store Checklist
- [ ] Privacy Policy URL
- [ ] Terms of Service URL
- [ ] App Store screenshots (6.5", 5.5")
- [ ] App description and keywords
- [ ] Age rating questionnaire
- [ ] Push notification setup
- [ ] Error/crash reporting (Firebase Crashlytics)
- [ ] Analytics (Firebase Analytics)
- [ ] Performance monitoring
- [ ] Accessibility audit
