# Sentiment Journal

A Flutter journaling app that analyzes the mood of each entry with Google Gemini and tracks your emotional trends over time.

## Features
- Email/password authentication (Firebase Auth)
- Write journal entries, stored in Cloud Firestore
- AI sentiment analysis (Positive / Negative / Neutral / Mixed) via the Gemini API
- Entry history and a mood graph over time (fl_chart)
- Local caching of entries

## Tech stack
Flutter · Firebase (Auth, Firestore) · Google Gemini API · Provider-style state management

## Setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install) and run `flutter pub get`.
2. Create your own Firebase project and generate the config (this repo does not include it):
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This creates `lib/firebase_options.dart`, `firebase.json` and `android/app/google-services.json`.
3. Get a Gemini API key from [Google AI Studio](https://aistudio.google.com/) and pass it at run time:
   ```
   flutter run --dart-define=GEMINI_API_KEY=your_key
   ```

## Notes
API keys and Firebase config are intentionally git-ignored. Never commit them.
