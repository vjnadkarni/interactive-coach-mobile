# CLAUDE.md - AI Assistant Instructions

## Project: Interactive Coach Mobile - Elenora Health & Wellness Coach

### Overview
This Flutter mobile app provides the Interactive Coach experience on iOS and Android, featuring Elenora - an AI health and wellness coach powered by Claude 4.5 Sonnet. The app connects to the same FastAPI backend as the web application and will integrate with Apple Watch (HealthKit) and Android watches (Health Connect) for health vitals tracking.

---

## 🔴 CRITICAL: Git Workflow - STRICT ENFORCEMENT

### Code Synchronization Between Machines (Mac Mini M4 ↔ MacBook Pro M3)

**NEVER use manual git commands. ALWAYS use the provided scripts.**

#### Leaving Work (Mac Mini M4):
```bash
~/venv/bin/push-wip.sh
```

#### Arriving Home (MacBook Pro M3):
```bash
~/venv/bin/pull-wip.sh
```

#### Leaving Home (MacBook Pro M3):
```bash
~/venv/bin/push-wip.sh
```

#### Arriving at Work (Mac Mini M4):
```bash
~/venv/bin/pull-wip.sh
```

### STRICT RULES (NEVER VIOLATE):
1. ✅ ALL commits MUST use `~/venv/bin/push-wip.sh`
2. ✅ ALL pulls MUST use `~/venv/bin/pull-wip.sh`
3. ❌ NEVER commit manually with `git commit`
4. ❌ NEVER pull manually with `git pull`
5. ⚠️  **Misaligned codebases = DISASTER**

### Why These Scripts?
- Ensure consistent workflow
- Prevent merge conflicts
- Track machine-to-machine transitions
- Maintain clean git history
- Automatic commit message formatting

### Branch Strategy
- **Development**: `wip` branch (ALL ongoing development)
- **Production**: `main` branch (merge only when features work to satisfaction)
- Current branch: `wip`

---

## 🔴 CRITICAL: Elenora's Personality Enforcement

### The Problem
Elenora must maintain her identity as a health & wellness coach across ALL platforms (web and mobile). She is NOT a business coach, NOT a general assistant, NOT Sofia or Anna or any other persona.

### Elenora's Identity (STRICT)
- **Name**: ELENORA (NOT Sofia, NOT Anna, NOT any business coach)
- **Role**: Health & Wellness Coach ONLY
- **Expertise**: Fitness, nutrition, training, sports, health vitals
- **Personality**: Friendly, bubbly, enthusiastic, warm, engaging
- **Communication**: 2-4 sentences, asks questions, encouraging

### Topics Elenora MUST Discuss
✅ Fitness, exercise, training (strength, cardio, HIIT, endurance)
✅ Nutrition, diet, supplements, healthy eating
✅ Sports (all kinds)
✅ Health vitals (heart rate, HRV, SpO2, blood pressure, sleep)
✅ Training plans, progress tracking
✅ Fitness equipment, gyms

### Topics Elenora MUST NEVER Discuss
❌ Business strategy, finance, career advice
❌ Technology, software, coding
❌ General assistant tasks
❌ Productivity tools unrelated to fitness

---

## 🔴 CRITICAL: Environment Variables & Security

**NEVER hardcode API keys in source code. NEVER commit .env files.**

### Single .env File
- **Location**: `interactive-coach-mobile/.env` (top-level)
- **Source**: Copied from `~/venv/interactive-avatar2/.env`
- **Status**: ✅ In .gitignore (never committed to git)

### Environment Variables
```bash
# Backend API Configuration
BACKEND_URL=http://192.168.7.30:8000  # Mac Mini IP for WiFi testing

# HeyGen (future use)
HEYGEN_API_KEY=<secret>

# Anthropic (backend handles this)
ANTHROPIC_API_KEY=<secret>

# Deepgram (future use)
DEEPGRAM_API_KEY=<secret>

# Supabase (backend handles this)
SUPABASE_URL=<url>
SUPABASE_ANON_KEY=<secret>
SUPABASE_SERVICE_KEY=<secret>
```

### Usage in Code

**Dart (Flutter) - CORRECT:**
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/constants.dart';

final apiUrl = AppConstants.backendUrl;
```

**Dart (Flutter) - FORBIDDEN:**
```dart
final apiUrl = "http://192.168.7.30:8000"; // ❌ NEVER DO THIS
```

---

## 🔴 STRICT: LLM Specification

### Claude 4.5 Sonnet ONLY

**Model ID**: `claude-sonnet-4-20250514`

All AI responses come from the FastAPI backend which uses Claude 4.5 Sonnet. The mobile app does NOT make direct calls to Anthropic API - it streams responses from the backend `/chat/stream` endpoint.

---

## 🔴 CRITICAL: iOS Permissions Configuration

### Required Info.plist Entries
**Location**: `ios/Runner/Info.plist`

```xml
<!-- Speech Recognition -->
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app uses speech recognition so you can talk to Elenora, your health and wellness coach.</string>

<!-- Microphone -->
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access so you can speak with Elenora.</string>

<!-- HealthKit (future) -->
<key>NSHealthShareUsageDescription</key>
<string>Interactive Coach needs access to your health data to provide personalized coaching</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Interactive Coach needs to save health data from your workouts</string>
```

### iOS Deployment Target
**Location**: `ios/Podfile`

```ruby
platform :ios, '14.0'  # Required for health package
```

**WHY**: The `health` package v13.2.0 requires iOS 14.0 or later.

---

## 🔴 CRITICAL: Backend Connection

### Development Setup
The mobile app connects to the FastAPI backend running on your Mac.

**IMPORTANT**: The backend must listen on **all interfaces** (0.0.0.0), not just localhost:

```bash
# ❌ WRONG - only accessible from Mac itself
uvicorn main:app --reload

# ✅ CORRECT - accessible from iPhone/Android over WiFi
uvicorn main:app --reload --host 0.0.0.0
```

### Network Configuration
- **Mac Mini IP**: 192.168.7.30 (check with `ifconfig`)
- **Backend URL**: `http://192.168.7.30:8000`
- **Mobile .env**: `BACKEND_URL=http://192.168.7.30:8000`

### Testing Connection
1. Start backend with `--host 0.0.0.0`
2. Ensure iPhone/Android is on same WiFi network as Mac
3. Test from mobile browser: `http://192.168.7.30:8000/docs`
4. If accessible → Mobile app will work

---

## Features

### Current Implementation ✅ WORKING

**Basic Chat Interface** (Tested Oct 9, 2025 on iPhone 12)
- **Text Input**: Type messages to Elenora
- **Speech-to-Text**: Tap microphone, speak, transcript appears
- **Streaming Responses**: Claude responses stream in real-time via SSE
- **Multi-turn Conversations**: Conversation history maintained
- **Elenora Personality**: Correct health & wellness coach identity
- **Network**: Connects to FastAPI backend over WiFi

**UI Elements**:
- Purple/magenta theme matching web app
- App bar: "Elenora - Your Health Coach"
- Chat bubbles: Blue (user), Purple (Elenora), Red (errors)
- Input area: Microphone button, text field, send button
- Auto-scroll to latest message

### Planned Features 🔲

1. **HeyGen Video Avatar** - Visual Elenora (like web app)
2. **HealthKit Integration** - Apple Watch vitals sync
3. **Health Connect Integration** - Android watch vitals sync
4. **User Authentication** - JWT-based login
5. **Health Dashboard** - Visualize vitals and trends
6. **Background Sync** - 15-minute health data updates
7. **Session Time Limits** - Configurable session duration
8. **Offline Mode** - Cached conversations

---

## Technology Stack

### Framework
- **Flutter**: 3.35.3
- **Dart**: 3.9.2
- **Platform**: iOS (iPhone 12, iOS 18.0.1) + Android (future)

### Backend Integration
- **FastAPI**: Shared with web app (localhost:8000 → 0.0.0.0:8000)
- **Streaming**: SSE (Server-Sent Events) via `/chat/stream`
- **Database**: Supabase (shared conversation history)
- **AI**: Claude 4.5 Sonnet via backend

### Key Packages
- **speech_to_text**: ^7.0.0 - iOS native speech recognition
- **http**: ^1.2.1 - HTTP client for API calls
- **flutter_dotenv**: ^5.1.0 - Environment variables
- **health**: ^13.2.0 - HealthKit + Health Connect (future)
- **video_player**: ^2.9.1 - HeyGen avatar (future)

---

## Project Structure

```
interactive-coach-mobile/
├── .env                        # 🔴 Environment variables (NEVER commit)
├── .gitignore                  # Git ignore rules
├── README.md                   # Project overview
├── CLAUDE.md                   # 🔴 This file - AI instructions
├── pubspec.yaml                # Dart dependencies
│
├── lib/                        # Flutter source code
│   ├── main.dart              # App entry point (loads .env, launches AvatarScreen)
│   ├── screens/
│   │   └── avatar_screen.dart # ✅ Chat interface with Elenora
│   ├── services/
│   │   └── api_service.dart   # ✅ FastAPI backend communication (SSE streaming)
│   └── utils/
│       └── constants.dart     # ✅ Environment config (AppConstants)
│
├── ios/                        # iOS-specific configuration
│   ├── Runner/
│   │   └── Info.plist         # ✅ Permissions (speech, microphone)
│   └── Podfile                # ✅ iOS deployment target (14.0)
│
├── android/                    # Android-specific configuration
│
└── assets/                     # Images, fonts, etc.
```

---

## Development Workflow

### Starting Development Session

1. **Pull latest code** (if switching machines):
```bash
~/venv/bin/pull-wip.sh
```

2. **Start backend** (Terminal 1):
```bash
cd /Users/vijay/venv/interactive-coach/backend
source ../venv/bin/activate
python -m uvicorn main:app --reload --host 0.0.0.0
```

3. **Deploy to iPhone 12** (Terminal 2):
```bash
cd /Users/vijay/venv/interactive-coach-mobile
flutter run -d 00008101-001D44303C08801E
```

**Device Info**:
- **Name**: Vijay's iPhone 12
- **Device ID**: 00008101-001D44303C08801E
- **iOS Version**: 18.0.1 (displayed as 26.0.1 in Xcode)
- **Developer Mode**: Enabled

### Ending Development Session

1. **Stop Flutter** (press 'q' in terminal or Ctrl+C)
2. **Stop backend** (Ctrl+C in backend terminal)
3. **Commit changes**:
```bash
~/venv/bin/push-wip.sh
```

---

## Testing Checklist ✅ VERIFIED (Oct 9, 2025)

### Session Start
- [x] App launches without crash
- [x] Permissions prompt for speech recognition appears
- [x] User grants permission → App shows chat interface
- [x] Elenora's greeting message appears: "Hi! I'm Elenora, your health and wellness coach..."

### Speech Recognition
- [x] Tap microphone → Red microphone icon
- [x] Speak → Text appears in input field
- [x] Release → Transcript finalized
- [x] Message sent automatically after finalization

### Text Input
- [x] Type message in text field
- [x] Tap send button → Message appears as blue bubble
- [x] Backend receives message → Elenora responds

### Conversation
- [x] Elenora responds in character (health/fitness topics)
- [x] Streaming responses work (text appears incrementally)
- [x] Purple chat bubble for Elenora
- [x] Multi-turn conversation works (tested 5+ exchanges)
- [x] Conversation history maintained
- [x] Elenora stays on topic (fitness/health only)

### Network
- [x] Backend accessible at 192.168.7.30:8000
- [x] Mobile app connects successfully
- [x] SSE streaming works over WiFi
- [x] Error handling: Shows "Failed to get response" on connection failure

### UI Layout
- [x] Purple/magenta app bar
- [x] Chat area with scrollable messages
- [x] Input area at bottom (mic, text field, send)
- [x] Auto-scroll to latest message

---

## Troubleshooting

### App Shows Blank White Screen
**Cause**: Missing iOS permissions or initialization error
**Solution**:
1. Check Xcode console for error messages
2. Add required permissions to Info.plist
3. Ensure `WidgetsFlutterBinding.ensureInitialized()` in main.dart

### "Failed to get response" Error
**Cause**: Backend not accessible from mobile device
**Solution**:
1. Verify backend running: `http://192.168.7.30:8000/docs` in browser
2. Ensure backend started with `--host 0.0.0.0`
3. Check iPhone and Mac are on same WiFi network
4. Verify .env has correct IP: `BACKEND_URL=http://192.168.7.30:8000`

### Speech Recognition Not Working
**Cause**: Missing permissions or iOS restrictions
**Solution**:
1. Check Info.plist has NSSpeechRecognitionUsageDescription
2. Grant permission when prompted
3. Settings → Privacy → Speech Recognition → Allow app
4. Restart app after granting permission

### Hot Reload Not Updating .env Changes
**Cause**: Environment variables loaded at app startup
**Solution**:
- Use **Hot Restart** (R) not Hot Reload (r)
- Or kill and redeploy: `flutter run -d <device-id>`

### CocoaPods Version Mismatch
**Cause**: Health package requires iOS 14.0+
**Solution**:
```bash
cd ios
pod deintegrate
# Edit Podfile: platform :ios, '14.0'
pod install
cd ..
```

---

## Important Notes

1. **Single Codebase**: One Flutter project for both iOS and Android (feature parity)
2. **Shared Backend**: Same FastAPI backend as web application
3. **Shared Database**: Supabase stores conversation history for both web and mobile
4. **WiFi Testing**: Development uses local network (Mac IP: 192.168.7.30)
5. **Production Deployment**: Will use HTTPS endpoint (future)
6. **Apple Watch**: Will integrate after basic features are complete
7. **Android Testing**: Will use emulator or physical device (future)

---

## Version History

- **v0.1.0** - Basic chat interface working on iPhone 12 (Oct 9, 2025) ✅
  - Text and speech input
  - Streaming Claude responses
  - Multi-turn conversations
  - Elenora personality correct
  - Status: Production-ready for basic chat

---

## Contact

For questions about AI implementation or architecture decisions, refer to this document first. The project aims to create a production-ready health coaching platform with emphasis on realistic human-like interactions and personalized health guidance.
