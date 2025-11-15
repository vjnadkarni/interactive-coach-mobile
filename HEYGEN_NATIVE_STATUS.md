# HeyGen Native iOS Implementation - Status & Next Steps

**Date:** November 15, 2025
**Status:** Blocked - WebView Solution Recommended

---

## Current Situation

### What's Working ✅
- Voice-Only mode (native Flutter with ElevenLabs TTS) - **Perfect!**
- Speech recognition (native iOS Speech framework) - **Perfect!**
- Backend conversation flow - **Perfect!**
- Text chat - **Perfect!**
- LiveKit connection establishes successfully

### What's NOT Working ❌
- Video+Voice mode (HeyGen Interactive Avatar)
- No video rendering (black screen)
- No audio from avatar
- HeyGen avatar participant never joins LiveKit room

---

## Root Cause Analysis

### The Problem
HeyGen Streaming Avatar v1 requires **WebRTC signaling** that we're not implementing:

1. **What we did:**
   - ✅ Called HeyGen `/v1/streaming.new` API
   - ✅ Connected to LiveKit room with access token
   - ✅ Set up track subscription callbacks
   - ❌ **MISSING:** Connected to HeyGen's WebRTC signaling server

2. **What should happen:**
   ```
   Client → HeyGen API (create session)
   Client → LiveKit (join room)
   Client → HeyGen Signaling Server (wss://webrtc-signaling.heygen.io/...)
   Client ↔ Signaling Server (exchange SDP offers/answers)
   HeyGen Avatar → LiveKit (joins room as "convai" participant)
   Client ← LiveKit (receives video/audio tracks)
   ```

3. **What's actually happening:**
   ```
   Client → HeyGen API (create session) ✅
   Client → LiveKit (join room) ✅
   [Nothing else happens - avatar never joins]
   Polling: Participant count stays 0 forever ❌
   ```

### Evidence from Logs
```
🔍 [HeyGenVM] Polling attempt 1/30 - Participant count: 0
🔍 [HeyGenVM] Polling attempt 2/30 - Participant count: 0
...
🔍 [HeyGenVM] Polling attempt 25/30 - Participant count: 0
```

**HeyGen avatar NEVER joins the LiveKit room** because we're not completing the WebRTC signaling handshake.

---

## Why Native Implementation is Hard

Implementing HeyGen Streaming Avatar v1 from scratch requires:

1. **WebRTC Signaling Client**
   - Connect to `wss://webrtc-signaling.heygen.io/v2-alpha/interactive-avatar/session/{id}`
   - Handle WebSocket messages
   - Exchange SDP offers/answers
   - Exchange ICE candidates

2. **Complex WebRTC Coordination**
   - Synchronize LiveKit connection with HeyGen signaling
   - Handle race conditions
   - Manage connection state

3. **Estimated Effort:** 500+ lines of complex Swift code, several days of debugging

### What the Web Version Does
The web version uses **HeyGen's JavaScript SDK** (`@heygen/streaming-avatar`):

```typescript
const avatar = new StreamingAvatar({ apiKey });
await avatar.createStartAvatar({
  avatarName: 'Marianne_Chair_Sitting_public',
  quality: AvatarQuality.High,
  voice: { voiceId: '834239226a1242e89a9fe228e0ba61d4' }
});
```

**The SDK handles everything automatically:**
- ✅ WebRTC signaling
- ✅ LiveKit connection
- ✅ Track subscription
- ✅ Video rendering
- ✅ Audio playback

---

## Recommended Solution: WebView Approach

### Strategy
Keep the working web implementation, embed it in Flutter mobile app:

1. **Voice-Only Mode:** Native Flutter (current implementation - works perfectly!)
2. **Video+Voice Mode:** WebView embedding Next.js page

### Implementation Plan

#### Step 1: Create Mobile-Optimized Web Page
Create `/web/app/mobile-avatar/page.tsx`:
- Same HeyGen avatar logic as desktop version
- Mobile-optimized layout (full-screen video)
- Exposes JavaScript bridge for Flutter communication
- No navigation chrome, just avatar + chat

#### Step 2: Flutter WebView Integration
Use `webview_flutter` package:
```dart
WebView(
  initialUrl: 'http://192.168.6.234:3000/mobile-avatar',
  javascriptMode: JavascriptMode.unrestricted,
  javascriptChannels: {
    JavascriptChannel(
      name: 'FlutterBridge',
      onMessageReceived: (JavascriptMessage message) {
        // Handle messages from web
      }
    )
  }
)
```

#### Step 3: JavaScript Bridge
Communication between Flutter ↔ Web:

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
- Voice-Only toggle: Native Flutter screen (current)
- Video+Voice toggle: WebView screen (new)
- Seamless switching between modes
- Shared conversation history

---

## Advantages of WebView Approach

### ✅ Pros
1. **Works immediately** - reuse battle-tested web code
2. **Easy to maintain** - one codebase for web + mobile video/voice
3. **No complex WebRTC code** - HeyGen SDK handles it
4. **Proven reliability** - web version already working perfectly
5. **Fast implementation** - 1-2 hours vs several days

### ⚠️ Cons
1. Requires network connection to Next.js server (already required for backend anyway)
2. Slight performance overhead (negligible for video streaming)
3. WebView uses more memory than native (but we're already streaming video)

---

## Alternative: Wait for HeyGen SDK v2

HeyGen is developing v2 of their API. Check if they'll provide:
- Native iOS SDK
- Better documentation for native implementation
- Simplified WebRTC flow

**For now:** WebView is the pragmatic solution.

---

## Files Modified (Session 2)

### Swift Files
- `ios/Runner/HeyGen/HeyGenAvatarViewModel.swift`
  - Added participant polling (lines 189-265)
  - Added track detection flags
  - Fixed Swift 6 concurrency issues

### Dart Files
- `lib/screens/avatar_screen_native.dart`
  - Fixed empty final transcript bug (lines 82-102)

### What Works
- ✅ Speech recognition and transcription
- ✅ Backend API communication
- ✅ Chat UI updates
- ✅ LiveKit connection

### What Doesn't Work
- ❌ Video rendering (HeyGen avatar never joins room)
- ❌ Audio playback (no audio track received)
- ❌ speak() API (fails with "Session is not in correct state")

---

## Next Session Plan

1. **Option A: WebView Implementation** (Recommended - 1-2 hours)
   - Create `/web/app/mobile-avatar/page.tsx`
   - Install `webview_flutter` package
   - Create WebView screen in Flutter
   - Set up JavaScript bridge
   - Test end-to-end

2. **Option B: Continue Native Investigation** (Risky - days of work)
   - Research HeyGen's WebRTC signaling protocol
   - Implement signaling client in Swift
   - Debug complex WebRTC coordination
   - High chance of hitting more blockers

**Recommendation:** Go with Option A (WebView). It's the pragmatic engineering choice.

---

## Questions to Decide Tomorrow

1. Are you comfortable with WebView approach?
2. Is Next.js server always accessible from mobile (same network / VPN / internet)?
3. Do you want to keep both Voice-Only (native) and Video+Voice (WebView)?
4. Should we add a fallback if WebView fails to load?

---

## Useful References

- **Web implementation:** `/Users/vijay/venv/interactive-coach/web/components/AvatarPanel.tsx`
- **HeyGen JS SDK:** `@heygen/streaming-avatar` package
- **Flutter WebView:** https://pub.dev/packages/webview_flutter
- **Current logs:** All polling shows participant count = 0

---

**Status:** Ready to pivot to WebView solution tomorrow. Native implementation blocked on missing WebRTC signaling.
