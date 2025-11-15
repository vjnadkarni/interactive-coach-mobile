# Native HeyGen Implementation - Complete Reference

**Date:** November 15, 2025
**Status:** Investigation Complete - WebView Approach Recommended
**Branch:** `wip`

---

## Executive Summary

### What We Attempted
Implement HeyGen Interactive Avatar natively in iOS using Swift and LiveKit SDK to enable Video+Voice mode in the Flutter mobile app.

### What Works ✅
- Voice-Only mode (native Flutter + ElevenLabs TTS) - **Perfect!**
- Speech recognition (native iOS Speech framework) - **Perfect!**
- Backend conversation flow - **Perfect!**
- LiveKit connection - **Successful!**

### What Doesn't Work ❌
- HeyGen avatar never joins LiveKit room
- No video rendering (black screen)
- No audio playback from avatar
- `speak()` API calls fail with "Session is not in correct state"

### Root Cause
Missing WebRTC signaling implementation. HeyGen requires connecting to their signaling server (`wss://webrtc-signaling.heygen.io/...`) to exchange SDP offers/answers before the avatar joins the LiveKit room. This is NOT documented and requires reverse-engineering the JavaScript SDK.

### Recommended Solution
**Use WebView to embed the working Next.js web page** instead of native implementation:
- Reuses battle-tested web code
- Works immediately (already proven in production)
- Easy to maintain (one codebase)
- 1-2 hours vs days of debugging

---

## Technical Details

### Architecture Attempted

```
iOS App (Swift)
├── HeyGenAvatarViewController.swift (platform view controller)
├── HeyGenAvatarViewModel.swift (session management + LiveKit)
├── HeyGenAPI.swift (REST API client)
└── HeyGenConfig.swift (constants)

Flutter Layer
└── avatar_screen_native.dart (UI + method channel)

Dependencies
├── LiveKit Swift SDK 2.10.0 (SPM)
└── Swift 6 language mode
```

### What We Implemented

#### 1. HeyGen API Client (`HeyGenAPI.swift`)
- `createSession()` - Calls `/v1/streaming.new` ✅
- `stopSession()` - Calls `/v1/streaming.stop` ✅
- `sendTask()` - Calls `/v1/streaming.task` (fails with 400)
- Complete error handling and logging

#### 2. LiveKit Integration (`HeyGenAvatarViewModel.swift`)
- Room connection ✅
- RoomDelegate callbacks ✅
- Track subscription detection ✅
- Participant polling (every 1 second for 30 attempts) ✅
- Video view setup ✅
- Audio session configuration ✅

#### 3. Flutter Platform View
- UiKitView embedding ✅
- Method channel communication ✅
- Native speech recognition integration ✅

### The Missing Piece

```swift
// We do this:
let session = try await api.createSession(...)  // ✅
try await room?.connect(url: session.url, token: session.accessToken)  // ✅

// We DON'T do this (undocumented requirement):
// Connect to wss://webrtc-signaling.heygen.io/v2-alpha/interactive-avatar/session/{id}
// Exchange SDP offer/answer via WebSocket
// Handle ICE candidates
// THEN avatar joins LiveKit room
```

**Evidence from Logs:**
```
🔍 [HeyGenVM] Polling attempt 1/30 - Participant count: 0
🔍 [HeyGenVM] Polling attempt 2/30 - Participant count: 0
...
🔍 [HeyGenVM] Polling attempt 25/30 - Participant count: 0
```

Participant count **never** increases because avatar never joins.

### Why Web Version Works

The web version uses HeyGen's JavaScript SDK:
```typescript
const avatar = new StreamingAvatar({ apiKey });
await avatar.createStartAvatar({
  avatarName: 'Marianne_Chair_Sitting_public',
  quality: AvatarQuality.High,
  voice: { voiceId: '834239226a1242e89a9fe228e0ba61d4' }
});
```

**This SDK hides ALL the complexity:**
- ✅ WebRTC signaling
- ✅ SDP offer/answer exchange
- ✅ LiveKit connection
- ✅ Track subscription
- ✅ Video rendering
- ✅ Audio playback

We tried to replicate this manually in Swift - it's **not feasible** without reverse-engineering the SDK or official native SDK from HeyGen.

---

## Files Created/Modified

### New Swift Files
- `ios/Runner/HeyGen/HeyGenAvatarViewController.swift` (211 lines)
- `ios/Runner/HeyGen/HeyGenAvatarViewModel.swift` (425 lines)
- `ios/Runner/HeyGen/HeyGenAPI.swift` (173 lines)
- `ios/Runner/HeyGen/HeyGenConfig.swift` (33 lines)

### Modified Swift Files
- `ios/Runner/AppDelegate.swift` - Audio session configuration
- `ios/Runner/NativeSpeechRecognizer.swift` - Minor fixes

### New Dart Files
- `lib/screens/avatar_screen_native.dart` (449 lines)

### Modified Dart Files
- `lib/screens/chat_screen.dart` - Toggle between web/native avatar screens
- `lib/screens/avatar_screen.dart` - Minor adjustments
- `lib/services/native_speech_service.dart` - Speech recognition fixes

### Xcode Configuration
- `ios/Runner.xcodeproj/project.pbxproj` - Added HeyGen files to build
- SPM: LiveKit Swift SDK 2.10.0 integrated
- Swift 6 language mode enabled

---

## Debugging Session Summary

### Session 1: Initial Setup
- Created all Swift files
- Integrated LiveKit SPM package
- Set up platform view
- Result: Build errors (missing files in Xcode)

### Session 2: Build Fixes
- Added files to Xcode project manually
- Linked LiveKit framework
- Fixed Swift 6 concurrency errors
- Fixed `Participant.Identity` type conversion
- Result: Build successful, LiveKit connects

### Session 3: Track Detection
- Implemented `didAddParticipant` callback
- Added track subscription detection
- Added video view setup
- Result: Callback never fires (participant never joins)

### Session 4: Participant Polling
- Added polling mechanism (check every 1s for 30s)
- Detailed logging of participant count
- Result: Count stays 0 forever - avatar never joins room

### Discovery: Missing Signaling
- Analyzed HeyGen API response
- Found `realtime_endpoint` field: `wss://webrtc-signaling.heygen.io/...`
- Realized we're not connecting to signaling server
- Compared with web SDK implementation
- **Conclusion:** Native implementation requires reverse-engineering WebRTC signaling protocol

---

## WebView Solution Plan

### Implementation Steps

#### Step 1: Create Mobile-Optimized Web Page
File: `web/app/mobile-avatar/page.tsx`
- Same HeyGen logic as desktop
- Mobile-optimized layout (full-screen video)
- JavaScript bridge for Flutter communication
- No navigation chrome, just avatar + chat

#### Step 2: Flutter WebView
Package: `webview_flutter`
```dart
WebView(
  initialUrl: 'http://192.168.6.234:3000/mobile-avatar',
  javascriptMode: JavascriptMode.unrestricted,
  javascriptChannels: {
    JavascriptChannel(
      name: 'FlutterBridge',
      onMessageReceived: (message) {
        // Handle web → Flutter
      }
    )
  }
)
```

#### Step 3: JavaScript Bridge
**Flutter → Web:**
```dart
webViewController.runJavascript('sendMessage("$userText")');
```

**Web → Flutter:**
```typescript
window.FlutterBridge.postMessage(JSON.stringify({
  type: 'response',
  text: 'Hey Vijay...'
}));
```

#### Step 4: User Experience
- Voice-Only: Native Flutter screen (current)
- Video+Voice: WebView screen (new)
- Seamless toggle between modes
- Shared conversation history

### Estimated Implementation Time
- 1-2 hours (vs days for native debugging)

### Pros/Cons

**✅ Pros:**
- Works immediately
- Reuses proven web code
- Easy to maintain
- No complex WebRTC code

**⚠️ Cons:**
- Requires network to Next.js server (already needed for backend anyway)
- Slight performance overhead (negligible for video)
- WebView uses more memory (but we're streaming video anyway)

---

## Alternative: Wait for HeyGen SDK v2

HeyGen may release native iOS SDK in the future. Check:
- Official SDK roadmap
- HeyGen developer forums
- API v2 announcements

**For now:** WebView is the pragmatic engineering choice.

---

## Reference Documentation

### Created During Investigation
- `HEYGEN_NATIVE_STATUS.md` - Status analysis and next steps
- `HEYGEN_NATIVE_IMPLEMENTATION_SUMMARY.md` - Technical implementation details
- `HEYGEN_NATIVE_IOS_SETUP.md` - Setup instructions
- `VIDEO_VOICE_DEBUGGING_SESSION.md` - Debugging session notes
- `VIDEO_VOICE_IOS_LIMITATION.md` - Limitation analysis
- `XCODE_PACKAGE_SETUP.md` - Xcode SPM setup guide
- `CRITICAL_FIX_APPLIED.md` - Critical fixes log
- `TWO_CRITICAL_FIXES.md` - Bug fix documentation
- `QUICK_START_NATIVE_HEYGEN.md` - Quick start guide
- `NATIVE_HEYGEN_COMPLETE_REFERENCE.md` - This document

### Web Implementation Reference
- `/Users/vijay/venv/interactive-coach/web/components/AvatarPanel.tsx`
- HeyGen JS SDK: `@heygen/streaming-avatar` package

---

## Decision Points for Next Session

1. ✅ Are you comfortable with WebView approach?
2. ✅ Is Next.js server always accessible from mobile?
3. ✅ Keep both Voice-Only (native) and Video+Voice (WebView)?
4. ✅ Add fallback if WebView fails to load?

---

## Conclusion

**Native iOS HeyGen implementation is blocked** on missing WebRTC signaling. The required signaling protocol is not documented and would require reverse-engineering HeyGen's JavaScript SDK.

**Recommended path forward:** WebView approach to embed the working Next.js web page. This is:
- ✅ Pragmatic (reuses proven code)
- ✅ Fast (1-2 hours implementation)
- ✅ Maintainable (single codebase)
- ✅ Reliable (web version already in production)

Voice-Only mode remains fully functional as native Flutter implementation.

---

**Status:** Ready to proceed with WebView implementation or await HeyGen native SDK v2.
