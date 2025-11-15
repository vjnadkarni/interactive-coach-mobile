# Quick Start: HeyGen Native iOS Implementation

**Goal**: Get Video + Voice mode working on iOS with audio playback

**Time Required**: 20-30 minutes

---

## Prerequisites

- [x] Code has been written (all Swift and Flutter files created)
- [x] AppDelegate updated to register platform view
- [ ] Xcode installed and working
- [ ] Physical iPhone connected to Mac
- [ ] HeyGen API key in `.env` file

---

## 4-Step Implementation

### Step 1: Open Project in Xcode (2 min)

```bash
cd /Users/vijay/venv/interactive-coach-mobile/ios
open Runner.xcworkspace  # NOT Runner.xcodeproj!
```

⚠️ **IMPORTANT**: Must open `.xcworkspace` (not `.xcodeproj`) for CocoaPods projects

---

### Step 2: Add LiveKit Package (5 min)

**In Xcode**:

1. Select **Runner** project (blue icon) in left sidebar
2. Select **Runner** target under TARGETS
3. Click **"+"** button at bottom of "Frameworks, Libraries, and Embedded Content"
4. Click **"Add Other..." → "Add Package Dependency..."**
5. Paste URL: `https://github.com/livekit/client-sdk-swift`
6. Dependency Rule: **"Up to Next Major Version"** with `2.0.0`
7. Click **"Add Package"**
8. Wait for package to download (1-2 minutes)
9. Select **LiveKit** in package products list
10. Click **"Add Package"**

**Verification**: In Project Navigator, you should see "Package Dependencies" → "client-sdk-swift"

---

### Step 3: Uncomment LiveKit Code (2 min)

**In Xcode**, open `Runner/HeyGen/HeyGenAvatarViewModel.swift`:

1. **Line 12**: Uncomment `// import LiveKit` → `import LiveKit`

2. **Lines 52-56**: Uncomment this block:
   ```swift
   /*
   room = Room()
   room?.add(delegate: self)
   try await room?.connect(url: sessionData.url, token: sessionData.accessToken)
   */
   ```

3. **Lines 135-271**: Uncomment the entire `extension HeyGenAvatarViewModel: RoomDelegate` section
   - Find `/* extension HeyGenAvatarViewModel: RoomDelegate {`
   - Delete `/*` at start and `*/` at end

4. **Build to verify**: Press **Cmd+B** (should compile without errors)

---

### Step 4: Update Flutter Navigation (1 min)

**Option A**: Test in isolation first

Edit `lib/main.dart`, add import at top:
```dart
import 'screens/avatar_screen_native.dart';
```

Find navigation to `AvatarScreen` and change to:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const AvatarScreenNative()),
);
```

**Option B**: Add menu option for testing

Add a button to switch between WebView and Native implementations for A/B testing.

---

## Deploy and Test (10 min)

### Build

```bash
cd /Users/vijay/venv/interactive-coach-mobile
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

**Select your physical iPhone when prompted**

### Test Checklist

Open app → Navigate to Video + Voice mode:

- [ ] No "Video mode unavailable" dialog (should go straight to avatar screen)
- [ ] Tap "Start" button (top right)
- [ ] Loading indicator appears
- [ ] Hera's avatar loads (video fills top half of screen)
- [ ] Status shows "Session active - Ready to chat"
- [ ] Tap microphone button (bottom)
- [ ] Speak: "Hi Hera, what is metabolic flexibility?"
- [ ] Transcript appears in real-time as you speak
- [ ] After 3.5s silence, transcript sent to backend
- [ ] Response appears in chat window
- [ ] **CRITICAL**: Hera's lips move AND you hear audio 🔊
- [ ] Audio plays clearly (test with headphones, then speaker)
- [ ] Microphone re-activates automatically after Hera finishes
- [ ] Continue conversation (multiple exchanges work)
- [ ] Tap "End Session" button
- [ ] Avatar stops, session ends cleanly

**✅ SUCCESS**: If you hear Hera's voice, the implementation works!

---

## Troubleshooting

### Build Error: "No such module 'LiveKit'"

**Solution**: LiveKit package not installed correctly

1. Xcode → File → Packages → Reset Package Caches
2. Clean: Cmd+Shift+K
3. Rebuild: Cmd+B
4. Verify "Package Dependencies" shows "client-sdk-swift"

### App Crashes on "Start"

**Check**:
1. HeyGen API key in `.env` file is correct
2. Internet connection working
3. Xcode Console for crash logs
4. Info.plist has `NSMicrophoneUsageDescription`

### Video Loads But No Audio

**Very unlikely** with native implementation, but if it happens:

1. Check Bluetooth headphones disconnected (test with wired or iPhone speaker first)
2. Check iOS Settings → Privacy → Microphone → Interactive Coach → Enabled
3. Restart app
4. Check Xcode Console for audio session logs

### HeyGen Session Fails to Start

**Check**:
1. API key valid (test on https://labs.heygen.com/interactive-avatar)
2. Network connectivity (try Safari)
3. HeyGen service status (check their status page)

---

## Expected Console Output

When working correctly, you should see:

```
🚀 [HeyGenVM] Starting HeyGen session...
✅ [HeyGenVM] Session created: <session-id>
✅ [HeyGenVM] Session started
✅ [HeyGenVM] Token created
🔌 [HeyGenVM] Connection state: connected
📹 [HeyGenVM] Track subscribed: <track-id>
🔊 [HeyGenVM] Audio track available - should play automatically
✅ [HeyGenVM] Video view configured
📞 [AvatarScreenNative] Received native call: onSessionStarted
💬 [HeyGenVM] Sending text to avatar: Hi! I'm Hera...
✅ [HeyGenVM] Text sent successfully
```

---

## Success Metrics

**Primary**:
- ✅ Audio plays from Hera (hear her voice)

**Secondary**:
- ✅ Video displays smoothly
- ✅ Lip-sync matches audio
- ✅ Speech recognition works
- ✅ Backend responses arrive
- ✅ Multiple conversation exchanges work
- ✅ Session termination clean

---

## If Everything Works

**Congratulations!** 🎉

Video + Voice mode is now fully functional on iOS mobile!

**Next Steps**:
1. Test edge cases (poor network, background/foreground, etc.)
2. Update user-facing documentation
3. Remove WebView redirect dialog
4. Deploy to TestFlight for beta testing
5. Consider Android implementation (LiveKit supports it)

---

## If Issues Persist

**Fallback**: Re-enable WebView redirect dialog temporarily

Edit `lib/screens/avatar_screen.dart` - restore the dialog that redirects to Voice-Only mode.

**Debug**: Share Xcode Console logs for analysis

**Contact**: HeyGen support (support@heygen.com) if HeyGen API issues

---

## Files Modified Summary

**Swift** (all in `ios/Runner/HeyGen/`):
- HeyGenConfig.swift (created)
- HeyGenAPIModels.swift (created)
- HeyGenAPI.swift (created)
- HeyGenAvatarViewController.swift (created)
- HeyGenAvatarViewModel.swift (created)

**Swift** (modified):
- AppDelegate.swift (added platform view registration)

**Flutter**:
- avatar_screen_native.dart (created)
- main.dart (navigation update - manual step)

**Total Lines of Code**: ~1,400 lines

---

**Ready to start? Follow Step 1 above!**
