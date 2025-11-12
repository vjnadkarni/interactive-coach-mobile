# Deepgram STT Integration Complete

**Date**: November 11, 2025
**Status**: ✅ **READY FOR TESTING**
**Branch**: `wip`
**Checkpoint**: `checkpoint-before-deepgram` (tag for rollback if needed)

---

## What Changed

Successfully replaced iOS native Speech-to-Text with Deepgram's cloud-based STT service to achieve **excellent punctuation and capitalization** matching the web application's quality.

---

## Files Created

1. **`lib/services/deepgram_service.dart`** (220 lines)
   - WebSocket connection to Deepgram API
   - Real-time audio streaming from microphone
   - Interim and final transcript handling
   - Auto-reconnect on disconnection
   - Proper cleanup and disposal

---

## Files Modified

1. **`pubspec.yaml`**
   - Uncommented `web_socket_channel: ^3.0.1` (WebSocket support)
   - Added `record: ^5.1.0` (microphone audio capture)

2. **`lib/screens/chat_screen.dart`** (Voice-Only mode)
   - Replaced iOS native STT with DeepgramService
   - Added interim transcript display (live feedback)
   - Added 3-second silence timer for automatic send
   - Stream-based transcript handling

3. **`lib/screens/avatar_screen.dart`** (Video+Voice mode)
   - Replaced iOS native STT with DeepgramService
   - Added interim transcript handling
   - Added 3-second silence timer
   - Stream-based transcript handling

---

## How Deepgram Works

### Connection Flow
```
1. App starts → DeepgramService.connect()
2. WebSocket opens to wss://api.deepgram.com/v1/listen
3. Parameters: nova-2 model, smart_format=true, punctuate=true
4. User taps mic → startRecording()
5. Audio streams in real-time (PCM 16-bit, 16kHz, mono)
6. Deepgram returns interim results → display to user
7. Deepgram returns final result → send to backend
8. 3-second silence → auto-submit transcript
```

### Audio Configuration
- **Format**: PCM 16-bit linear encoding
- **Sample Rate**: 16kHz
- **Channels**: Mono (1 channel)
- **Streaming**: Real-time audio chunks sent to Deepgram

### Deepgram Parameters
- **model**: nova-2 (latest, best accuracy)
- **language**: en-US
- **smart_format**: true (automatic punctuation, capitalization, formatting)
- **punctuate**: true (add periods, commas, question marks, exclamation marks)
- **interim_results**: true (live feedback as user speaks)
- **encoding**: linear16
- **sample_rate**: 16000
- **channels**: 1

---

## New Dependencies Required

Run this command before testing:
```bash
cd /Users/vijay/venv/interactive-coach-mobile
flutter pub get
```

This will install:
- `web_socket_channel: ^3.0.1`
- `record: ^5.1.0`

---

## Testing Instructions

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Deploy to iPhone 12
```bash
flutter run --release
```

### 3. Test Voice-Only Mode
1. Open app → Chat screen (Voice-Only mode)
2. Tap microphone button
3. Speak a question with natural pauses
4. **Expected**: See interim transcript display in real-time
5. **Expected**: After 3 seconds of silence OR final result, message auto-submits
6. **Expected**: Full punctuation and capitalization in transcript

### 4. Test Video+Voice Mode
1. Toggle switch to "Video + Voice" mode
2. Wait for Hera's avatar to load
3. Tap microphone button
4. Speak a question
5. **Expected**: Hera speaks response after transcription

### 5. Test Punctuation Quality
- **Test questions**:
  - "What is HIIT training?" (expect: "What is HIIT training?")
  - "I want to lose 10 lbs in 2 months" (expect: "I want to lose 10 lbs in 2 months.")
  - "Tell me about recovery why is it important" (expect: "Tell me about recovery. Why is it important?")

---

## Expected Results

### ✅ Success Criteria
- Interim transcripts display in real-time as user speaks
- Final transcripts have complete punctuation (periods, commas, question marks)
- Sentence boundaries detected automatically
- Capitalization correct at sentence starts
- Microphone button toggles on/off smoothly
- 3-second silence auto-submits transcript
- Transcripts match quality of web application

### ⚠️ Potential Issues

1. **"Deepgram not available" error**
   - Check internet connection
   - Verify Deepgram API key in `.env` file
   - Check backend logs for WebSocket connection errors

2. **No audio streaming**
   - Check microphone permissions (iOS Settings → Privacy → Microphone → Galeno Genie)
   - Verify `record` package installed correctly

3. **Poor transcription quality**
   - Check audio quality (background noise)
   - Verify Deepgram parameters (smart_format=true, punctuate=true)

4. **Timeouts or disconnects**
   - Deepgram auto-reconnects up to 3 times
   - Check console logs for reconnection attempts

---

## Rollback Instructions

If Deepgram integration has issues, rollback to previous working version:

```bash
git checkout checkpoint-before-deepgram
flutter pub get
flutter run --release
```

This restores the previous iOS native STT implementation.

---

## Comparison: iOS Native vs Deepgram

### iOS Native Speech Recognition
- ❌ Punctuation: Very poor, inconsistent
- ❌ Sentence boundaries: Not detected
- ❌ Question marks: Missing for questions
- ✅ On-device processing (no internet required)
- ✅ Fast (low latency)

### Deepgram STT
- ✅ Punctuation: Excellent, consistent
- ✅ Sentence boundaries: Accurately detected
- ✅ Question marks: Correctly added for questions
- ✅ Capitalization: Proper sentence capitalization
- ⚠️ Requires internet connection
- ⚠️ Slightly higher latency (~200-500ms)

---

## Environment Variables

Required in `.env` file:
```
DEEPGRAM_API_KEY=577cc1a38d9330a05aeafd428fdda612f3fe0ac4
```

Already present and verified ✅

---

## Next Steps

1. Test on iPhone 12 physical device
2. Verify punctuation quality matches web app
3. Test sustained conversations (multiple queries)
4. Test both Voice-Only and Video+Voice modes
5. Verify 3-second silence timer works correctly
6. Check for any audio recording permission issues

---

## Notes

- Deepgram connection established at app startup (not per-query)
- WebSocket stays open for entire session (reduces latency)
- Audio streaming happens in real-time (not batch processing)
- Interim results provide live feedback to user
- Final results trigger message submission
- Silence timer provides fallback if no final result received

---

## Support

If issues arise:
1. Check Flutter console logs for Deepgram connection status
2. Verify microphone permissions in iOS Settings
3. Test internet connectivity
4. Review Deepgram API usage dashboard (check quota limits)
5. Fallback to checkpoint-before-deepgram if needed
