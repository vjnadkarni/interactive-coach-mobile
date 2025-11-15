# Video + Voice Mode iOS Debugging Session

**Date**: November 14, 2025
**Status**: Short-term solution implemented, long-term solution identified
**Issue**: No audio playback in Video + Voice mode on iOS mobile despite working video and transcription

---

## Executive Summary

**Problem**: Video + Voice mode showed Hera's avatar with correct lip-sync and transcription, but produced zero audio output on iOS devices (tested on iPhone 12 with Shokz headphones, iPhone speakers, and ear speakers).

**Root Cause**: iOS WKWebView enforces strict autoplay policies that block audio playback from WebRTC MediaStream sources (used by HeyGen Interactive Avatar). This is a platform security restriction that cannot be bypassed through JavaScript or native configuration.

**Short-Term Solution**: ✅ IMPLEMENTED
- Disabled Video + Voice mode on iOS mobile with clear user messaging
- Enhanced Voice-Only mode as the recommended mobile experience
- Created comprehensive documentation for future development

**Long-Term Solution**: HeyGen Native iOS SDK (identified and researched)
- GitHub: https://github.com/HeyGen-Official/interactive-avatar-swiftui
- Uses SwiftUI + LiveKit for native WebRTC implementation
- Bypasses WebView restrictions entirely
- Implementation pending future development cycle

---

## Detailed Timeline of Debugging

### Initial Problem Report

**User's Observations:**
1. **Voice-Only Mode**: ✅ Working perfectly
   - Crystal clear audio on Shokz headphones
   - Excellent real-time transcription with visual feedback box
   - Fast, responsive, reliable

2. **Video + Voice Mode**: ❌ Multiple issues
   - Avatar displays correctly (Hera visible)
   - Lip movements sync with responses
   - Transcription works
   - Text responses appear in chat
   - **NO AUDIO** - tested on:
     - Shokz Bluetooth headphones
     - iPhone native speakers
     - Ear speaker
   - Unwanted fullscreen behavior
   - No real-time transcription visual feedback (unlike Voice-Only)

**User's Question**: "Does Video + Voice mode use Apple's native speech recognition or Deepgram for transcription? Could this affect audio?"

---

## Investigation Phase 1: Transcription Method Analysis

**File Analyzed**: `lib/screens/avatar_screen.dart`

**Finding**: Line 21 shows `NativeSpeechService _nativeSpeech = NativeSpeechService()`

**Conclusion**: Video + Voice mode uses Apple's native iOS Speech Recognition (SFSpeechRecognizer), identical to Voice-Only mode.

**Result**: Transcription method ruled out as cause of audio issue.

---

## Investigation Phase 2: Audio Architecture Comparison

**Voice-Only Mode Architecture**:
```
User speaks → iOS SFSpeechRecognizer → Text → Backend API →
ElevenLabs TTS → Native AVAudioPlayer → Audio Output ✅
```

**Video + Voice Mode Architecture**:
```
User speaks → iOS SFSpeechRecognizer → Text → Backend API →
HeyGen Avatar (WebView) → WebRTC MediaStream → BLOCKED BY iOS ❌
```

**Key Difference**: Voice-Only uses native iOS AVAudioPlayer (no WebView), Video + Voice uses WebView with HeyGen's WebRTC MediaStream.

**Critical Discovery**: iOS WKWebView blocks audio autoplay from MediaStream sources with `NotAllowedError`.

---

## Investigation Phase 3: React State Closure Issue

**Error Observed**:
```
flutter: 🌐 [WebView Console] ❌ Cannot speak - avatar not initialized
```

**Root Cause**: React `useState` hook - event listeners captured initial null state.

**Fix Applied** (`web/app/mobile-avatar/page.tsx`):
```typescript
// Changed from useState to useRef
const avatarRef = useRef<StreamingAvatar | null>(null);

// Updated event listener
if (avatarRef.current && text) {
  avatarRef.current.speak({ text: cleanText, ... });
}
```

**Result**: Avatar initialization fixed, HeyGen API receiving speak commands.

**User Feedback**: "Hera is speaking the responses now, but the only way I can tell is by matching her lip movements with the output in the chat window. For some strange reason, there is no sound."

---

## Investigation Phase 4: iOS WebView Audio Restrictions

**Console Error**:
```
NotAllowedError: The request is not allowed by the user agent
or the platform in the current context, possibly because the
user denied permission.
```

**Additional Logs**:
```
flutter: 🌐 [WebView Console] 🔊 Video muted: false
flutter: 🌐 [WebView Console] 🔊 Video volume: 1
flutter: 🌐 [WebView Console] ✅ Video playing
```

**Analysis**: Video element correctly configured (unmuted, volume 1.0, playing), but iOS still blocks audio.

**Testing Evidence**:
- Voice-Only mode: ✅ Audio works (uses native AVAudioPlayer)
- Video + Voice mode: ❌ Audio blocked (uses WebView)
- Same device, same user, same headphones
- Confirms issue is WebView-specific, not device/settings

---

## Attempted Fixes (All Failed)

### Attempt 1: Explicit Video Unmuting
```typescript
videoElement.muted = false;
videoElement.volume = 1.0;
```
**Result**: No change - iOS still blocks audio

### Attempt 2: AVAudioSession Configuration
```swift
try AVAudioSession.sharedInstance().setCategory(
  .playback,
  mode: .spokenAudio,
  options: [.allowBluetoothA2DP, .duckOthers]
)
```
**Result**: No change - WebView policy overrides native audio session

### Attempt 3: AudioContext Initialization
```typescript
const audioContext = new AudioContext();
audioContext.resume();
```
**Result**: No change - MediaStream audio still blocked

### Attempt 4: Method Swizzling (WKWebView Configuration)
**Goal**: Override `mediaTypesRequiringUserActionForPlayback` at runtime

**Code Attempted**:
```swift
private func swizzleWKWebView() {
  // Swizzle WKWebView.init to configure media playback
}
```

**Result**: Xcode build failures with integer precision errors

**Conclusion**: Method swizzling approach abandoned

### Attempt 5: User Gesture Trigger
**Strategy**: "Tap to Start" overlay to capture user gesture

**Implementation**:
```typescript
<div onClick={() => {
  mediaStream.current.muted = false;
  mediaStream.current.play();
}}>
  Tap to Start
</div>
```

**Result**: Video plays, but audio still blocked by iOS policy

---

## Hybrid Solution Evaluation

**User's Question**: "In the hybrid solution, would there be lip sync between the spoken audio from iOS AVAudioPlayer and Hera's lip movements?"

**Analysis**:
- HeyGen generates video with lip-sync tied to HeyGen's TTS timing
- Hybrid approach would use ElevenLabs TTS via native AVAudioPlayer
- Two different TTS engines = two different timing profiles
- Even with timing synchronization, prosody and word boundaries would differ

**Conclusion**: ❌ NO - Lip-sync would be broken or unreliable

**Why Lip-Sync is Impossible**:
1. HeyGen's lips move based on HeyGen's internal TTS timing
2. ElevenLabs audio has different timing, prosody, and pacing
3. Attempting to sync would require:
   - Frame-by-frame video manipulation
   - Audio time-stretching
   - Complex synchronization logic
   - May violate HeyGen terms of service
4. End result: Lips and audio visibly out of sync

**User Decision**: Accepted this limitation and chose short-term solution instead.

---

## Final Solution Options Presented

### Option 1: HeyGen Native iOS SDK (Preferred) ✅
**Status**: Researched and confirmed viable

**Pros**:
- Native iOS audio playback (no WebView restrictions)
- Better performance
- Proper iOS integration
- Uses SwiftUI + LiveKit

**Cons**:
- Requires significant refactoring
- May have different API/pricing
- Development time investment

**Resources**:
- GitHub: https://github.com/HeyGen-Official/interactive-avatar-swiftui
- Docs: https://docs.heygen.com/docs/streaming-avatar-ios-sdk
- LiveKit Integration: https://docs.heygen.com/docs/streaming-api-integration-with-livekit-v2

**Dependencies**:
- LiveKit Swift SDK
- Alamofire (HTTP networking)
- SDWebImageSwiftUI (image loading)

### Option 2: Hybrid Native Audio Extraction (Not Recommended) ❌
**Status**: Technically challenging, lip-sync would be broken

**Approach**:
- Extract audio stream from HeyGen's WebRTC MediaStream
- Route to native iOS AVAudioPlayer
- Keep video in WebView (muted)

**Cons**:
- ❌ Lip-sync broken (different TTS engines)
- Complex WebRTC audio extraction
- May violate HeyGen terms of service
- Unreliable timing synchronization

### Option 3: Alternative Avatar Solution
**Status**: Exploratory, significant migration effort

**Approach**:
- Find alternative avatar provider with native iOS SDK
- Examples: D-ID, Synthesia, custom solution

**Cons**:
- Requires switching providers
- Significant development effort
- Migration complexity
- May not have equivalent quality/features

---

## Short-Term Solution Implementation

**User's Decision**: "For the short term I'm ok with going with Option A that you recommended so that we can move onto additional features that need to be implemented."

### Changes Made

#### 1. Modified `lib/screens/avatar_screen.dart`
**Purpose**: Show explanatory dialog and redirect to Voice-Only mode

**Code**:
```dart
@override
void initState() {
  super.initState();

  // Show message that Video+Voice is not available on mobile
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _showVideoModeNotAvailableDialog();
  });
}

void _showVideoModeNotAvailableDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Video + Voice Mode'),
        content: const Text(
          'Video + Voice mode with the interactive avatar is currently not available on iOS mobile due to platform limitations.\n\n'
          'Please use Voice-Only mode for the best mobile experience with Hera. Voice-Only mode provides:\n\n'
          '• Crystal clear audio\n'
          '• Real-time transcription\n'
          '• Faster responses\n'
          '• Full AI coaching features\n\n'
          'Video + Voice mode is available on the web version.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              );
            },
            child: const Text('Switch to Voice-Only Mode'),
          ),
        ],
      );
    },
  );
}
```

#### 2. Enhanced `lib/screens/chat_screen.dart`
**Purpose**: Position Voice-Only mode as the recommended mobile experience

**Changes**:
- Added subtitle "Voice-Only Mode (Recommended)" in AppBar
- Added info button explaining Voice-Only benefits
- Modified Video toggle to show explanatory dialog instead of switching

**Key UI Elements**:
```dart
title: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text('Chat with Hera', style: TextStyle(fontSize: 18)),
    const SizedBox(height: 2),
    const Text(
      'Voice-Only Mode (Recommended)',
      style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.normal),
    ),
  ],
),
```

**Info Dialog Content**:
```
Voice-Only mode is optimized for mobile and provides:

✓ Crystal clear audio with Hera
✓ Real-time transcription as you speak
✓ Faster response times
✓ Full AI coaching features
✓ No video buffering or connectivity issues

Video + Voice mode is available on the web version.
```

**Video Toggle Behavior**:
```dart
Switch(
  value: _videoMode,
  onChanged: (value) {
    if (value) {
      // Show dialog explaining Video mode is not available
      showDialog(...);
    }
  },
),
```

#### 3. Created `VIDEO_VOICE_IOS_LIMITATION.md`
**Purpose**: Comprehensive documentation for future development

**Contents**:
- Issue summary with symptoms and root cause
- Current solution (Voice-Only mode)
- Future solution options with detailed pros/cons
- Technical details and console logs
- Recommended next steps (short, medium, long-term)
- HeyGen contact information
- Related files reference

---

## Technical Deep Dive: Why iOS WebView Blocks Audio

### iOS WebView Security Policies

**WKWebView Autoplay Rules**:
1. Audio playback requires explicit user gesture
2. User gesture must be recent (not stale)
3. MediaStream sources from WebRTC are blocked by default
4. No JavaScript configuration can override this
5. No native WKWebView configuration accessible via Flutter can bypass this

### What We Tried vs. What's Required

**What We Tried** (via JavaScript):
- ✅ Explicit unmuting: `videoElement.muted = false`
- ✅ Volume control: `videoElement.volume = 1.0`
- ✅ User gesture: "Tap to Start" overlay
- ✅ AudioContext resumption

**What's Required** (not accessible via Flutter WebView):
- ❌ Native WKWebView configuration:
  ```swift
  webView.configuration.mediaTypesRequiringUserActionForPlayback = []
  ```
- ❌ Direct access to WKWebViewConfiguration before initialization
- ❌ Method swizzling of WKWebView initializers (attempted, build failed)

**Why webview_flutter Can't Help**:
- Plugin provides high-level Flutter API
- Does not expose underlying WKWebViewConfiguration
- Cannot modify `mediaTypesRequiringUserActionForPlayback` property
- Would require forking the plugin or creating custom native implementation

---

## HeyGen Native iOS SDK Research

### Official Resources

**GitHub Repository**:
https://github.com/HeyGen-Official/interactive-avatar-swiftui

**Official Documentation**:
https://docs.heygen.com/docs/streaming-avatar-ios-sdk

**LiveKit Integration Guide**:
https://docs.heygen.com/docs/streaming-api-integration-with-livekit-v2

### SDK Architecture

**Technology Stack**:
- **SwiftUI** - Native iOS UI framework
- **LiveKit SDK** - WebRTC infrastructure
- **Alamofire** - HTTP networking
- **SDWebImageSwiftUI** - Image loading

**Key Features**:
- 100% Swift implementation (no WebView)
- Native iOS audio playback (bypasses WebView restrictions)
- Real-time WebRTC video/audio streaming
- HeyGen API integration for avatar sessions

### Implementation Requirements

**Prerequisites**:
1. HeyGen API token
2. Xcode 14.0+
3. iOS 14.0+ deployment target
4. Swift 5.5+

**Dependencies** (via Swift Package Manager):
```swift
dependencies: [
  .package(url: "https://github.com/livekit/client-sdk-swift", from: "2.0.0"),
  .package(url: "https://github.com/Alamofire/Alamofire", from: "5.0.0"),
  .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI", from: "2.0.0")
]
```

**Estimated Integration Time**: 1-2 weeks
- SDK setup and configuration
- API authentication implementation
- UI integration with existing Flutter app
- Testing on physical devices

### Migration Strategy

**Option A: Hybrid Flutter + Native iOS**
- Keep Flutter for chat UI and navigation
- Use native iOS SwiftUI for avatar view only
- Communication via platform channels

**Option B: Full Native iOS Refactor**
- Rewrite avatar screen in Swift
- Keep backend API unchanged
- Maintain feature parity with web version

**Recommendation**: Option A (Hybrid) - faster implementation, maintains existing Flutter codebase.

---

## Recommended Next Steps

### Short-term (Current) ✅
1. ✅ Voice-Only mode as primary mobile experience
2. ✅ Clear messaging to users about Video mode availability
3. ✅ Maintain Video + Voice on web version

### Medium-term (Next Sprint)
1. Contact HeyGen support about native iOS SDK best practices
   - Email: support@heygen.com
   - Question: "We're implementing the Streaming Avatar iOS SDK. What are best practices for Flutter integration?"
2. Prototype HeyGen SDK integration
3. Test audio playback on physical iOS devices
4. Evaluate performance and credit usage

### Long-term (Future Release)
1. Implement full Video + Voice on iOS via native SDK
2. Ensure feature parity across all platforms (Web, iOS, Android)
3. A/B test user preference (Voice-Only vs Video + Voice)
4. Consider Android native implementation if needed

---

## User Feedback and Decisions

**User's Explicit Decisions**:
1. ✅ Accepted short-term solution (disable Video+Voice on mobile)
2. ✅ Acknowledged need to fix Video+Voice for production release
3. ✅ Chose to prioritize other features in the near term
4. ✅ Direct quote: "For the short term I'm ok with going with Option A that you recommended so that we can move onto additional features that need to be implemented. However, we will need to come back to it at a later time and fix Video + Voice mode, since we cannot go to market with a product that does not have a working Video + Voice mode."

**User Testing Feedback**:
- Voice-Only mode: "Perfect audio on Shokz headphones, excellent real-time transcription with visual feedback box"
- Video + Voice mode: "Hera is speaking the responses now [confirmed by lip-reading], but... there is no sound"
- Headphones verification: "As a quick check, I tried the same query in the Voice-only mode and there was able to hear the response loud and clear. Thus confirms that there is no issue with my headphones or with the iPhone 12's sound settings."

---

## Files Modified Summary

### Flutter Mobile App

**`lib/screens/avatar_screen.dart`**:
- Removed initialization of speech and WebView
- Added dialog explaining Video+Voice unavailable on iOS
- Auto-redirects to ChatScreen (Voice-Only mode)

**`lib/screens/chat_screen.dart`**:
- Enhanced AppBar with "Voice-Only Mode (Recommended)" subtitle
- Added info button with explanatory dialog
- Modified Video toggle to show dialog instead of switching modes

### Web Application (Debugging)

**`web/app/mobile-avatar/page.tsx`**:
- Changed `useState` to `useRef` for avatar object (fixed React closure issue)
- Added explicit unmuting: `videoElement.muted = false; videoElement.volume = 1.0`
- Added logging for debugging audio configuration

**`ios/Runner/AppDelegate.swift`**:
- Configured AVAudioSession for playback with Bluetooth support
- Simplified after method swizzling attempts failed
- Final version maintains audio session configuration only

### Documentation

**`VIDEO_VOICE_IOS_LIMITATION.md`** (NEW):
- Comprehensive documentation of iOS limitation
- Root cause analysis
- Current and future solutions
- Technical details and next steps

**`VIDEO_VOICE_DEBUGGING_SESSION.md`** (NEW - this file):
- Complete debugging session timeline
- All attempted fixes and results
- User feedback and decisions
- Recommended implementation path

---

## Conclusion

**Problem**: iOS WebView blocks HeyGen Interactive Avatar audio playback due to platform security restrictions.

**Short-Term Solution**: ✅ IMPLEMENTED
- Voice-Only mode positioned as recommended mobile experience
- Clear user messaging about Video+Voice unavailability
- Comprehensive documentation for future development

**Long-Term Solution**: HeyGen Native iOS SDK
- ✅ SDK identified and researched
- ✅ Technical requirements documented
- ✅ Migration strategy outlined
- ⏳ Implementation pending future development cycle

**Status**: Ready to move on to additional features as requested by user.

---

**Last Updated**: November 14, 2025
**Author**: Development Team
**Next Review**: When prioritizing Video + Voice native SDK implementation
