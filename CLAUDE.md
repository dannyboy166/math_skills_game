# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter-based educational math skills game designed for children. The app features ring-based puzzle mechanics where users solve mathematical equations by dragging numbers into position. The app includes Firebase authentication (Google Sign-In, Apple Sign-In, email/password), cloud data storage, leaderboards, user statistics tracking, and audio/haptic feedback.

## Development Commands

### Core Flutter Commands
- `flutter run` - Run the app in debug mode
- `flutter run --release` - Run in release mode for performance testing
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build for iOS (requires Xcode)
- `flutter clean` - Clean build cache and generated files
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies

### Code Quality & Analysis
- `flutter analyze` - Static code analysis using rules from analysis_options.yaml
- `flutter test` - Run unit and widget tests
- `flutter doctor` - Check development environment setup

### Platform-Specific Builds
- **Android**: `flutter build apk --release` or `flutter build appbundle`
- **iOS**: `flutter build ios --release` (requires Xcode and developer certificates)
- **Web**: `flutter build web`
- **macOS**: `flutter build macos`

## Architecture Overview

### Core Architecture Pattern
The app follows a service-based architecture with clear separation of concerns:

- **Services Layer**: Business logic and external integrations
  - `AuthService`: Firebase authentication with Google/Apple Sign-In
  - `UserService`/`UserStatsService`: User data management and statistics
  - `LeaderboardService`: Global leaderboards and ranking system
  - `SoundService`/`HapticService`: Audio and tactile feedback
  - `AdminService`: Administrative functions

- **Models**: Data structures representing game entities
  - `RingModel`: Core game mechanics with outer/inner rings
  - `OperationConfig`: Mathematical operation configurations
  - `DifficultyLevel`: Game difficulty settings
  - `LockedEquation`: Equation state management

- **Screens**: UI components organized by feature
  - Authentication flow: `LandingScreen` → `LoginScreen`/`RegisterScreen`
  - Main app: `HomeScreen` → `LevelsScreen` → `GameScreen`
  - Additional: `LeaderboardScreen`, `ProfileScreen`, `SettingsScreen`

### Game Mechanics
The core game revolves around two concentric rings containing numbers. Players drag numbers between rings to form mathematical equations. The `RingModel` manages ring state, while `GameScreen` handles game logic, scoring, and progression.

### Firebase Integration
- **Authentication**: Multi-provider auth (email, Google, Apple) via `AuthService`
- **Firestore**: User data, statistics, and leaderboards stored in cloud
- **Configuration**: 
  - Android: `android/app/google-services.json`
  - iOS: `ios/GoogleService-Info.plist`

### State Management
The app uses Flutter's built-in state management with StatefulWidget for local state and SharedPreferences for simple persistence. Service classes handle complex state logic.

## Key Implementation Details

### Audio System
The `SoundService` manages game audio with preloaded sound effects stored in `assets/sounds/`. Sounds are categorized by game events (correct/incorrect answers, star achievements).

### Haptic Feedback
`HapticService` provides tactile feedback for user interactions, enhancing the mobile game experience.

### Tutorial System
`TutorialHelper` and `TutorialOverlay` provide guided introductions to game mechanics, with progress tracking via SharedPreferences.

### Animation Framework
Custom animations in `lib/animations/` handle celebrations, star effects, and visual feedback. The app uses `flutter_animate` for enhanced animation capabilities.

## Firebase Setup Requirements

When setting up Firebase:
1. Ensure `google-services.json` is present in `android/app/`
2. Ensure `GoogleService-Info.plist` is present in `ios/`
3. Firebase project must have Authentication and Firestore enabled
4. Configure OAuth providers (Google, Apple) in Firebase Console

## Development Environment Notes

- **Flutter SDK**: 3.27.1+ (check with `flutter doctor`)
- **Dart SDK**: ^3.6.0
- **Platform Support**: iOS, Android, Web, macOS, Linux, Windows
- **Firebase**: Core, Auth, Firestore services required
- **Audio Assets**: MP3 files in `assets/sounds/` for game feedback
- **Platform Dependencies**: 
  - iOS development requires Xcode and valid certificates
  - Android development requires Android Studio and SDK setup

## Testing Strategy

- Unit tests for game logic and utility functions
- Widget tests for UI components
- Integration tests for Firebase authentication flow
- Audio and haptic feedback should be tested on physical devices