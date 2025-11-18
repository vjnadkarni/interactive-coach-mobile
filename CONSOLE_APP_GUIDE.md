# Using macOS Console.app - Simple Alternative to Xcode

## Why Console.app is Better

- **Simple, focused interface** - just shows logs, nothing else
- **Real-time filtering** - type "AppleTTS" and see ONLY those logs
- **No IDE complexity** - it's just a log viewer
- **Works with flutter run** - no need to use Xcode at all

---

## How to Use Console.app

### 1. Open Console.app
It should already be open. If not:
- Spotlight: Press `⌘ + Space`, type "Console", press Enter
- OR: Go to `/Applications/Utilities/Console.app`

### 2. Select Your iPhone in Sidebar
On the **left sidebar**, under **"Devices"**, click:
- **"Vijay's iPhone 12"** (your iPhone 12)

### 3. Set Up Filter (Critical!)
At the **top-right corner**, you'll see a search box. Type:
```
AppleTTSHandler
```

This will filter to show ONLY logs from our Swift code.

### 4. Start the App
In Terminal, run:
```bash
cd /Users/vijay/venv/interactive-coach-mobile
flutter run -d 00008101-001D44303C08801E
```

### 5. Watch Console.app While App Launches
You should see logs appear in real-time:
```
🎤 [AppleTTSHandler] Registered Apple TTS channel  ← App startup
```

### 6. Chat with Hera
When Hera responds, you should see:
```
🔊 [AppleTTSHandler] Speaking text (142 chars)
🎵 [AppleTTSHandler] Voice: com.apple.ttsbundle.Samantha-compact...
✅ [AppleTTSHandler] Audio session configured for Bluetooth/headphones  ← THIS!
✅ [AppleTTSHandler] Using voice: Samantha
✅ [AppleTTSHandler] Speech started
▶️ [AppleTTSHandler] Speech started
✅ [AppleTTSHandler] Speech finished
```

---

## What If Console.app Shows No Logs?

**Problem**: Console.app is open but no logs appear when app runs.

**Solution**: You might need to enable "Include Info Messages" and "Include Debug Messages":
1. At the top of Console.app, click the **"Action"** button (looks like 3 horizontal lines)
2. Enable checkboxes:
   - ✅ Include Info Messages
   - ✅ Include Debug Messages

---

## Comparison

| Xcode Console | Console.app |
|---------------|-------------|
| Complex IDE with 1000 buttons | Simple log viewer |
| Must run from Xcode | Works with `flutter run` |
| Hard to find the right panel | One window, that's it |
| Mixes build logs with runtime logs | Shows only runtime logs |
| **Difficult** | **Easy** |

---

## Expected Workflow

1. **Open Console.app** (already done)
2. **Select iPhone 12** in left sidebar
3. **Filter for "AppleTTSHandler"** in search box
4. **Run app**: `flutter run -d 00008101-001D44303C08801E`
5. **Chat with Hera**
6. **Copy logs** from Console.app and share

Much simpler than navigating Xcode!
