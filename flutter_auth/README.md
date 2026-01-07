# CentrX Flutter Application

This directory contains the main Flutter application code for CentrX.

## Quick Start

```bash
# Install dependencies
flutter pub get

# Run on your preferred platform
flutter run
```

## Requirements

- Flutter SDK 3.0+
- Dart 2.17+
- Firebase configuration files (contact project owner)

## Development

### Running Tests
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

### Format Code
```bash
dart format .
```

## Project Documentation

For comprehensive documentation including architecture, features, and setup instructions, see the [main README](../README.md) in the root directory.

## Firebase Configuration

This project requires Firebase configuration files that are **not included** in version control for security:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`

Contact the project owner to obtain these files.

## Learn More

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
- [Riverpod Documentation](https://riverpod.dev/)
