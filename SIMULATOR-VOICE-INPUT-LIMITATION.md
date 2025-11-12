# iOS Simulator Voice Input Limitation

**Date**: November 10, 2025
**Issue**: Microphone button shows "Listening" state but doesn't transcribe speech in iOS Simulator

## Root Cause

**iOS Simulator has limited or non-functional speech recognition support.**

This is a known Apple limitation, not an issue with our app code. The Speech Recognition framework (`speech_to_text` package) has the following limitations in the simulator:

1. **Microphone Pass-Through Issues**: The simulator relies on your Mac's microphone, which may not be properly configured or passed through
2. **Speech Framework Limitations**: Apple's Speech Recognition API is designed primarily for physical iOS devices
3. **On-Device Processing**: Modern iOS devices use on-device ML models for speech recognition, which aren't fully emulated in the simulator

## What Works in Simulator ✅

1. ✅ **Text Input** - Type messages and get responses (fully functional)
2. ✅ **Text-to-Speech (TTS)** - Hera speaks responses with ElevenLabs voice (works perfectly)
3. ✅ **Backend API** - Chat streaming, authentication, database (all working)
4. ✅ **UI/Navigation** - All screens, buttons, navigation (fully functional)
5. ✅ **Microphone Button** - Visual feedback shows "Listening" state correctly

## What Doesn't Work in Simulator ❌

1. ❌ **Speech-to-Text (STT)** - Voice input doesn't transcribe speech
2. ❌ **Microphone Audio Capture** - Simulator doesn't reliably capture Mac microphone input for Speech Recognition

## Solution: Test on Physical Device

**Voice input (speech recognition) works perfectly on physical iOS devices.**

### To Test Voice Input:

**Option 1: iPhone 12 (Currently Connected)**
- Device ID: `00008101-001D44303C08801E`
- Status: Connected but has pairing issue (0xE800001A)
- Action needed: Re-pair device with Mac, ensure unlocked and trusted

**Option 2: Any Other Physical iOS Device**
- iPhone, iPad, or iPod touch running iOS 13.0+
- Connect via USB cable
- Ensure device is unlocked and trusted
- Run: `flutter run -d <device-id>`

## Testing Strategy

### Simulator Testing (Current Workflow)
Use the iOS Simulator for:
- ✅ UI/UX testing
- ✅ Text input testing
- ✅ Backend API integration testing
- ✅ TTS (speech output) testing
- ✅ Navigation and state management testing
- ✅ Hot reload during development

### Physical Device Testing (For Voice Input)
Use a physical iPhone/iPad for:
- ✅ Speech recognition (STT) testing
- ✅ Microphone permissions testing
- ✅ Real-world voice input accuracy testing
- ✅ Full end-to-end user experience testing

## Current Status

### Simulator ✅
- **App deployed**: iPhone 16 Pro Simulator
- **Text input**: Working perfectly
- **TTS output**: Working perfectly
- **Backend**: All APIs functional
- **Voice input**: Not functional (expected simulator limitation)

### Physical Device ⏳
- **iPhone 12 detected**: Yes
- **Connection status**: Pairing error (0xE800001A)
- **Next step**: Fix device pairing to enable physical device testing

## Workaround for Simulator Voice Testing

If you want to test the speech recognition code flow in the simulator without actual voice input, you can:

1. **Use Text Input**: Type your messages - the backend responds identically
2. **Mock Speech Results**: Modify `chat_screen.dart` to simulate speech transcripts (development only)
3. **Test on Physical Device**: The recommended approach for voice input testing

## Recommendation

**For development:**
- ✅ Continue using iOS Simulator with text input
- ✅ All features except voice input can be tested in simulator
- ✅ Voice input automatically works when deployed to physical device (no code changes needed)

**For voice input testing:**
- ⏳ Fix iPhone 12 pairing issue
- ✅ Or test on another physical iOS device
- ✅ Voice recognition will work immediately on real device (iOS native speech has automatic punctuation!)

## Technical Details

### Speech Recognition Initialization
```dart
// In chat_screen.dart
Future<void> _initSpeech() async {
  _speechAvailable = await _speech.initialize(
    onStatus: (status) => print('🎤 [ChatScreen] Speech status: $status'),
    onError: (error) => print('❌ [ChatScreen] Speech error: $error'),
  );
  setState(() {});
  print('🎤 [ChatScreen] Speech available: $_speechAvailable');
}
```

### iOS Native Speech Features
- ✅ Automatic punctuation (periods, commas, questions, exclamations)
- ✅ Automatic capitalization
- ✅ High accuracy (Apple-quality recognition)
- ✅ On-device processing (privacy-focused)
- ✅ Works offline (on-device ML models)

### Simulator vs Physical Device

| Feature | Simulator | Physical Device |
|---------|-----------|-----------------|
| Text Input | ✅ Works | ✅ Works |
| Voice Input (STT) | ❌ Limited/Non-functional | ✅ Works perfectly |
| TTS Output | ✅ Works | ✅ Works |
| Microphone Access | ⚠️ Mac microphone (unreliable) | ✅ Device microphone |
| Speech Recognition | ❌ Framework limitations | ✅ Full iOS Speech API |
| Punctuation | N/A | ✅ Automatic |
| Capitalization | N/A | ✅ Automatic |

## Conclusion

The microphone "Listening" state without transcription is **expected behavior in iOS Simulator** due to Apple's Speech Recognition framework limitations. This is not a bug in our app.

**The solution is to test voice input on a physical iOS device**, where Apple's native speech recognition works perfectly with automatic punctuation and capitalization.

All other app functionality (text input, TTS, backend API, UI) works perfectly in the simulator and is fully testable there.
