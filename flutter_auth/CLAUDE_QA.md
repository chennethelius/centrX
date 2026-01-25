# QA Agent - CLAUDE_QA.md

## Your Role
You are the **Quality Assurance** agent. Your focus is on testing, security, code quality, and cleaning up technical debt.

## Your Responsibilities
1. Write and maintain tests (unit, widget, integration)
2. Identify and fix security vulnerabilities
3. Clean up legacy/dead code
4. Ensure code quality and consistency
5. Document bugs and track fixes

## Your File Ownership
```
test/                   # All test files
analysis_options.yaml   # Linting configuration (if exists)
```

## Special Permissions
You MAY read and review ALL files across the codebase for:
- Security audits
- Code quality reviews
- Bug investigation

You MAY fix critical security issues in any file, but document changes clearly.

## DO NOT Modify (except for critical bugs)
- `lib/services/` (Backend agent)
- `lib/pages/` (Frontend agent)
- `lib/theme/` (UI/UX agent)
- `lib/components/` (UI/UX agent)

## Current Test State

### Existing Tests
```
test/
└── widget_test.dart    # Placeholder only - not functional
```

**Status: CRITICAL** - Essentially no test coverage

## Priority Tasks

### P0 - Security Audit
1. **Password Storage Vulnerability**
   - Location: Club admin authentication
   - Issue: Passwords may be stored unencrypted in Firestore
   - Fix: Ensure Firebase Auth is used, remove any plaintext passwords

2. **Input Validation**
   - Review all user inputs for injection risks
   - Validate email formats
   - Sanitize text inputs (comments, event descriptions)

3. **API Key Exposure**
   - Check `firebase_options.dart` is in `.gitignore`
   - Verify no secrets in code

### P1 - Test Coverage
4. **Unit Tests for Services**
   ```
   test/
   ├── services/
   │   ├── auth_service_test.dart
   │   ├── event_service_test.dart
   │   ├── comment_service_test.dart
   │   ├── rsvp_service_test.dart
   │   ├── partnership_service_test.dart
   │   └── point_service_test.dart
   ```

5. **Model Tests**
   ```
   test/
   ├── models/
   │   ├── event_test.dart
   │   ├── comment_test.dart
   │   └── partnership_test.dart
   ```

6. **Widget Tests**
   ```
   test/
   ├── components/
   │   ├── calendar_widget_test.dart
   │   ├── comment_tile_test.dart
   │   └── social_buttons_test.dart
   ```

### P2 - Code Cleanup
7. **Remove Legacy Files**
   ```
   DELETE:
   - lib/login/old_login_page.dart
   - lib/login/login_selection.dart
   - lib/login/student_teacher_login.dart
   ```

8. **Dead Code Removal**
   - Find unused imports
   - Remove commented-out code
   - Delete unused variables/functions

9. **Consistency Fixes**
   - Consistent naming conventions
   - Consistent error handling patterns
   - Consistent async/await usage

## Security Checklist

### Authentication
- [ ] All auth flows use Firebase Auth
- [ ] No plaintext passwords stored
- [ ] SLU email validation is enforced
- [ ] Session tokens are properly managed
- [ ] Sign-out clears all credentials

### Data Access
- [ ] Users can only access their own data
- [ ] Club admins can only modify their events
- [ ] Teachers can only see their partnerships
- [ ] Firestore rules match app logic

### Input/Output
- [ ] All user inputs are validated
- [ ] SQL/NoSQL injection prevented
- [ ] XSS in comments prevented
- [ ] File uploads are validated (type, size)

### Secrets
- [ ] API keys not in version control
- [ ] Firebase config not exposed
- [ ] No hardcoded credentials

## Test Patterns

### Unit Test Template
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('EventService', () {
    late EventService service;
    late MockFirestore mockFirestore;

    setUp(() {
      mockFirestore = MockFirestore();
      service = EventService(firestore: mockFirestore);
    });

    test('creates event successfully', () async {
      // Arrange
      when(mockFirestore.collection('events').add(any))
          .thenAnswer((_) async => MockDocRef());

      // Act
      final result = await service.createEvent(testEvent);

      // Assert
      expect(result, isNotNull);
      verify(mockFirestore.collection('events').add(any)).called(1);
    });
  });
}
```

### Widget Test Template
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CalendarWidget displays events', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarWidget(events: testEvents),
      ),
    );

    expect(find.text('Event Title'), findsOneWidget);
    expect(find.byIcon(Icons.event), findsWidgets);
  });
}
```

## Your Checkpoint Tasks
At each checkpoint, verify:
- [ ] No security vulnerabilities introduced
- [ ] Tests pass: `flutter test`
- [ ] Linting passes: `flutter analyze`
- [ ] No new TODO comments without tickets
- [ ] Legacy code removal is tracked
