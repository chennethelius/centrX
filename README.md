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

*First release of Centrx. Feedback and contributions are welcome!*
