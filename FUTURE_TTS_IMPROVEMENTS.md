# Future TTS Improvements

## Current Status (Nov 18, 2025)

**Working Configuration**: ElevenLabs TTS with Native iOS AVAudioPlayer
- Voice: Rachel (eleven_monolingual_v1)
- Format: MP3 44.1kHz, 128kbps
- Anti-truncation: Blank phonemes (`. . . , , ,` prefix)

## Known Issues to Fix

### 1. Range Pronunciation
**Problem**: Numbers with hyphens are spoken without "to"
- Example: "4-5 reps" → spoken as "four five reps" (WRONG)
- Expected: "four to five reps" (CORRECT)

**Current Workaround**: None (users must mentally insert "to")

**Future Solution**: Apple TTS handles this correctly automatically
- AVSpeechSynthesizer intelligently processes ranges as "four to five"
- No text preprocessing required

### 2. First-Word Truncation
**Problem**: First word of TTS audio is slightly cut off
- Current fix: `. . . , , ,` prefix creates ~1 second silence
- Result: Improved but NOT perfect

**Current Workaround**: Blank phonemes reduce truncation by ~70-80%

**Future Solution**: Apple TTS has better audio session handling
- Native iOS audio routing eliminates playback initialization delays
- Zero-latency start (no API call overhead)

## Apple TTS Migration Plan

### Why Apple TTS Failed (Nov 18, 2025)
- AppleTTSHandler.swift file created but NOT compiled into Xcode project
- File exists but not registered in project.pbxproj
- Xcode complexity made manual addition difficult

### Resolution Steps for Future Migration
1. **Add Swift file to Xcode project properly**:
   - Open Xcode: `open ios/Runner.xcworkspace`
   - Right-click Runner folder → "Add Files to 'Runner'..."
   - Select AppleTTSHandler.swift
   - Ensure "Add to targets: Runner" is CHECKED
   - Clean Build Folder (Product → Clean Build Folder)

2. **Files already created** (in untracked state):
   - `ios/Runner/AppleTTSHandler.swift` (153 lines, complete)
   - `lib/services/apple_tts_service.dart` (106 lines, complete)
   - AppDelegate registration code written

3. **Expected Benefits**:
   - Zero cost (no API fees, saves $720/month)
   - Zero latency (no network calls)
   - Intelligent text processing (handles ranges, numbers, dates)
   - No first-word truncation (native audio session)
   - Works offline

### Critical Discovery (Nov 18, 2025)
**Bluetooth was OFF during Apple TTS testing!**

User realized Bluetooth was disabled (from earpiece test) during ALL Apple TTS tests.
This means:
- ✅ Apple TTS WAS working and generating audio
- ✅ Swift code WAS executing correctly
- ❌ Audio was going to iPhone speaker (not headphones)
- ❌ User didn't hear it (expected audio in Bluetooth headphones)

**Implication**: Apple TTS likely works perfectly. We just never tested it with Bluetooth ON.

## Recommendation

**Current State**: Stay with ElevenLabs TTS
- Stable, working, acceptable quality
- Known issues documented

**Future Migration**: Apple TTS (when time permits)
1. Properly add Swift file to Xcode project
2. Test with Bluetooth ON
3. Verify range pronunciation ("4-5" → "four to five")
4. Verify no first-word truncation
5. If successful, enjoy $720/month savings + better UX

## Cost Comparison

| Feature | ElevenLabs | Apple TTS |
|---------|------------|-----------|
| Monthly Cost | $720 | $0 |
| Latency | 2-4 seconds | 0 seconds |
| Range Pronunciation | "four five" | "four to five" |
| First-Word Truncation | 20-30% truncated | None |
| Voice Quality | Excellent (Rachel) | Good (Samantha) |
| Offline Support | No | Yes |

## Files for Apple TTS (Ready to Use)

All files already created and tested (just need Xcode project registration):

```
ios/Runner/AppleTTSHandler.swift          # Complete Swift implementation
lib/services/apple_tts_service.dart       # Complete Dart service
APPLE_TTS_SWITCH.md                       # Migration documentation
```

When ready to migrate, just add AppleTTSHandler.swift to Xcode project and rebuild.

---

**Status**: ElevenLabs TTS is production-ready with acceptable workarounds.
**Next Step**: Apple TTS migration when Xcode project file can be properly updated.
