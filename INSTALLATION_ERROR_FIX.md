# Fix: "The device is passcode protected" Error

## Error Details
```
DTDKRemoteDeviceConnection: Failed to start remote service
"com.apple.mobile.notification_proxy" on device.
Error Domain=com.apple.dt.MobileDeviceErrorDomain Code=-402653158
"The device is passcode protected."
```

## Common Causes (Even When Device Is Unlocked)

### 1. Trust Relationship Not Established
**Most Common Cause**

When you connect your iPhone to your Mac, a "Trust This Computer?" prompt appears on the iPhone. If you haven't tapped "Trust" or if the trust relationship was broken, you'll get this error.

**Fix**:
1. Unplug iPhone from Mac
2. Plug it back in
3. **Look at your iPhone screen** - you should see "Trust This Computer?" popup
4. Tap **"Trust"**
5. Enter your iPhone passcode to confirm trust
6. Wait 5-10 seconds for pairing to complete
7. Try `flutter run` again

### 2. Developer Mode Not Enabled (iOS 16+)
**Required for iOS 16 and later**

Starting with iOS 16, Apple requires "Developer Mode" to be manually enabled before installing development apps.

**Check if enabled**:
1. On your iPhone, go to **Settings** → **Privacy & Security**
2. Scroll down to **Developer Mode**
3. If it says "Off", tap it and toggle it ON
4. iPhone will reboot
5. After reboot, confirm "Turn On Developer Mode" alert
6. Try `flutter run` again

**If you don't see Developer Mode option**:
- Your iOS version is < 16 (doesn't need this)
- Continue to next fix

### 3. Outdated Provisioning Profiles
Sometimes Xcode's cached provisioning profiles get corrupted.

**Fix**:
```bash
# Clear provisioning profiles
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*

# Clear Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Try again
flutter clean
flutter run -d 00008101-001D44303C08801E
```

### 4. Xcode Device Pairing Issue
Xcode may have lost pairing with your device.

**Fix in Xcode**:
1. Open Xcode
2. Go to **Window** → **Devices and Simulators** (or press `Cmd+Shift+2`)
3. Select your iPhone in left sidebar
4. Look at the status - should say "Connected"
5. If it says "Unavailable" or shows a warning icon:
   - Click the device
   - Click the **"-"** button at bottom to remove it
   - Unplug and replug your iPhone
   - It should re-appear with "Trust This Computer?" prompt
6. Try `flutter run` again

### 5. iOS Version Too New for Xcode
If your iPhone's iOS version is newer than your Xcode supports, you may get this error.

**Check versions**:
```bash
# Check Xcode version
xcodebuild -version

# Check iPhone iOS version (in Xcode Devices window or on iPhone: Settings → General → About)
```

If iPhone iOS is 17.x but Xcode is old (< 15.0), update Xcode from App Store.

### 6. Restart Services
Sometimes the communication services between Mac and iPhone get stuck.

**Fix**:
```bash
# Kill lockdown services
sudo pkill -9 lockdownd
sudo pkill -9 usbmuxd

# Restart them (macOS will auto-restart)
# Wait 10 seconds

# Unplug and replug iPhone
# Try flutter run again
```

## Diagnostic Steps (In Order)

**Step 1: Check Trust Status**
1. Unplug iPhone
2. Plug it back in
3. Look at iPhone screen for "Trust This Computer?" prompt
4. If you see it: Tap Trust, enter passcode
5. If you don't see it: Continue to Step 2

**Step 2: Check Developer Mode (iOS 16+)**
1. iPhone → Settings → Privacy & Security → Developer Mode
2. If OFF: Turn it ON and reboot iPhone
3. If option doesn't exist: Your iOS is < 16, continue to Step 3

**Step 3: Check Xcode Device Status**
1. Open Xcode
2. Window → Devices and Simulators
3. Select your iPhone
4. Status should say "Connected"
5. If not: Remove device and replug to re-pair

**Step 4: Try Flutter Run**
```bash
flutter clean
flutter run -d 00008101-001D44303C08801E --verbose
```

The `--verbose` flag will show more detailed error messages.

## Expected Success Output

When it works, you should see:
```
Launching lib/main.dart on iPhone 12 in debug mode...
Running Xcode build...
Xcode build done.                                           36.4s
Installing and launching...
✓ Built build/ios/iphoneos/Runner.app
Syncing files to device iPhone 12...
Flutter run key commands.
h List all available interactive commands.
c Clear the screen
q Quit (terminate the application on the device).

💬 An Observatory debugger and profiler on iPhone 12 is available at: http://127.0.0.1:...
The Flutter DevTools debugger and profiler on iPhone 12 is available at: http://127.0.0.1:...
```

## If None of This Works

Run this diagnostic command and share the output:
```bash
# Full diagnostic
system_profiler SPUSBDataType | grep -A 11 "iPhone"
instruments -s devices
xcodebuild -showsdks
```

This will show:
- USB connection status
- Device recognition by Xcode tools
- Available SDKs

---

**Most Likely Fix**: Check for "Trust This Computer?" prompt on your iPhone. This is the #1 cause of this error even when the device appears unlocked.
