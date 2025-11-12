# Flutter Development Best Practices - Preventing Zombie Processes

## The Problem

Running `flutter run` in background mode (`run_in_background: true`) causes processes to persist indefinitely, even after the app stops or you exit the session. This creates "zombie" processes that:
- Consume system resources (CPU, memory)
- Interfere with subsequent Flutter runs
- Block ports and device connections
- Require manual cleanup with `kill -9`

**This is completely unacceptable for a smooth development workflow.**

---

## The Solution: User-Controlled Flutter Execution

**Golden Rule**: Always run Flutter commands manually in your own terminal, never in background mode through automation tools.

### Step 1: Open Terminal in Mobile Project Directory

```bash
cd /Users/vijay/venv/interactive-coach-mobile
```

### Step 2: Start Flutter App on iPhone

```bash
flutter run
```

This will:
- Build the app
- Deploy to connected iPhone 12
- Start hot reload server
- Show interactive terminal with key commands

### Step 3: Use Flutter's Built-in Key Commands

While `flutter run` is active, you have full control:

- **r** - Hot reload (reloads code changes without restarting)
- **R** - Hot restart (restarts entire app, clears state)
- **h** - List all available key commands
- **d** - Detach (keeps app running but exits Flutter terminal)
- **q** - Quit (stops app and exits)

### Step 4: Making Code Changes

1. Edit files in VS Code or your preferred editor
2. Save files
3. Press **r** in Flutter terminal for hot reload
4. If hot reload doesn't work, press **R** for hot restart
5. If major changes (like new dependencies), press **q** then `flutter run` again

### Step 5: Ending Session

**Always use 'q' to quit Flutter properly:**

```bash
# In Flutter terminal, press:
q
```

**Never use Ctrl+C or kill commands** - this leaves processes orphaned.

---

## How to Verify No Zombie Processes

After quitting Flutter, verify clean shutdown:

```bash
ps aux | grep -E "(flutter|dart)" | grep -v grep
```

**Expected**: No output (empty)
**Problem**: If you see processes, they're zombies

---

## How to Clean Up Zombie Processes (Emergency Only)

If you accidentally create zombie processes:

```bash
# Kill all Flutter/Dart processes
pkill -9 -f 'flutter|dart'

# Verify they're gone
ps aux | grep -E "(flutter|dart)" | grep -v grep
```

**But remember**: Prevention is better than cleanup!

---

## Why Background Execution Was a Bad Idea

The previous workflow used `run_in_background: true` which:
- ❌ Started Flutter processes that never terminated
- ❌ Created 17+ zombie processes in one session
- ❌ Required manual cleanup every time
- ❌ Caused device connection conflicts
- ❌ Made debugging harder (split console output)

The new workflow with manual execution:
- ✅ Single clean process you control
- ✅ Interactive terminal with hot reload
- ✅ Proper cleanup when you press 'q'
- ✅ Clear console output in one place
- ✅ No zombie processes

---

## Typical Development Workflow

### Morning: Start Development Session

```bash
# Terminal 1 - Mobile App
cd /Users/vijay/venv/interactive-coach-mobile
flutter run

# Terminal 2 - Backend (if needed)
cd /Users/vijay/venv/interactive-coach/backend
source ../venv/bin/activate
python -m uvicorn main:app --reload --host 0.0.0.0
```

### During Development: Iterative Changes

1. Edit `chat_screen.dart` in VS Code
2. Save file
3. Switch to Flutter terminal
4. Press **r** (hot reload)
5. Test changes on iPhone
6. Repeat

### End of Day: Clean Shutdown

```bash
# Terminal 1 (Flutter) - press 'q'
q

# Terminal 2 (Backend) - Ctrl+C
^C
```

---

## Special Cases

### Installing New Dependencies

When adding packages to `pubspec.yaml`:

```bash
# 1. Quit Flutter if running
q

# 2. Get new dependencies
flutter pub get

# 3. Restart Flutter
flutter run
```

### Debugging Build Issues

If you see errors or app won't start:

```bash
# Clean build artifacts
flutter clean

# Rebuild
flutter run
```

### Checking Device Connection

```bash
# List connected devices
flutter devices

# Expected output:
# iPhone 12 (mobile) • <device-id> • ios • iOS 16.x
```

---

## Summary

**DO**:
- ✅ Run `flutter run` manually in your own terminal
- ✅ Use **r** for hot reload during development
- ✅ Use **q** to quit Flutter cleanly
- ✅ Keep Flutter terminal visible for key commands
- ✅ Verify no zombies with `ps aux | grep flutter`

**DON'T**:
- ❌ Run Flutter in background mode
- ❌ Use Ctrl+C to exit (use 'q' instead)
- ❌ Start multiple Flutter instances simultaneously
- ❌ Leave Flutter running when switching projects
- ❌ Ignore zombie process warnings

---

## Benefits of This Approach

1. **No Zombie Processes**: Proper cleanup on exit
2. **Faster Iteration**: Hot reload with single keypress
3. **Better Debugging**: All logs in one terminal
4. **Resource Efficiency**: Only one Flutter process
5. **User Control**: You decide when to start/stop
6. **Professional Workflow**: Industry-standard practice

---

## Reference: Flutter Key Commands

```
Key Commands:
r - Hot reload
R - Hot restart
h - List all commands
d - Detach (keep app running)
c - Clear the screen
q - Quit (stop app)
s - Screenshot
w - Dump widget hierarchy
t - Dump rendering tree
L - Dump layer tree
S - Dump accessibility tree
U - Dump semantics tree
i - Toggle widget inspector
p - Toggle performance overlay
P - Toggle platform (iOS/Android)
o - Toggle platform brightness
z - Toggle construction lines
```

Most useful: **r** (hot reload) and **q** (quit)
