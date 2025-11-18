# How to View Xcode Runtime Console Logs

## Where Swift `print()` Statements Appear

The Swift runtime logs (from `AppleTTSHandler.swift`) appear in the **Debug Console** at the bottom of Xcode, NOT in the Issue Navigator.

---

## Step-by-Step Guide

### 1. Open Xcode
```bash
open /Users/vijay/venv/interactive-coach-mobile/ios/Runner.xcworkspace
```

### 2. Show the Debug Area (Console)
**Option A - Keyboard Shortcut:**
- Press: `⌘ + Shift + Y` (Command + Shift + Y)

**Option B - Menu:**
- Go to: **View → Debug Area → Activate Console**

**Option C - Toolbar Button:**
- At the **top-right corner** of Xcode window, look for 3 buttons
- Click the **middle button** (looks like a horizontal line with text below it)
- This toggles the Debug Area at the bottom

### 3. The Debug Console Will Appear
- **Location**: Bottom half of Xcode window
- **Look for**: A panel with tabs: "All Output", "Console Output", "Variables View"
- **Default Tab**: "All Output" (shows both Xcode and Swift logs)

### 4. Select Your Device
- **Top-left toolbar**: Click the device dropdown (next to "Runner" scheme)
- **Select**: "Vijay's iPhone 12" (your physical iPhone 12 device)

### 5. Run the App
- Click the **Play button** (▶️) at top-left of Xcode
- OR Press: `⌘ + R` (Command + R)

### 6. What You'll See in Console
When the app launches, you should see:
```
🎤 [AppleTTSHandler] Registered Apple TTS channel  ← At app startup
```

When you chat with Hera and she responds, you should see:
```
🔊 [AppleTTSHandler] Speaking text (142 chars)
🎵 [AppleTTSHandler] Voice: com.apple.ttsbundle.Samantha-compact, Rate: 0.5, Pitch: 1.0, Volume: 1.0
✅ [AppleTTSHandler] Audio session configured for Bluetooth/headphones  ← THIS IS CRITICAL!
✅ [AppleTTSHandler] Using voice: Samantha
✅ [AppleTTSHandler] Speech started
▶️ [AppleTTSHandler] Speech started
✅ [AppleTTSHandler] Speech finished
```

---

## Troubleshooting

### Console Not Showing?
1. Make sure Debug Area is visible (`⌘ + Shift + Y`)
2. Check the bottom-right corner buttons - click the one that looks like `[ = ]` (Show Console)

### Too Many Logs?
- At the top of the console, there's a **search/filter box**
- Type: `AppleTTSHandler` to filter only our logs
- OR Type: `Audio session` to see just the audio configuration logs

### Wrong Tab?
- Make sure you're on "All Output" tab (NOT "Variables View")
- The tabs are at the bottom of the Debug Area

---

## What We're Looking For

**CRITICAL LOG LINE:**
```
✅ [AppleTTSHandler] Audio session configured for Bluetooth/headphones
```

If this line appears → Audio routing is working, we need to investigate further
If this line is MISSING → Swift code is not executing, build system issue

---

## Screenshot Reference

The Debug Console looks like this:

```
┌─────────────────────────────────────────────────────────┐
│  Xcode Window                                           │
│  ┌───────────────────────────────────────────────────┐  │
│  │                                                     │  │
│  │         Your App Running on iPhone                 │  │
│  │                                                     │  │
│  └───────────────────────────────────────────────────┘  │
│  ════════════════════════════════════════════════════   │  ← Divider
│  DEBUG CONSOLE (Bottom Half)                            │
│  ┌───────────────────────────────────────────────────┐  │
│  │ All Output | Console Output | Variables View      │  │
│  ├───────────────────────────────────────────────────┤  │
│  │ 🎤 [AppleTTSHandler] Registered Apple TTS channel │  │
│  │ flutter: ✅ Found existing session                 │  │
│  │ 🔊 [AppleTTSHandler] Speaking text (142 chars)    │  │
│  │ ✅ [AppleTTSHandler] Audio session configured...  │  │ ← THIS!
│  │ ✅ [AppleTTSHandler] Speech started               │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## Alternative: Use Console.app

If Xcode console is overwhelming, you can also use macOS Console.app:

1. Open **Console.app** (from /Applications/Utilities/)
2. Select your **iPhone 12** in the left sidebar (under "Devices")
3. In the search box (top-right), type: `AppleTTSHandler`
4. Run the app from Xcode
5. Console.app will show ONLY AppleTTSHandler logs

---

## Next Steps After Viewing Logs

1. **Run the app from Xcode** (not `flutter run`)
2. **Chat with Hera** on your iPhone
3. **Copy the console output** that appears when Hera responds
4. **Share the logs** so we can see if audio session configuration is executing
