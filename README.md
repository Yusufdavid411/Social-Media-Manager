# Social Media Manager

Android-first Flutter app for managing real social posts, drafts, schedules,
connected accounts, and analytics.

## Current Scope

- Flutter Android app using package `com.social_media_manager`
- Firebase-ready authentication flow
- Firestore-ready user and post data model
- Mobile-first Home, Compose, Calendar, Analytics, and Settings screens
- Facebook and Instagram prioritized across the UI
- No fake dashboard posts or hardcoded metrics
- Cloudinary and Meta integration placeholders for the next build phase

## Requirements

- Flutter SDK
- Android Studio or Android SDK
- Firebase project config for Android

## Getting Started

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d <android-device-id>
```

## Firebase Setup

Add the Android Firebase config file to:

```text
android/app/google-services.json
```

The target Firebase project from the handoff is:

- Project ID: `social-media-manager-e07a6`
- Android package: `com.social_media_manager`

## Next Build Phase

- Wire FlutterFire Android config
- Enable real Firebase Auth and Firestore writes on device
- Add Cloudinary signed upload through Firebase Cloud Functions
- Add Meta OAuth connection flow
- Implement Facebook Page publishing
- Implement Instagram Business publishing
- Add scheduled publishing worker
