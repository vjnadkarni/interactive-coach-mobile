# Video + Voice Mode - iOS Mobile Limitation

**Date**: November 14, 2025
**Status**: Temporarily Disabled on iOS Mobile
**Platforms Affected**: iOS (iPhone/iPad)
**Platforms Working**: Web (Desktop/Mobile browsers)

---

## 🔴 Issue Summary

Video + Voice mode (HeyGen Interactive Avatar) does **not** work on iOS mobile app due to **iOS WebView audio autoplay restrictions**.

### Symptoms:
- ✅ Video displays correctly (Hera's avatar visible)
- ✅ Lip movements sync with responses
- ✅ Transcription works perfectly
- ✅ Text responses appear correctly in chat
- ❌ **NO AUDIO** - Hera's voice does not play

### Root Cause:
iOS WKWebView blocks audio playback from WebRTC MediaStreams (used by HeyGen) with the error:
```
NotAllowedError: The request is not allowed by the user agent or the platform in the current context
```

This is a **platform security restriction** by Apple that cannot be bypassed through:
- JavaScript configuration
- Audio session settings
- User gesture triggers
- WebView configuration

---

## ✅ Current Solution

**Voice-Only Mode** is the primary mobile experience:
- ✓ Crystal clear audio (ElevenLabs TTS)
- ✓ Real-time transcription with visual feedback
- ✓ Faster response times (no video buffering)
- ✓ Full AI coaching features
- ✓ No HeyGen credit usage
- ✓ Reliable on all iOS devices

**Video + Voice Mode** remains available on:
- Web version (https://coach.galenogen.com)
- Desktop browsers
- Mobile browsers (not the native app)

---

## 🔮 Future Solutions

### Option 1: HeyGen Native iOS SDK (Preferred)
**Status**: Needs research
**Complexity**: Medium
**Impact**: High

**Action Items**:
1. Contact HeyGen support to check if native iOS SDK exists
2. If available, refactor to use native SDK instead of WebView
3. This would provide full audio/video support on iOS

**Pros**:
- Native iOS audio playback (no WebView restrictions)
- Better performance
- Proper iOS integration

**Cons**:
- Requires HeyGen SDK support
- Significant refactoring
- May have different API/pricing

---

### Option 2: Hybrid Native Audio Extraction (Not Recommended)
**Status**: Technically challenging
**Complexity**: Very High
**Impact**: Medium

**Approach**:
- Extract audio stream from HeyGen's WebRTC MediaStream
- Route to native iOS AVAudioPlayer
- Keep video in WebView (muted)

**Pros**:
- Uses existing HeyGen implementation

**Cons**:
- ❌ **Lip-sync would be broken** (HeyGen video uses HeyGen TTS, we'd use ElevenLabs audio)
- Complex WebRTC audio extraction
- May violate HeyGen terms of service
- Unreliable timing synchronization

---

### Option 3: Alternative Avatar Solution
**Status**: Exploratory
**Complexity**: Very High
**Impact**: Very High

**Approach**:
- Find alternative avatar solution with native iOS SDK
- Examples: D-ID, Synthesia, or custom solution

**Pros**:
- Full control over implementation
- Native iOS support

**Cons**:
- Requires switching providers
- Significant development effort
- Migration complexity

---

## 📋 Recommended Next Steps

**Short-term (Current):**
1. ✅ Voice-Only mode as primary mobile experience
2. ✅ Clear messaging to users about Video mode availability
3. ✅ Maintain Video + Voice on web version

**Medium-term (Next Sprint):**
1. Research HeyGen native iOS SDK availability
2. If SDK exists, prototype integration
3. If SDK doesn't exist, contact HeyGen about roadmap

**Long-term (Future Release):**
1. Implement full Video + Voice on iOS (via SDK or alternative)
2. Ensure feature parity across all platforms
3. A/B test user preference (Voice-Only vs Video + Voice)

---

## 🔬 Technical Details

### iOS WebView Restrictions:
- **WKWebView** (used by `webview_flutter`) enforces strict autoplay policies
- Audio from `<video>` elements with MediaStream sources is blocked
- No JavaScript or native configuration can override this
- User gesture requirement cannot be satisfied for programmatic playback

### Testing Evidence:
- Voice-Only mode: ✅ Audio works (uses native AVAudioPlayer)
- Video + Voice mode: ❌ Audio blocked (uses WebView)
- Same device, same user, same headphones
- Confirms issue is WebView-specific, not device/settings

### Console Logs:
```
flutter: 🌐 [WebView Console] NotAllowedError: The request is not allowed...
flutter: 🌐 [WebView Console] ⚠️ Video paused, restarting...
flutter: 🌐 [WebView Console] 🔊 Video muted: false
flutter: 🌐 [WebView Console] 🔊 Video volume: 1
flutter: 🌐 [WebView Console] ✅ Video playing
```
(Video plays, audio configured correctly, but still no sound due to iOS blocking)

---

## 📞 Contact Information

**HeyGen Support**: support@heygen.com
**Question to Ask**: "Do you offer a native iOS SDK for Interactive Avatar? We're experiencing WebView audio limitations on iOS."

---

## 🏷️ Related Files

- `lib/screens/avatar_screen.dart` - Video + Voice implementation (disabled on iOS)
- `lib/screens/chat_screen.dart` - Voice-Only mode (primary mobile experience)
- `web/app/mobile-avatar/page.tsx` - Web version (works correctly)
- `ios/Runner/AppDelegate.swift` - iOS native configuration attempts

---

**Last Updated**: November 14, 2025
**Author**: Development Team
**Review Date**: To be scheduled after HeyGen SDK research
