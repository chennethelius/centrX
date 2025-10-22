# Canvas Class Syncing Implementation - Student

## What Was Implemented

### 1. **CanvasStudentService** (`lib/services/canvas_student_service.dart`)

A service layer that handles all Canvas API interactions for students.

**Key Methods:**

| Method | Purpose |
|--------|---------|
| `testCanvasConnection()` | Verify Canvas URL + API token are valid |
| `fetchStudentCourses()` | Query Canvas API to get all enrolled courses |
| `saveCanvasCredentials()` | Store Canvas URL + token securely (FlutterSecureStorage) |
| `getCanvasCredentials()` | Retrieve stored Canvas credentials |
| `importCoursesToFirestore()` | Save fetched courses to Firestore |
| `refreshCoursesFromCanvas()` | Re-sync all courses from Canvas |
| `removeCanvasClass()` | Remove a course from Firestore (doesn't unenroll from Canvas) |
| `addManualClass()` | Add a course manually if not in Canvas |
| `removeManualClass()` | Remove a manually-added course |

---

### 2. **ClassEnrollmentWidgetCanvas** (`lib/components/class_enrollment_widget_canvas.dart`)

A new UI component that replaces the old manual-only class enrollment.

**Features:**

✅ **Canvas Connection State**
- Shows "Canvas Not Connected" with warning banner
- Button to connect Canvas (asks for URL + API token)
- On success: fetches all courses and displays them

✅ **Canvas Classes Display**
- Lists all synced Canvas courses
- Shows course name + code
- Can remove individual courses from the list
- Badge shows "✅ Canvas Connected (5 classes)"

✅ **Manual Classes Fallback**
- Can still add classes manually if not in Canvas
- Shows separate "Manual" badge
- Can add/remove manually

✅ **Refresh Functionality**
- Button to re-sync all courses from Canvas
- Shows loading dialog during refresh
- Updates course list on success

**User Flows:**

**First Time (Not Connected):**
```
1. Student opens home page
2. Sees: "⚠️ Canvas Not Connected"
3. Clicks "Connect Canvas"
4. Enters Canvas URL: https://slu.instructure.com
5. Enters Canvas API Token: [generated from Canvas settings]
6. System validates connection
7. Fetches all enrolled courses
8. Shows: "✅ Connected! Found 5 courses"
9. Courses appear in list (CS101, ECON101, BIO201, etc)
```

**Already Connected:**
```
1. Student opens home page
2. Sees: "✅ Canvas Connected (5 classes)"
3. Lists all Canvas courses
4. Can:
   - Click ✕ to remove a course
   - Click "Add Manual" to add non-Canvas class
   - Click "Refresh" to re-sync from Canvas
```

---

## Data Storage

### Before (Manual Only)
```json
{
  "uid": "student123",
  "enrolledClasses": [
    {"code": "CS101", "name": "Computer Science 101"},
    {"code": "ECON101", "name": "Economics 101"}
  ]
}
```

### After (Canvas Synced)
```json
{
  "uid": "student123",
  "canvasConnected": true,
  "canvasUrl": "https://slu.instructure.com",
  "canvasLastSynced": "2024-02-05T10:30:00Z",
  
  "canvasClasses": [
    {
      "canvasId": "12345",
      "name": "Computer Science 101",
      "code": "CS101",
      "term": "Fall 2024",
      "enrollmentState": "active",
      "synced": true,
      "syncedAt": "2024-02-05T10:30:00Z"
    },
    {
      "canvasId": "12346",
      "name": "Economics 101",
      "code": "ECON101",
      "term": "Fall 2024",
      "enrollmentState": "active",
      "synced": true,
      "syncedAt": "2024-02-05T10:30:00Z"
    }
  ],
  
  "manualClasses": [
    {
      "id": "1707133980000",
      "code": "IND500",
      "name": "Independent Study",
      "instructor": "Dr. Smith",
      "addedAt": "2024-02-05T10:33:00Z",
      "synced": false
    }
  ]
}
```

---

## Security

✅ **Canvas API Token Storage:**
- Never stored in Firestore (plain text)
- Stored in **FlutterSecureStorage** (encrypted on device)
- Only retrieved for API calls
- Deleted when user signs out

✅ **API Connection:**
- 10-15 second timeout to prevent hanging
- Connection tested before importing courses
- Errors don't expose sensitive data

---

## How to Test

### Setup:
1. Get Canvas API token from `https://slu.instructure.com`
   - Profile → Settings → Approved Integrations
   - Click "+ New Access Token"
   - Copy the token (shown only once)

2. Run the app as a student
3. Open home page
4. Find class enrollment section
5. See "Canvas Not Connected"

### Test Connection:
1. Click "Connect Canvas"
2. Enter: `https://slu.instructure.com`
3. Paste Canvas API token
4. Click OK
5. Should see: "✅ Connected! Found X courses"

### Verify Import:
1. Check Firestore: `users/{studentUid}`
2. Should have:
   - `canvasConnected: true`
   - `canvasClasses: [...]` with all courses
   - `canvasLastSynced: 2024-...`

### Test Manual Add:
1. Click "+ Add Manual"
2. Enter: Code = "IND500", Name = "Independent Study", Instructor = "Dr. Smith"
3. Should appear in "Manual Classes" section

### Test Remove:
1. Click ✕ next to any course
2. Course removed from list
3. Note: Doesn't unenroll from Canvas (only removes from CentrX)

### Test Refresh:
1. Click "Refresh"
2. Waits for new courses to be fetched
3. Updates list
4. Updates `canvasLastSynced`

---

## Dependencies Added

```yaml
flutter_secure_storage: ^9.2.0  # Encrypted credential storage
http: ^1.1.0                    # Canvas API calls
```

---

## What's Next

Once this is tested and working:

1. **Update home_page.dart** to use `ClassEnrollmentWidgetCanvas` instead of old widget
2. **Add Canvas class filtering** to extra credit features (students see EC only for their classes)
3. **Create professor equivalent** (professor can view student enrollments)
4. **Wire up extra credit syncing** (when student checks in, grade updates Canvas grade)

---

## Architecture Diagram

```
ClassEnrollmentWidgetCanvas (UI)
    ↓
  [Connect Canvas] → CanvasStudentService.testCanvasConnection()
    ↓
  [Fetch] → CanvasStudentService.fetchStudentCourses()
    ↓
  [Save] → CanvasStudentService.saveCanvasCredentials()
          → CanvasStudentService.importCoursesToFirestore()
    ↓
  Firestore: canvasClasses array
    ↓
  [Display] ← Read from Firestore
    ↓
  [Refresh] → CanvasStudentService.refreshCoursesFromCanvas()
    ↓
  [Remove] → CanvasStudentService.removeCanvasClass()
    ↓
  [Manual Add] → CanvasStudentService.addManualClass()
```

---

## Git Commit

```
commit 4c646cf
author: GitHub Copilot
date:   Oct 22, 2024

    feat: Add Canvas class syncing for students
```

**Files Changed:**
- `lib/services/canvas_student_service.dart` (NEW - 273 lines)
- `lib/components/class_enrollment_widget_canvas.dart` (NEW - 563 lines)
- `pubspec.yaml` (MODIFIED - added dependencies)
