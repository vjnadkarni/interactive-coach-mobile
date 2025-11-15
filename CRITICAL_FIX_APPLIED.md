# 🔧 CRITICAL FIX APPLIED - Session Ready State

**Date**: November 15, 2025 - 12:50 AM
**Fix**: Wait for tracks before calling speak()

---

## ❌ **Problem Identified**

From your logs:
```
📥 [HeyGenAPI] Task response status: 400
📥 [HeyGenAPI] Task response body: {"code":400006,"message":"Session is not in correct state"}
```

**Root Cause**: We were calling `speak()` immediately after LiveKit connected, but HeyGen's session backend was not fully initialized yet. The session needs to subscribe to both video AND audio tracks before it's ready to accept task requests.

**Timeline of events** (from logs):
1. ✅ Session created: `cad9453b-c1f7-11f0-ab0e-b61b803b494d`
2. ✅ Connected to LiveKit room
3. ❌ **IMMEDIATELY** tried to send opening message (TOO EARLY!)
4. ❌ Got 400 error: "Session is not in correct state"
5. ✅ Room fully connected (should have waited for this)

---

## ✅ **Solution Applied**

**Strategy**: Wait for both video and audio tracks to be subscribed (indicating session is fully ready) before sending any speak() commands.

### **Code Changes** (3 modifications):

#### 1. Added Tracking Flags
**File**: [HeyGenAvatarViewModel.swift](ios/Runner/HeyGen/HeyGenAvatarViewModel.swift:35-37)

```swift
// Track when session is ready for speak() calls
private var hasVideoTrack = false
private var hasAudioTrack = false
private var hasSentOpeningMessage = false
```

#### 2. Removed Premature speak() Call
**File**: [HeyGenAvatarViewModel.swift](ios/Runner/HeyGen/HeyGenAvatarViewModel.swift:127-129)

**Before**:
```swift
// Send opening message
try await speak(text: HeyGenConfig.AvatarSettings.openingMessage)
```

**After**:
```swift
// DON'T send opening message yet - wait for video/audio tracks to be ready
// Opening message will be sent from didSubscribeTrack callback
print("⏳ [HeyGenVM] Waiting for tracks to be ready before speaking...")
```

#### 3. Speak When Both Tracks Ready
**File**: [HeyGenAvatarViewModel.swift](ios/Runner/HeyGen/HeyGenAvatarViewModel.swift:204-235)

Added to `didSubscribeTrack` method:

```swift
func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
    Task { @MainActor in
        print("📹 [HeyGenVM] Track subscribed: \(publication.sid)")

        // If this is a video track, render it
        if let track = publication.track as? VideoTrack {
            hasVideoTrack = true
            setupVideoView(track: track)
            print("✅ [HeyGenVM] Video track ready")
        }

        // Audio tracks will automatically play through speakers/headphones
        if publication.track is AudioTrack {
            hasAudioTrack = true
            print("🔊 [HeyGenVM] Audio track available - should play automatically")
        }

        // Send opening message when BOTH tracks are ready
        if hasVideoTrack && hasAudioTrack && !hasSentOpeningMessage {
            hasSentOpeningMessage = true
            print("✅ [HeyGenVM] Both tracks ready - sending opening message")

            Task {
                do {
                    try await speak(text: HeyGenConfig.AvatarSettings.openingMessage)
                } catch {
                    print("❌ [HeyGenVM] Failed to send opening message: \(error)")
                }
            }
        }
    }
}
```

#### 4. Reset Flags on Session Stop
**File**: [HeyGenAvatarViewModel.swift](ios/Runner/HeyGen/HeyGenAvatarViewModel.swift:155-157)

```swift
// Clean up
session = nil
sessionToken = nil
isSessionActive = false
hasVideoTrack = false        // ADDED
hasAudioTrack = false        // ADDED
hasSentOpeningMessage = false // ADDED
```

---

## 🎯 **Expected New Flow**

### Before (Failed):
```
1. Session created ✅
2. LiveKit connected ✅
3. Immediately call speak() ❌ → 400 Error: "Session is not in correct state"
```

### After (Should Work):
```
1. Session created ✅
2. LiveKit connected ✅
3. Video track subscribed ✅ → hasVideoTrack = true
4. Audio track subscribed ✅ → hasAudioTrack = true
5. BOTH tracks ready → NOW call speak() ✅
6. Avatar speaks opening message ✅
7. Audio plays through headphones ✅
```

---

## 🔍 **What to Look For in Next Test**

### ✅ **Success Indicators**:
```
🚀 [HeyGenVM] Starting HeyGen session...
✅ [HeyGenVM] Session created: <session_id>
✅ [HeyGenVM] Connected to LiveKit room
⏳ [HeyGenVM] Waiting for tracks to be ready before speaking...
📹 [HeyGenVM] Track subscribed: <track_id>
✅ [HeyGenVM] Video track ready
📹 [HeyGenVM] Track subscribed: <track_id>
🔊 [HeyGenVM] Audio track available - should play automatically
✅ [HeyGenVM] Both tracks ready - sending opening message
💬 [HeyGenVM] Sending text to avatar: Hi! I'm Hera...
🌐 [HeyGenAPI] POST https://api.heygen.com/v1/streaming.task
📥 [HeyGenAPI] Task response status: 200  ← THIS IS THE KEY!
✅ [HeyGenVM] Text sent successfully
```

### ❌ **Failure (if still not ready)**:
```
...
✅ [HeyGenVM] Both tracks ready - sending opening message
📥 [HeyGenAPI] Task response status: 400
📥 [HeyGenAPI] Task response body: {"code":400006,"message":"..."}
```
If this happens, we may need to add a small delay (e.g., 500ms) after tracks are ready before calling speak().

---

## 🚀 **Next Steps**

### Rebuild in Xcode:
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Connect iPhone 12 via USB (ensure unlocked)
3. Click Stop ■ button, then Play ▶️ button
4. Toggle to Video + Voice mode
5. **Watch for the new log messages showing track subscription**

### Expected Timeline:
- Session creates: ~1 second
- LiveKit connects: ~2 seconds
- **Tracks subscribe: ~2-5 seconds** ← New wait period
- speak() called: ~5-8 seconds total
- Hera starts speaking: ~8-10 seconds

---

## 📝 **Technical Details**

**Why This Fix Works**:
1. HeyGen's Streaming API v1 uses WebRTC (via LiveKit) for media streaming
2. WebRTC sessions have multiple states: connecting → connected → tracks subscribed → ready
3. The session is only ready to accept task requests AFTER both video and audio tracks are fully subscribed
4. The `didSubscribeTrack` callback from LiveKit tells us exactly when each track is ready
5. Waiting for both tracks ensures the session backend has completed all initialization

**Alternative Approaches** (if this doesn't work):
1. Add a 500ms delay after both tracks are ready
2. Listen for a specific HeyGen event via data channel (e.g., "session_ready")
3. Use LiveKit room state changes instead of track subscription

---

**Status**: ✅ **Fix Applied - Ready to Test**

**Files Modified**:
- `ios/Runner/HeyGen/HeyGenAvatarViewModel.swift` (4 changes)

**Confidence Level**: High - This is a common race condition in WebRTC applications
