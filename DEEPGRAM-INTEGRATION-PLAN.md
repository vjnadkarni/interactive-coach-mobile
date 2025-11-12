# Deepgram STT Integration Plan for Flutter Mobile App

## Current Status
- ✅ Chat responses working (fixed 'token' field issue)
- ❌ Punctuation missing (using iOS native speech recognition)
- 🎯 **Solution**: Replace `speech_to_text` with Deepgram WebSocket API

---

## Why Deepgram?

**Advantages**:
- ✅ Automatic punctuation
- ✅ Automatic capitalization
- ✅ Smart formatting (numbers, dates, etc.)
- ✅ Real-time streaming transcription
- ✅ Same quality as web app
- ✅ Cross-platform (works on iOS and Android)

**Current iOS native STT limitations**:
- ❌ No automatic punctuation
- ❌ No automatic capitalization
- ❌ Platform-specific behavior

---

## Implementation Steps

### **Step 1: Add Required Dependencies**

Edit `pubspec.yaml`, add under `dependencies`:

```yaml
  # Audio recording for Deepgram streaming
  record: ^5.1.0

  # Already have web_socket_channel: ^3.0.1 ✅
```

Then run:
```bash
cd /Users/vijay/venv/interactive-coach-mobile
flutter pub get
```

---

### **Step 2: Create Deepgram Service**

**File**: `lib/services/deepgram_stt_service.dart`

**Features**:
- WebSocket connection to Deepgram API
- Real-time audio streaming (PCM 16kHz)
- Interim and final transcripts
- Automatic reconnection on errors
- Clean resource management

**Key Configuration**:
```
wss://api.deepgram.com/v1/listen?
  model=nova-2&
  language=en-US&
  smart_format=true&
  punctuate=true&
  interim_results=true&
  endpointing=300
```

---

### **Step 3: Update ChatScreen**

**File**: `lib/screens/chat_screen.dart`

**Changes**:
1. Replace `speech_to_text` import with `deepgram_stt_service`
2. Replace `_speech` instance with `_deepgramService`
3. Update `_startListening()` to use Deepgram stream
4. Remove manual `_addPunctuation()` function (Deepgram does this automatically)

**Before**:
```dart
import 'package:speech_to_text/speech_to_text.dart' as stt;
final stt.SpeechToText _speech = stt.SpeechToText();
```

**After**:
```dart
import '../services/deepgram_stt_service.dart';
final DeepgramSTTService _deepgramService = DeepgramSTTService();
```

---

### **Step 4: Update iOS Permissions**

**File**: `ios/Runner/Info.plist`

Ensure microphone permission is configured:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for voice chat with Hera</string>
```

---

### **Step 5: Test on iPhone 12**

1. Kill all Flutter processes
2. Run `flutter run`
3. Navigate to Chat screen
4. Press microphone button
5. Say: "hello hera how are you today"
6. Expected result: "Hello Hera, how are you today?" (with punctuation!)

---

## API Usage & Costs

**Deepgram Pricing**:
- Nova-2 model: ~$0.0043 per minute
- Free tier: $200 credit (enough for testing)
- Production: Pay-as-you-go

**API Key**:
- Already configured in `.env`: `DEEPGRAM_API_KEY`
- Loaded via `AppConstants.deepgramApiKey`

---

## Implementation Files Needed

1. ✅ `lib/services/deepgram_stt_service.dart` (created, needs revision)
2. ⏳ Update `lib/screens/chat_screen.dart` (replace speech_to_text)
3. ⏳ Update `pubspec.yaml` (add `record` package)
4. ⏳ Test on iPhone 12

---

## Alternative: Simplified Approach

If full WebSocket implementation is too complex, consider:

**Option**: Use Deepgram's REST API (not real-time)
- Record audio file
- Upload to Deepgram
- Get punctuated transcript back
- **Pro**: Simpler implementation
- **Con**: Not real-time (slight delay)

---

## Next Actions

**Immediate**:
1. Kill all zombie Flutter/Dart processes
2. Add `record: ^5.1.0` to `pubspec.yaml`
3. Run `flutter pub get`
4. Implement Deepgram service (WebSocket or REST)
5. Test punctuation quality

**Questions to Answer**:
- Do you want real-time streaming (WebSocket) or batch processing (REST)?
- Should I implement this now, or document for later?

---

## Current Blockers

- 🔴 Many zombie Flutter/Dart processes running in background
- 🟡 Need to add `record` package dependency
- 🟢 Deepgram API key already configured

**Recommendation**: Clean restart with fresh Flutter session to implement properly.
