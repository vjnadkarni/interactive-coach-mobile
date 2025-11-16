# kill-sessions.sh - Usage Guide

## Purpose
This script helps you clean up all running processes related to the Galeno Genie mobile app to prevent accidental HeyGen credit consumption from lingering sessions.

## When to Use
- After stopping a development session
- When you see HeyGen credits being consumed unexpectedly
- After force-closing Xcode or Flutter
- Before checking out or switching git branches
- At the end of the workday to ensure everything is shut down

## Usage

### Simple Usage
From the `interactive-coach-mobile` directory:
```bash
./kill-sessions.sh
```

The script will:
1. ✅ Find and kill Flutter processes (with confirmation)
2. ✅ Find and kill Dart processes (with confirmation)
3. ✅ Find and kill iOS device logging processes
4. ✅ Find and kill iproxy processes
5. ⚠️  Remind you to force-close the app on iPhone
6. 🔍 Optionally kill Next.js dev server (port 3000)
7. 🔍 Optionally kill FastAPI backend (port 8000)
8. ✅ Verify all processes terminated
9. 📋 Remind you to check HeyGen dashboard

### Interactive Prompts
The script asks for confirmation before killing each type of process:
- **Press `y` + Enter** to kill the processes
- **Press `n` + Enter** (or just Enter) to skip

### Example Session
```
═══════════════════════════════════════════════════════════
  Galeno Genie - Session Termination Tool
═══════════════════════════════════════════════════════════

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Checking Flutter processes...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Found flutter run processes:
vijay  12345  ... flutter run -d 00008101-001D44303C08801E

Kill these processes? [y/N]: y
✅ Killed flutter run processes
```

## What Gets Killed

### Always Checked (with confirmation):
- **Flutter processes** - `flutter run` commands
- **Dart processes** - Dart VM and compiler processes
- **idevicesyslog** - iOS device logging
- **iproxy** - iOS port forwarding

### Optionally Killed:
- **Next.js dev server** (port 3000) - Only if you want to stop the web app
- **FastAPI backend** (port 8000) - Only if you want to stop the API server

### Manual Actions Required:
- **Force-close app on iPhone** - Swipe up → Swipe away "Galeno Genie"
- **Check HeyGen dashboard** - Visit https://app.heygen.com/ to verify no active sessions

## HeyGen Session Verification

After running the script, **always verify** no HeyGen sessions are active:

1. Visit: https://app.heygen.com/
2. Login with your account
3. Check the dashboard for any active "Streaming Avatar" sessions
4. If any are listed, click "Stop" or "Terminate"

**Note:** Sessions should auto-terminate when the app closes, but manual verification ensures no credits are wasted.

## Tips

### Quick Cleanup at End of Day
```bash
# Kill everything (answer 'y' to all prompts)
./kill-sessions.sh
```

### Keep Backend Running
If you're only stopping the mobile app but want to keep the backend running for web development:
```bash
./kill-sessions.sh
# Answer 'y' to Flutter/Dart processes
# Answer 'n' to backend server (port 8000)
```

### Kill All Development Servers
To completely stop all development:
```bash
./kill-sessions.sh
# Answer 'y' to everything
```

## Troubleshooting

### "Permission denied" error
Make the script executable:
```bash
chmod +x kill-sessions.sh
```

### Processes won't die
Some processes might require `sudo`:
```bash
sudo ./kill-sessions.sh
```

### "No such file or directory"
Make sure you're in the `interactive-coach-mobile` directory:
```bash
cd /Users/vijay/venv/interactive-coach-mobile
./kill-sessions.sh
```

### HeyGen session still active
If the HeyGen dashboard shows an active session after running the script:
1. Force-close the app on iPhone (swipe up → swipe away)
2. Wait 30-60 seconds for the session to timeout
3. Manually terminate it from the HeyGen dashboard if it persists

## Safety Features

- ✅ **Interactive confirmation** - Asks before killing each process type
- ✅ **Process preview** - Shows which processes will be killed
- ✅ **Verification step** - Confirms all processes terminated
- ✅ **HeyGen reminder** - Reminds you to check the dashboard
- ✅ **Safe defaults** - Pressing Enter skips (doesn't kill)

## What This Script Does NOT Do

- ❌ Does not automatically close the app on iPhone (manual step required)
- ❌ Does not terminate HeyGen sessions via API (manual dashboard check required)
- ❌ Does not clean up Xcode build artifacts (use `flutter clean` for that)
- ❌ Does not modify any code or git state

---

**Created:** November 16, 2025
**Location:** `/Users/vijay/venv/interactive-coach-mobile/kill-sessions.sh`
**Git branch:** `wip`
