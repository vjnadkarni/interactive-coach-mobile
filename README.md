# Interactive Coach Mobile

Flutter mobile application for Interactive Coach - Elenora Health & Wellness Coach with Apple Watch and Android Watch integration.

## Overview

This is the mobile companion app for the Interactive Coach web platform, providing:
- Full Elenora coaching experience on iOS and Android
- Apple Watch integration (HealthKit)
- Android Watch integration (Health Connect)
- Real-time health vitals sync to backend
- Feature parity with web application

## Features

### Core Features ✅ WORKING
- ✅ **Text chat with Elenora** - Claude 4.5 Sonnet AI coaching
- ✅ **Speech-to-text** - iOS native speech recognition
- ✅ **Real-time conversation streaming** - SSE from FastAPI backend
- ✅ **Multi-turn conversations** - Conversation history maintained
- ✅ **Elenora personality** - Health & wellness coach (NOT business coach)
- 🔲 HeyGen streaming avatar (planned)
- 🔲 Session time limits (planned)
- 🔲 User authentication with JWT (planned)

### Health Data Integration 🔲 PLANNED
- 🔲 Apple Watch (HealthKit)
  - Heart rate (resting, active, max)
  - HRV (Heart Rate Variability)
  - SpO2 (blood oxygen)
  - Blood pressure
  - Sleep quality
  - Steps and active minutes
  - Workout data
- 🔲 Android Watch (Health Connect)
  - Same metrics as iOS
- 🔲 Background sync (every 15 minutes)
- 🔲 Health dashboard UI

### Mobile-Specific Features 🔲 PLANNED
- Push notifications
- Offline mode (cached conversations)
- Biometric authentication (Face ID, Touch ID, Fingerprint)
- Camera integration (progress photos)

## Tech Stack

- **Framework**: Flutter 3.35.3
- **Language**: Dart 3.9.2
- **State Management**: Provider
- **Backend**: FastAPI (shared with web app)
- **Database**: Supabase (shared with web app)
- **Health**: `health` package v13.2.0
- **Video**: `video_player` package
- **HTTP**: `http` package
- **WebSocket**: `web_socket_channel` package
- **Speech**: `speech_to_text` package

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   ├── health_vitals.dart
│   └── conversation.dart
├── screens/                  # UI screens
│   ├── login_screen.dart
│   ├── avatar_screen.dart
│   ├── profile_screen.dart
│   └── health_dashboard.dart
├── services/                 # Business logic
│   ├── api_service.dart      # FastAPI backend
│   ├── health_service.dart   # HealthKit/Health Connect
│   ├── auth_service.dart     # JWT authentication
│   └── speech_service.dart   # Deepgram STT
├── widgets/                  # Reusable UI components
│   ├── avatar_player.dart
│   └── voice_input_button.dart
└── utils/                    # Helper functions
    └── constants.dart

ios/                          # iOS-specific configuration
android/                      # Android-specific configuration
assets/                       # Images, fonts, etc.
```

## Prerequisites

### Development Environment
1. **Flutter SDK**: 3.35.3 or later
   ```bash
   flutter doctor
   ```

2. **Xcode** (for iOS development)
   - Xcode 15.0 or later
   - Command Line Tools installed
   - iOS Simulator

3. **Android Studio** (for Android development)
   - Android SDK 21 or later
   - Android Emulator

### Backend Setup
The mobile app requires the Interactive Coach FastAPI backend to be running:
- Local development: `http://localhost:8000`
- Production: `https://coach.galenogen.com/api`

See the main `interactive-coach` repository for backend setup instructions.

## Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/vjnadkarni/interactive-coach-mobile.git
cd interactive-coach-mobile
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Environment Variables
```bash
cp .env.example .env
```

Edit `.env` with your actual API keys:
```bash
BACKEND_URL=http://localhost:8000
HEYGEN_API_KEY=your_heygen_api_key
DEEPGRAM_API_KEY=your_deepgram_api_key
```

### 4. iOS Configuration

#### 4a. Install CocoaPods dependencies
```bash
cd ios
pod install
cd ..
```

#### 4b. Configure HealthKit permissions
Edit `ios/Runner/Info.plist` and add:
```xml
<key>NSHealthShareUsageDescription</key>
<string>Interactive Coach needs access to your health data to provide personalized coaching</string>
<key>NSHealthUpdateUsageDescription</key>
<string>Interactive Coach needs to save health data from your workouts</string>
```

#### 4c. Enable HealthKit capability
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Signing & Capabilities
3. Click "+ Capability" → HealthKit
4. Enable "Clinical Health Records" (optional)

### 5. Android Configuration

#### 5a. Configure Health Connect permissions
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest>
    <!-- Health Connect permissions -->
    <uses-permission android:name="android.permission.health.READ_HEART_RATE"/>
    <uses-permission android:name="android.permission.health.READ_BLOOD_OXYGEN"/>
    <uses-permission android:name="android.permission.health.READ_STEPS"/>
    <uses-permission android:name="android.permission.health.READ_SLEEP"/>
    <!-- Add other health permissions as needed -->

    <application>
        <!-- Health Connect configuration -->
        <activity
            android:name="com.google.android.apps.healthconnect.permissioncontroller.PermissionActivity"
            android:exported="true"/>
    </application>
</manifest>
```

#### 5b. Update minimum SDK version
Edit `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 26  // Health Connect requires API 26+
    }
}
```

### 6. Run the App

#### iOS
```bash
flutter run -d ios
```

or open Xcode and run from there:
```bash
open ios/Runner.xcworkspace
```

#### Android
```bash
flutter run -d android
```

or open Android Studio:
```bash
open -a "Android Studio" android/
```

## Development Workflow

### Branch Strategy
- **main**: Stable releases only
- **wip**: All ongoing development (use this branch)

```bash
git checkout wip
# Make changes
git add .
git commit -m "Description of changes"
git push origin wip
```

### Testing

#### Run Tests
```bash
flutter test
```

#### Run on Device
iOS:
```bash
flutter devices  # Find device ID
flutter run -d <device-id>
```

Android:
```bash
flutter devices  # Find device ID
flutter run -d <device-id>
```

### Building

#### iOS (requires Mac + Xcode)
```bash
flutter build ios --release
```

#### Android
```bash
flutter build apk --release  # APK
flutter build appbundle      # AAB for Play Store
```

## Health Data Integration

### Supported Metrics

**iOS (HealthKit)**:
- Heart Rate (resting, active, max)
- HRV (Heart Rate Variability)
- SpO2 (blood oxygen)
- Blood Pressure
- Sleep Analysis
- Steps
- Active Energy
- Workouts

**Android (Health Connect)**:
- Heart Rate
- Blood Oxygen
- Blood Pressure
- Sleep Sessions
- Steps
- Active Calories
- Exercise Sessions

### Data Sync Flow

```
Apple Watch/Android Watch
    ↓ (native sync)
iPhone/Android Phone (HealthKit/Health Connect)
    ↓ (Flutter health package)
Mobile App
    ↓ (HTTP POST every 15 min)
FastAPI Backend (/health/vitals)
    ↓ (Supabase database)
Web App (can view same data)
```

### Background Sync

The app syncs health data every 15 minutes using:
- iOS: Background Tasks framework
- Android: WorkManager

## API Integration

### FastAPI Backend Endpoints

**Authentication**:
- `POST /auth/register` - Create account
- `POST /auth/login` - Login
- `POST /auth/logout` - Logout
- `POST /auth/refresh` - Refresh JWT token

**Chat**:
- `POST /chat/stream` - Streaming conversation with Elenora
- `GET /conversation/check/{user_id}` - Check existing conversation
- `POST /conversation/clear/{user_id}` - Clear conversation

**Health Data**:
- `POST /health/vitals` - Sync health vitals
- `GET /health/vitals/{user_id}/latest` - Get latest vitals
- `GET /health/vitals/{user_id}/summary` - Get summary for AI context

## Troubleshooting

### iOS Issues

**Problem**: HealthKit not authorized
**Solution**:
1. Check Info.plist has NSHealthShareUsageDescription
2. Verify HealthKit capability is enabled in Xcode
3. Reset simulator: Device → Erase All Content and Settings

**Problem**: CocoaPods issues
**Solution**:
```bash
cd ios
pod deintegrate
pod install
cd ..
```

### Android Issues

**Problem**: Health Connect not found
**Solution**: Install Health Connect app from Play Store (beta)

**Problem**: Gradle build fails
**Solution**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### General Issues

**Problem**: Package version conflicts
**Solution**:
```bash
flutter clean
flutter pub get
```

**Problem**: Hot reload not working
**Solution**: Restart the app completely (not hot restart)

## Dependencies

See `pubspec.yaml` for complete list. Key dependencies:

- `health: ^13.2.0` - HealthKit + Health Connect
- `http: ^1.2.1` - HTTP client
- `flutter_secure_storage: ^9.2.2` - Secure storage for tokens
- `provider: ^6.1.2` - State management
- `video_player: ^2.9.1` - Video playback for avatar
- `web_socket_channel: ^3.0.1` - WebSocket for streaming
- `speech_to_text: ^7.0.0` - Speech recognition
- `permission_handler: ^11.3.1` - Permissions

## Resources

- **Flutter Docs**: https://flutter.dev/docs
- **Health Package**: https://pub.dev/packages/health
- **HealthKit Docs**: https://developer.apple.com/documentation/healthkit
- **Health Connect Docs**: https://developer.android.com/health-and-fitness/guides/health-connect

## Contributing

This is a private project. All development happens on the `wip` branch. Only merge to `main` when features are complete and tested.

## License

Private - All Rights Reserved

## Contact

For questions or issues, contact: vijay@galenogen.com
