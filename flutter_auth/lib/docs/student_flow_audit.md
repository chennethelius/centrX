# Student User Flow Audit

**Audit Date:** January 24, 2026
**Auditor:** Product Agent
**Version:** 1.0

---

## Executive Summary

This audit examines the complete student journey in the CentrX Flutter app, from login through earning extra credit points. While the core flow is functional, several gaps and UX issues were identified that should be addressed before App Store launch.

---

## Current Flow Description

### 1. Login (Entry Point)

**Files:**
- `/lib/login/new_login_page.dart` - Role selection screen
- `/lib/login/student_login.dart` - Student Google sign-in

**Flow:**
1. User opens app and sees role selection (Student, Professor, Club)
2. Student taps "Student" option
3. Redirected to `StudentLoginScreen` with "Continue with Google" button
4. On tap, triggers `AuthService.authenticateWithGoogle()`
5. SLU email validation enforced (`@slu.edu` only)
6. New users get Firestore document created with default fields
7. On success, navigate to `AppShell`

**Status:** Working

---

### 2. Main Container (App Shell)

**File:** `/lib/components/app_shell.dart`

**Flow:**
1. After login, user lands on `AppShell`
2. Bottom navigation with 4 tabs: Home, Events, Rewards, QR Scanner
3. `_currentIndex` tracks active tab, pages rendered via `_tabs` list

**Status:** Working

---

### 3. Home Page

**File:** `/lib/pages/home_page.dart`

**Flow:**
1. Displays welcome message with user's first name
2. Shows points balance from Firestore (`pointsBalance`)
3. Calendar widget shows RSVP'd events by date
4. Class enrollment section for managing enrolled courses
5. Logout button at bottom

**Status:** Partially Working

---

### 4. Browse Events

**File:** `/lib/pages/events_page.dart`

**Flow:**
1. TikTok-style vertical video feed
2. Fetches events from `/events` collection ordered by `createdAt`
3. Video player pool manages controller lifecycle
4. Each video shows overlay with title, description, location
5. Action buttons: Like, Comment, RSVP on right side

**Status:** Working (with performance concerns)

---

### 5. RSVP Flow

**Files:**
- `/lib/components/rsvp_button.dart` - Button component
- `/lib/components/video_overlay.dart` - Overlay layout
- `/lib/pages/rsvp_details.dart` - RSVP modal
- `/lib/services/rsvp_service.dart` - Backend logic

**Flow:**
1. User taps RSVP icon on video overlay
2. Opens `RsvpDetailsPage` modal with event details
3. Shows date, time, location, RSVP count
4. User taps "RSVP" button
5. `RsvpService.rsvpToEvent()` executes batch write:
   - Adds user to event's `rsvpList`
   - Adds eventId to user's `events_registered`
6. Modal closes, icon changes to checkmark

**Status:** Working

---

### 6. QR Code Check-in

**Files:**
- `/lib/pages/qr_scanner_page.dart` - Scanner UI
- `/lib/services/rsvp_service.dart` - Check-in logic

**Flow:**
1. User navigates to QR Scanner tab
2. Camera opens with scanning overlay
3. QR code format: `clubId|eventId|timestamp`
4. On scan, `RsvpService.checkInEvent()` executes:
   - Adds user to both `/clubs/{clubId}/events/{eventId}/attendanceList` and `/events/{eventId}/attendanceList`
   - Calls `_checkPartnershipEligibility()` for auto points
5. Shows success/error dialog

**Status:** Working

---

### 7. Earning Points (Partnership System)

**Files:**
- `/lib/services/point_service.dart` - Point awarding
- `/lib/services/partnership_service.dart` - Partnership queries

**Flow:**
1. After check-in, system checks for active club partnerships
2. For each partnership with `approvalMode: 'auto'`:
   - Checks if student is enrolled in partnered course
   - Checks if student hasn't exceeded cap
   - Awards points via `PointService.awardPartnershipPoints()`
3. Updates user's `pointsBalance` and `extraCreditByClass`
4. Creates `partnership_attendances` record for analytics

**Status:** Working (complex, limited visibility to user)

---

### 8. Rewards Page

**File:** `/lib/pages/rewards_page.dart`

**Flow:**
1. Currently displays mock professor data (hardcoded)
2. Features tab system (Featured, Favorites, Menu)
3. Professor cards with points costs
4. Cart system for "purchasing" rewards
5. **ENTIRE BUILD METHOD IS COMMENTED OUT** - Returns empty Scaffold

**Status:** BROKEN - Page is completely empty

---

## Identified Issues

### P0 - Critical (Must Fix Before Launch)

| ID | Issue | Location | Impact |
|----|-------|----------|--------|
| P0-1 | **RewardsPage is completely empty** - Build method body is commented out | `rewards_page.dart:141-297` | Users see blank page; core feature missing |
| P0-2 | **Mock data in RewardsPage** - Hardcoded professors, not from Firestore | `rewards_page.dart:30-99` | No connection to real courses/teachers |
| P0-3 | **No un-RSVP functionality** - Users cannot cancel RSVP | `rsvp_details.dart:213-221` | Button disabled after RSVP, no cancel option |
| P0-4 | **No error handling for QR check-in failures** - Generic error message | `qr_scanner_page.dart:56-57` | User sees raw error, no guidance |
| P0-5 | **No notification bell functionality** - Icon present but does nothing | `home_page.dart:155-165` | Misleading UI element |

### P1 - High Priority (Should Fix Before Launch)

| ID | Issue | Location | Impact |
|----|-------|----------|--------|
| P1-1 | **No visual feedback when points are earned** - Points awarded silently | `rsvp_service.dart:85-89` | Users don't know they earned points |
| P1-2 | **Calendar events not tappable for details** - Shows events but no action | `calendar_widget.dart:367-369` | Comment says "optional: navigate" but not implemented |
| P1-3 | **No event date/time shown in video overlay** - Missing key info | `video_overlay.dart` | Users don't know when event is happening |
| P1-4 | **No search/filter for events feed** - Only chronological scroll | `events_page.dart` | Hard to find specific events |
| P1-5 | **No "My Events" or "My RSVP'd Events" dedicated view** | Various | Users rely on calendar only to see commitments |
| P1-6 | **No loading state when RSVP button is processing** | `rsvp_button.dart` | `_busy` flag exists but not shown visually |
| P1-7 | **Class enrollment requires manual course+instructor selection** | `class_enrollment_widget.dart` | Error-prone, no autocomplete matching |
| P1-8 | **No points breakdown visible on Home page** | `home_page.dart` | Shows total points but not per-class breakdown |

### P2 - Medium Priority (Nice to Have)

| ID | Issue | Location | Impact |
|----|-------|----------|--------|
| P2-1 | **Video auto-plays when returning to Events page** - May be unexpected | `events_page.dart:59` | Audio starts without user intent |
| P2-2 | **No onboarding for first-time users** | N/A | New users don't understand app features |
| P2-3 | **QR timestamp is ignored** - Could validate event is currently active | `qr_scanner_page.dart:50` | Could check-in to past/future events |
| P2-4 | **No offline support** - App requires network | Various | Fails silently without connection |
| P2-5 | **No pull-to-refresh on Home page** | `home_page.dart` | Users can't manually refresh data |
| P2-6 | **Logout requires confirmation dialog twice** | `home_page.dart:331-366` | One dialog would suffice |
| P2-7 | **No profile/settings page** | N/A | Users cannot view/edit their info |

### P3 - Low Priority (Future Enhancements)

| ID | Issue | Location | Impact |
|----|-------|----------|--------|
| P3-1 | **No event sharing functionality** | N/A | Can't share events to friends |
| P3-2 | **No push notifications** | N/A | Users miss event reminders |
| P3-3 | **No event recommendations** | N/A | Manual discovery only |
| P3-4 | **No achievement/badge system** | N/A | Less gamification motivation |

---

## UX Flow Gaps

### Gap 1: Broken Rewards Experience
The Rewards page is the culmination of the student journey - they attend events, earn points, and redeem them. Currently:
- Page renders as empty scaffold
- Even if uncommented, uses mock data
- No connection to actual teacher partnerships
- "Purchasing" rewards has no backend action

**Recommendation:** This is the highest priority fix. The page needs to:
1. Fetch real courses from user's `enrolledClasses`
2. Show actual points earned per course from `extraCreditByClass`
3. Display partnership details (points-to-percentage conversion)
4. Remove "purchasing" concept - points auto-apply via partnerships

### Gap 2: Silent Point Earning
When a student scans a QR code and earns points:
- No visual confirmation of points earned
- No breakdown of which class got credit
- User must navigate to Home to see updated balance

**Recommendation:** After check-in success:
1. Show celebration animation
2. Display: "You earned X points for [Course Name]!"
3. Show running total: "Total: Y points"

### Gap 3: Missing Event Context
Video overlay shows title, description, location but:
- No date/time of event
- No club name (just `clubId` internally)
- No indication if user already RSVP'd visually before tapping

**Recommendation:** Add to overlay:
1. Event date and time prominently displayed
2. Club name/logo
3. Badge if already RSVP'd (currently icon changes but requires data load)

### Gap 4: Calendar-to-Event Disconnect
Calendar shows events on dates but:
- Tapping an event does nothing
- No way to navigate to event video/details from calendar
- No way to cancel RSVP from calendar view

**Recommendation:** Calendar event tap should:
1. Open event details modal (similar to RSVP modal)
2. Show option to cancel RSVP
3. Deep link to event in video feed

### Gap 5: No Points Visibility in Journey
Points are only visible on:
- Home page header (total balance)

But NOT visible in:
- Events page (no indication of point value)
- QR scanner (no confirmation)
- Rewards page (broken)

**Recommendation:** Add points context throughout:
1. Show potential points on event overlay
2. Show earned points after check-in
3. Show per-course breakdown on working Rewards page

---

## Data Flow Issues

### Issue 1: Dual Event Storage
Events exist in two locations:
- `/events/{eventId}` - Top-level collection
- `/clubs/{clubId}/events/{eventId}` - Club subcollection

This causes:
- RSVP writes to club subcollection
- Check-in writes to both locations
- Calendar reads from user's registered events

**Risk:** Data inconsistency if one write fails.

### Issue 2: Partnership Auto-Award Complexity
The auto-award logic in `_checkPartnershipEligibility()`:
- Runs synchronously after check-in batch commit
- Nested loops through all partnerships and all courses
- Silent failure (catches and logs errors)

**Risk:** User checked in but points not awarded, no visibility.

---

## Recommended Fixes Summary

### Immediate (Before Beta)
1. **Uncomment and fix RewardsPage** - Replace mock data with real Firestore queries
2. **Add RSVP cancellation** - Allow users to un-RSVP before event
3. **Add check-in success feedback** - Show points earned on success dialog
4. **Make calendar events tappable** - Navigate to event details

### Short-term (Before Launch)
5. **Add event date/time to video overlay** - Critical info for users
6. **Add loading states** - RSVP button, check-in processing
7. **Add points breakdown** - Per-class view on Home or dedicated page
8. **Add search/filter for events** - Find events by name, date, club

### Post-launch
9. **Add push notifications** - Event reminders
10. **Add onboarding flow** - First-time user tutorial
11. **Add profile page** - View/edit user info
12. **Add offline support** - Cache recent data

---

## Files Audited

| File | Lines | Status |
|------|-------|--------|
| `/lib/login/new_login_page.dart` | 168 | OK |
| `/lib/login/student_login.dart` | 182 | OK |
| `/lib/components/app_shell.dart` | 50 | OK |
| `/lib/pages/home_page.dart` | 368 | Minor issues |
| `/lib/pages/events_page.dart` | 283 | OK |
| `/lib/components/video_overlay.dart` | 256 | Missing date/time |
| `/lib/components/rsvp_button.dart` | 108 | Missing loading state |
| `/lib/pages/rsvp_details.dart` | 326 | Missing cancel |
| `/lib/services/rsvp_service.dart` | 156 | OK |
| `/lib/pages/qr_scanner_page.dart` | 231 | Error handling weak |
| `/lib/services/point_service.dart` | 143 | OK |
| `/lib/services/partnership_service.dart` | 204 | OK |
| `/lib/pages/rewards_page.dart` | 613 | **BROKEN** |
| `/lib/components/calendar_widget.dart` | 390 | Events not tappable |
| `/lib/components/class_enrollment_widget.dart` | 1054 | Complex but functional |
| `/lib/services/auth_service.dart` | 320 | OK |

---

## Next Steps

1. **Frontend Agent:** Fix RewardsPage - uncomment build method and replace mock data
2. **Backend Agent:** Add endpoint/query for student's earned points by course
3. **UI/UX Agent:** Design point-earning celebration animation
4. **QA Agent:** Create test cases for complete student flow
5. **Product Agent:** Prioritize P0 issues in next sprint planning

---

*This audit is read-only. No code changes were made.*
