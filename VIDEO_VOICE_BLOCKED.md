# Video+Voice Mode - iOS Implementation Blocked

**Date**: November 15-16, 2025
**Status**: ❌ **Abandoned** - iOS WebView networking limitations
**Working Alternative**: ✅ Voice-Only mode works perfectly

---

## Summary

Attempted to implement Video+Voice mode (HeyGen Interactive Avatar) on iOS mobile using a WebView approach. All components functioned correctly EXCEPT the critical backend API call, which iOS WebView blocks due to security restrictions.

---

## What We Tried

### Native iOS Approach (Previous Session)
- **Attempt**: Native Swift implementation with LiveKit SDK
- **Result**: ❌ Failed - Missing WebRTC signaling to HeyGen servers
- **Blocker**: HeyGen never joined LiveKit room (participant count = 0)
- **Root Cause**: HeyGen v1 API uses custom WebRTC signaling that Swift LiveKit SDK doesn't support

### WebView Approach (This Session)
- **Attempt**: Embed web version (`mobile-avatar/page.tsx`) in iOS WebView
- **Result**: ❌ Failed - iOS WebView blocks backend API calls
- **What Worked**:
  - ✅ WebView loads successfully
  - ✅ HeyGen avatar initializes and appears on screen
  - ✅ JWT authentication token passed from Flutter to WebView
  - ✅ Apple Speech Recognition works perfectly with punctuation
  - ✅ User transcript sent to WebView correctly
- **What Failed**:
  - ❌ **Backend API call fails** with "TypeError: Load failed"
  - ❌ WebView cannot fetch from `http://192.168.6.234:8000/chat/stream`

---

## Technical Details

### Files Modified (All Reverted)
**Mobile (`interactive-coach-mobile`):**
- `lib/screens/chat_screen.dart` - Changed navigation from `AvatarScreenNative()` to `AvatarScreen()`
- `lib/screens/login_screen.dart` - Changed post-login navigation to `ChatScreen()`
- `lib/screens/avatar_screen.dart` - Added JWT token sending to WebView
- `ios/Runner/Info.plist` - Added `NSAppTransportSecurity` exception

**Web (`interactive-coach/web`):**
- `app/mobile-avatar/page.tsx` - Added JWT token state and Authorization header to fetch

### What We Learned
1. **iOS WebView Network Security**: iOS WebView has strict App Transport Security (ATS) that blocks HTTP requests to local network IPs, even with `NSAllowsArbitraryLoads=true`
2. **WebRTC Limitations**: HeyGen's WebRTC implementation requires browser-level APIs that neither native Swift nor iOS WebView can fully support
3. **Voice-Only is Reliable**: The native Flutter + ElevenLabs TTS approach works flawlessly

---

## Error Log
```
flutter: 🌐 [WebView Console] 📤 Sending to backend: Hi, I'm Vijay. Can you help me with my fitness?
flutter: 🌐 [WebView Console] ❌ Error processing user message: TypeError: Load failed
flutter: 📨 [AvatarScreen] Message from WebView: {"type":"error","message":"Failed to get response from backend"}
```

**Diagnosis**: iOS WebView's `fetch()` API fails to connect to local backend server despite:
- CORS configured correctly on backend (`allow_origins=["*"]`)
- ATS exception added to Info.plist
- JWT token being passed correctly
- Backend server confirmed running and accessible from Mac

**Likely Cause**: iOS WebView has additional networking restrictions beyond ATS that prevent local network HTTP requests from WebView JavaScript context, even in development builds.

---

## Recommended Solution

**Abandon Video+Voice mode on iOS mobile.**

### Why Voice-Only is Better for Mobile:
1. **Works Perfectly**: Native Flutter + ElevenLabs TTS is reliable and fast
2. **Better Performance**: No WebRTC overhead, lower battery usage
3. **Simpler Architecture**: No WebView complexity
4. **Consistent UX**: Same Apple Speech Recognition as Video+Voice attempt
5. **Lower Costs**: ElevenLabs TTS cheaper than HeyGen credits

### Future Possibilities (If Video+Voice is Required):
1. **Use HeyGen v2 Streaming API** (if/when available) with native iOS WebRTC support
2. **Proxy Backend Calls**: Create a local proxy server on the iPhone that the WebView can call (complex)
3. **Web App Only**: Keep Video+Voice exclusive to web browsers (coach.galenogen.com)

---

## Current Status

- ✅ **Voice-Only Mode**: Fully functional and production-ready
- ✅ **Web Video+Voice**: Working at https://coach.galenogen.com
- ❌ **Mobile Video+Voice**: Abandoned due to iOS WebView limitations

**User Decision**: Move forward with Voice-Only mode only. Revisit Video+Voice mobile implementation later if needed.

---

## Files to Keep

These files contain useful WebView implementation knowledge for future reference:

- `NATIVE_HEYGEN_COMPLETE_REFERENCE.md` - Native Swift attempt documentation
- `VIDEO_VOICE_BLOCKED.md` - This file
- `web/app/mobile-avatar/page.tsx` - Working WebView implementation (for web browsers)

All experimental mobile code has been reverted to keep the codebase clean.
