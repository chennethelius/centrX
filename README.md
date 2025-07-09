# Centrx

**Flutter** mobile social media app for university extracurricular engagement.

---

## Description

Centrx connects students, clubs, and campus organizations in one platform:

* **Event feeds** with images, descriptions, and RSVP buttons
* **Club pages** with real-time chat and direct messaging
* **Leaderboards** rewarding the most active participants
* **Role-based access** for students, club officers, and administrators

---

## Interesting Techniques

* **Firestore real-time snapshots** for live, reactive feeds ([docs](https://firebase.google.com/docs/firestore/query-data/listen))
* **Custom slivers** for smooth scrolling lists ([SliverList](https://api.flutter.dev/flutter/widgets/SliverList-class.html))
* **Google Sign-In (OAuth2)** via the `google_sign_in` plugin ([pub.dev](https://pub.dev/packages/google_sign_in))
* **Push notifications** using `firebase_messaging` and local notifications
* **Offline persistence** with Firestore caching ([docs](https://firebase.google.com/docs/firestore/manage-data/enable-offline))

---

## Key Libraries & Tools

* **Flutter SDK** ([flutter.dev](https://flutter.dev))
* **firebase\_core**, **firebase\_auth**, **cloud\_firestore**, **firebase\_messaging** ([pub.dev](https://pub.dev))
* **Riverpod** for state management ([riverpod.dev](https://riverpod.dev))
* **cached\_network\_image** for image caching and placeholders
* **qr\_flutter** for QR code generation and scanning
* **google\_fonts** for custom typography ([Google Fonts](https://fonts.google.com))

---

## Project Structure

```
lib/
├── main.dart           # Entry point with authentication guard
├── core/               # Constants, theme, utilities
├── services/           # Firebase and data integration logic
├── models/             # Data classes and serializers
├── providers/          # Riverpod state providers
├── pages/
│   ├── auth/           # Login and registration screens
│   └── app/            # Home, feed, leaderboard, club pages
└── components/         # Shared widgets, including AppShell and nav bar
assets/
├── images/             # Static images and placeholders
└── fonts/              # Custom font files
```

* The **`components/`** directory contains `AppShell` (`app_shell.dart`) for bottom-bar navigation and page management.
* The **auth flow** resides in `pages/auth/` without the navigation bar until login.
* The **main app UI** uses `AppShell` for in-app navigation after authentication.

---

*First release of Centrx. Feedback and contributions are welcome!*
