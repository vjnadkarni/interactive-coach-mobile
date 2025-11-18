# Console.app Filters to Try

The "AppleTTSHandler" filter showed no logs, which means either:
1. The Swift code isn't executing
2. The logs are under a different process/category name

---

## Try These Filters (One at a Time)

In Console.app's search box at the top-right, try each of these:

### Filter 1: Just "Apple"
```
Apple
```

### Filter 2: Just "TTS"
```
TTS
```

### Filter 3: Process name "Runner"
```
process:Runner
```

### Filter 4: Subsystem filter
```
subsystem:com.iscoyd.galenogenie
```

### Filter 5: Remove filter entirely
```
(clear the search box - leave it empty)
```
Then look for **ANY** logs that appear when you chat with Hera.

---

## What to Look For

When you chat with Hera, look for:
- Any log lines containing "TTS", "speak", "audio", "AVSpeech"
- Any log lines with timestamps matching when you sent a message
- Log lines from process "Runner" (that's our app)

---

## Alternative: Check if chat_screen.dart is even calling AppleTTS

Before we spend more time on Console.app, let's verify the Dart code is trying to call AppleTTS.

**In Console.app, try this filter:**
```
[AppleTTS]
```

This will show Dart-side AppleTTS logs (which ARE appearing in Flutter terminal).

If you see:
```
flutter: 🔊 [AppleTTS] Speaking: "..."
flutter: ✅ [AppleTTS] Speech started successfully
```

But NO corresponding Swift logs (`[AppleTTSHandler]`), it means:
- Dart is calling the method channel
- Swift is NOT receiving the call
- Plugin registration is broken
