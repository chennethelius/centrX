
# Centrx Mobile App - Product Requirements Document (PRD)

## 1. Introduction / Overview
Centrx is a mobile application designed to connect students, clubs, teachers, and administrators in a unified platform for event management, communication, and engagement. It facilitates event discovery, media sharing, RSVP tracking, and role-based access, aiming to improve community participation in academic and extracurricular activities.

The platform supports both Android and iOS devices, built using Flutter with Firebase (Firestore, Authentication, and Storage) as the backend infrastructure.

---

## 2. Goals / Objectives
**Primary Objective:** Build a scalable, secure, and user-friendly mobile app that enables role-based access and efficient event interaction between students, clubs, teachers, and admins.

**SMART Goals:**
1. **Specific:** Enable students to discover and RSVP for events, clubs to post events with media, and teachers/admins to manage event approvals and student engagement.
2. **Measurable:** Achieve 2,000 monthly active users (MAU) within the first year of launch.
3. **Achievable:** Leverage Firebase backend for authentication, role management, and event storage with proven scalable architecture.
4. **Relevant:** Address the gap in streamlined event communication and participation in school communities.
5. **Time-bound:** Launch MVP within 6 months, with incremental feature rollouts every 2 months thereafter.

---

## 3. Target Audience / User Personas
- **Students:** Discover events, RSVP, earn points for participation, and view event media.
- **Club Representatives:** Post and manage club events, upload images/videos, track RSVPs.
- **Teachers:** Approve student participation for extra credit, view attendance lists.
- **Admins:** Oversee entire platform, manage user roles, remove inappropriate content.

---

## 4. User Stories / Use Cases
1. As a **student**, I want to view a feed of upcoming events so I can decide which to attend.
2. As a **student**, I want to RSVP to an event so I can secure my spot and earn points.
3. As a **club**, I want to create and post an event with images/videos so students are informed.
4. As a **teacher**, I want to approve points for students’ event participation for extra credit.
5. As an **admin**, I want to manage all content and users to ensure compliance with rules.

---

## 5. Functional Requirements
- **Authentication:**
  - Google Sign-In for students and teachers.
  - Email/Password login for club accounts.
  - Role-based user access stored in Firestore (`role` field).
- **Event Management:**
  - Create, edit, and delete events.
  - Upload and store event media in Firebase Storage.
  - RSVP tracking with attendance lists.
- **Media Feed:**
  - Scrollable feed of event images/videos.
  - Caching for performance optimization.
- **Role Management:**
  - Separate Firestore collections for `users` and `clubs`.
  - Admin UI for assigning/updating roles.
- **Notifications:**
  - Push notifications for upcoming events or changes.

---

## 6. Non-Functional Requirements
- **Performance:** App must load event feed within 2 seconds over 4G.
- **Scalability:** Support 2,000+ MAU with minimal Firestore reads/writes per user session.
- **Security:** Firebase rules to restrict data access by role; no direct access to sensitive fields.
- **Usability:** Intuitive UI for role-specific flows; maintain consistent app theme and branding.
- **Compatibility:** Android 8+ and iOS 14+.

---

## 7. Design Considerations / Mockups
- Use a central theme file for colors, fonts, and styles to ensure consistency.
- Responsive UI for various screen sizes (phones, tablets).
- Mockups for key screens (login, event feed, event details, post event form) to be created in Figma.

---

## 8. Success Metrics
- 2,000 MAU within first year.
- Average session length > 3 minutes.
- RSVP rate of > 30% for posted events.
- Less than 1% crash rate across devices.

---

## 9. Open Questions / Future Considerations
- Should events expire automatically after their date passes?
- Implement video compression before upload to save storage?
- Integration with school calendar systems?
- Potential for monetization via sponsored events?
