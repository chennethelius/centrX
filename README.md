# CentrX 🎓

> A modern Flutter-based social platform connecting students with campus events, clubs, and extracurricular activities.

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.0+-blue.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-Latest-orange.svg" alt="Firebase">
  <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-green.svg" alt="Platform">
</p>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [Architecture](#-architecture)
- [Security](#-security)
- [Contributing](#-contributing)

---

## 🎯 Overview

**CentrX** is a comprehensive social engagement platform designed for university communities. It bridges the gap between students and campus organizations by providing a centralized hub for event discovery, club management, and real-time communication.

### Why CentrX?

- **For Students**: Discover events, connect with clubs, and earn rewards for participation
- **For Club Officers**: Manage events, track RSVPs, and communicate with members
- **For Administrators**: Oversee campus activities and monitor engagement metrics

---

## ✨ Features

### 🎉 Event Management
- **Live Event Feed**: Real-time updates on campus events with rich media support
- **Smart RSVP System**: One-click event registration with QR code check-in
- **Calendar Integration**: Sync events with your device calendar
- **Event Details**: Comprehensive information including location, time, and club details

### 👥 Social Engagement
- **Club Pages**: Dedicated spaces for clubs with member directories and activity feeds
- **Interactive Buttons**: Like, comment, and share events within the community
- **Direct Messaging**: Connect with club officers and fellow students
- **Push Notifications**: Stay updated on event reminders and club announcements

### 🏆 Gamification
- **Rewards System**: Earn points for attending events and participating in activities
- **Leaderboards**: Track your engagement compared to peers
- **Achievement Badges**: Unlock milestones as you explore campus life

### 🔐 Authentication & Roles
- **Google Sign-In**: Seamless OAuth2 authentication
- **Role-Based Access**: Different permissions for students, club admins, and teachers
- **Secure Sessions**: Firebase Authentication with automatic token refresh

---

## 🛠 Tech Stack

### Frontend Framework
- **[Flutter](https://flutter.dev)** - Cross-platform UI toolkit for iOS, Android, and Web
- **Dart** - Programming language optimized for UI development

### Backend & Database
- **[Firebase](https://firebase.google.com)**
  - **Authentication** - Secure user management with Google Sign-In
  - **Cloud Firestore** - NoSQL database with real-time synchronization
  - **Firebase Messaging** - Cross-platform push notifications
  - **Cloud Storage** - Media file hosting and delivery

### State Management & Architecture
- **[Riverpod](https://riverpod.dev)** - Reactive state management with compile-time safety
- **Service Layer Pattern** - Separation of business logic from UI components

### Key Libraries
| Library | Purpose |
|---------|---------|
| `firebase_core` | Firebase SDK initialization |
| `firebase_auth` | User authentication |
| `cloud_firestore` | Real-time database access |
| `firebase_messaging` | Push notifications |
| `google_sign_in` | Google OAuth integration |
| `cached_network_image` | Optimized image loading |
| `qr_flutter` | QR code generation/scanning |
| `google_fonts` | Custom typography |
| `intl` | Internationalization & date formatting |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: Version 3.0 or higher
- **Dart**: Version 2.17 or higher
- **Firebase Account**: With a configured project
- **IDE**: VS Code or Android Studio recommended

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/chennethelius/centrX.git
   cd centrX/flutter_auth
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase** (Contact project owner for credentials)
   - Firebase configuration files are not included in the repository for security
   - You'll need:
     - `lib/firebase_options.dart`
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`
     - `macos/Runner/GoogleService-Info.plist`

4. **Run the app**
   ```bash
   # iOS
   flutter run -d ios
   
   # Android
   flutter run -d android
   
   # Web
   flutter run -d chrome
   ```

### Configuration

Create a `.env` file based on `.env.example`:
```bash
cp .env.example .env
# Edit .env with your configuration values
```

---

## 📁 Project Structure

```
flutter_auth/
├── lib/
│   ├── components/          # Reusable UI components
│   │   ├── app_shell.dart
│   │   ├── bottom_nav_bar.dart
│   │   ├── event_card.dart
│   │   ├── like_button.dart
│   │   └── ...
│   ├── login/              # Authentication screens
│   │   ├── new_login_page.dart
│   │   ├── club_admin_login.dart
│   │   └── student_teacher_login.dart
│   ├── models/             # Data models
│   │   └── event.dart
│   ├── pages/              # Main application screens
│   │   ├── home_page.dart
│   │   ├── events_page.dart
│   │   ├── club_page.dart
│   │   ├── rewards_page.dart
│   │   └── ...
│   ├── services/           # Business logic & API calls
│   │   ├── auth_service.dart
│   │   ├── database_service.dart
│   │   ├── event_service.dart
│   │   └── ...
│   ├── theme/              # App theming & styling
│   ├── firebase_options.dart
│   └── main.dart           # App entry point
├── android/                # Android-specific code
├── ios/                    # iOS-specific code
├── web/                    # Web-specific code
└── test/                   # Unit & widget tests
```

---

## 🏗 Architecture

### Design Patterns

**Service Layer Pattern**
- Business logic separated from UI components
- Services handle Firebase operations and data transformations
- Examples: `AuthService`, `EventService`, `DatabaseService`

**Repository Pattern**
- Abstract data sources behind repositories
- Easier testing and data source swapping

**Provider Pattern (via Riverpod)**
- Reactive state management
- Dependency injection
- Widget rebuild optimization

### Data Flow

```
UI Components → Riverpod Providers → Services → Firebase
     ↑                                              ↓
     └──────────── Real-time Updates ──────────────┘
```

### Key Technical Implementations

- **Real-time Snapshots**: Firestore streams for live data updates
- **Custom Slivers**: Optimized scrolling with `SliverList` and `SliverGrid`
- **Offline-First**: Firestore cache enables offline functionality
- **Lazy Loading**: Pagination for event feeds and user lists
- **Image Optimization**: `cached_network_image` with placeholder and error handling

---

## 🔒 Security

### Best Practices Implemented

✅ **API Keys**: Firebase configuration files excluded from version control  
✅ **Authentication**: Google OAuth with Firebase Authentication  
✅ **Authorization**: Role-based access control via Firestore security rules  
✅ **Data Validation**: Input sanitization on client and server side  
✅ **HTTPS**: All API calls encrypted in transit  

### Important Notes

- **Never commit** Firebase configuration files to public repositories
- API keys are restricted by bundle ID / package name in Google Cloud Console
- Firestore security rules enforce server-side authorization
- User tokens automatically refresh via Firebase SDK

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` before committing
- Format code with `dart format .`
- Write tests for new features

---

## 📄 License

This project is part of an academic initiative. Please contact the project owner for licensing information.

---

## 📞 Contact

**Project Maintainer**: Max Chen  
**Repository**: [github.com/chennethelius/centrX](https://github.com/chennethelius/centrX)

For Firebase configuration access or questions, please contact the project owner.

---

<p align="center">Made with ❤️ for university communities</p>
