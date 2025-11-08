# HealthKit Observer Setup Guide

## Overview

This guide explains how to enable **real-time health data notifications** using Apple's `HKObserverQuery` API. This replaces the current 5-minute polling timer with **event-driven updates** (1-3 second latency).

---

## Current Implementation (Temporary)

**Status**: ✅ Working with 5-minute polling timer
**Latency**: 0-5 minutes
**File**: `lib/screens/health_dashboard_screen.dart`

The app currently uses a `Timer.periodic` that fetches data from HealthKit every 5 minutes:

```dart
void _startAutoRefresh() {
  _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
    print('🔄 Auto-refresh triggered (5-minute timer)');
    _loadDashboardData();
  });
}
```

**Pros**:
- Simple implementation
- No special configuration required
- Works reliably

**Cons**:
- Data can be up to 5 minutes old
- Wastes battery (polls even when no new data)
- Timestamp shows "8 m ago", "13 m ago", etc.

---

## Permanent Solution (Observer-Based)

**Status**: ⏳ Code implemented, entitlements needed
**Latency**: 1-3 seconds
**File**: `lib/services/health_observer_service.dart`

The observer implementation uses `health_kit_reporter` package to receive **immediate notifications** when Apple Watch writes new health data.

**Pros**:
- ✅ Real-time updates (1-3 second latency)
- ✅ Better battery life (event-driven vs polling)
- ✅ Timestamps always show "< 1 m ago"
- ✅ Works even when app is backgrounded
- ✅ Auto-syncs to backend within seconds

**Cons**:
- ❌ Requires manual Xcode entitlement configuration (one-time setup)

---

## ⚠️ Current Error

When trying to enable background delivery, the app fails with:

```
PlatformException(EnableBackgroundDelivery, Error in enableBackgroundDelivery,
Optional(Error Domain=com.apple.healthkit Code=4
"Missing com.apple.developer.healthkit.background-delivery entitlement."
UserInfo={NSLocalizedDescription=Missing com.apple.developer.healthkit.background-delivery entitlement.}), null)
```

**Root Cause**: The Xcode project is missing the **HealthKit Background Delivery** entitlement.

---

## 🔧 How to Fix (Manual Xcode Steps)

### Step 1: Open Xcode Project

```bash
cd /Users/vijay/venv/interactive-coach-mobile
open ios/Runner.xcworkspace
```

**Important**: Open `.xcworkspace`, NOT `.xcodeproj` (CocoaPods requirement)

### Step 2: Select Runner Target

1. In Xcode, click on **"Runner"** in the left sidebar (project navigator)
2. Make sure **"Runner"** target is selected (not the project)
3. Click on the **"Signing & Capabilities"** tab at the top

### Step 3: Add HealthKit Capability

1. Click the **"+ Capability"** button (top left of the tab)
2. Type **"HealthKit"** in the search box
3. Double-click **"HealthKit"** to add it

You should see a new "HealthKit" section appear with two checkboxes:
- ☐ Clinical Health Records
- ☑ **Background Delivery** ← ENABLE THIS!

**Important**: Make sure the **"Background Delivery"** checkbox is **CHECKED**.

### Step 4: Verify Entitlements File

Xcode should automatically create/update:
```
ios/Runner/Runner.entitlements
```

Open this file and verify it contains:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.healthkit</key>
    <true/>
    <key>com.apple.developer.healthkit.background-delivery</key>
    <true/>
</dict>
</plist>
```

### Step 5: Update health_dashboard_screen.dart

Once entitlements are configured, switch from polling to observers:

**Find this code** (lines 50-73):

```dart
// Auto-refresh timer (temporary polling until entitlements are configured)
Timer? _autoRefreshTimer;

@override
void initState() {
  super.initState();
  _loadDashboardData();
  _startAutoRefresh();
}

@override
void dispose() {
  _autoRefreshTimer?.cancel();
  super.dispose();
}

/// Start automatic refresh every 5 minutes
/// TODO: Replace with observer-based updates once HealthKit entitlements are configured
void _startAutoRefresh() {
  _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
    print('🔄 Auto-refresh triggered (5-minute timer)');
    _loadDashboardData();
  });
}
```

**Replace with** (observer-based):

```dart
@override
void initState() {
  super.initState();
  _loadDashboardData();
  _startObservers();
}

@override
void dispose() {
  _observerService.stopAllObservers();
  super.dispose();
}

/// Start HealthKit observers for real-time notifications
Future<void> _startObservers() async {
  print('🔔 Starting HealthKit observers for real-time updates...');

  await _observerService.startObservingAllVitals(
    onHeartRate: (VitalReading hrReading) async {
      print('🔔 [Dashboard] NEW HR: ${hrReading.value.round()} BPM');
      setState(() {
        _heartRate = hrReading.value.round();
        _vitalsTimestamp = hrReading.timestamp;
      });

      // Immediately sync to backend
      await _syncService.syncAllHealthData();
      setState(() {
        _lastSync = DateTime.now();
      });
    },
    onHRV: (VitalReading hrvReading) async {
      print('🔔 [Dashboard] NEW HRV: ${hrvReading.value.round()} ms');
      setState(() {
        _hrv = hrvReading.value.round();
      });

      // Sync to backend
      await _syncService.syncAllHealthData();
      setState(() {
        _lastSync = DateTime.now();
      });
    },
    onSpO2: (VitalReading spo2Reading) async {
      print('🔔 [Dashboard] NEW SpO2: ${spo2Reading.value.round()}%');
      setState(() {
        _spo2 = spo2Reading.value.round();
      });

      // Sync to backend
      await _syncService.syncAllHealthData();
      setState(() {
        _lastSync = DateTime.now();
      });
    },
  );

  print('✅ All HealthKit observers started - awaiting real-time updates');
}
```

### Step 6: Rebuild and Test

```bash
flutter run
```

Navigate to Health Dashboard and check logs for:

```
✅ [HealthObserver] Background delivery enabled for heart rate
✅ [HealthObserver] Heart rate observer started
✅ [HealthObserver] Background delivery enabled for HRV
✅ [HealthObserver] HRV observer started
✅ [HealthObserver] Background delivery enabled for SpO2
✅ [HealthObserver] SpO2 observer started
✅ All HealthKit observers started - awaiting real-time updates
```

**No more errors!**

### Step 7: Trigger Apple Watch Measurement

To test real-time notifications:

1. Open **Breathe app** on Apple Watch (triggers active HR monitoring)
2. Complete 1-minute breathing session
3. Apple Watch will write HR data to HealthKit
4. Within 1-3 seconds, you should see in logs:

```
🔔 NEW HEART RATE DATA AVAILABLE! Fetching from HealthKit...
✅ [HealthObserver] New HR: 52 BPM at 2025-11-07 17:50:15.123
🔔 [Dashboard] NEW HR: 52 BPM
```

5. iOS dashboard updates immediately
6. Backend syncs within 2-3 seconds
7. Web dashboard shows fresh data

---

## Verification Checklist

After completing setup, verify:

- [ ] No "Missing entitlement" errors in logs
- [ ] Observers start successfully (3 success messages)
- [ ] Apple Watch measurement triggers notification within 3 seconds
- [ ] iOS dashboard updates immediately
- [ ] Backend receives sync within 5 seconds
- [ ] Web dashboard shows fresh data
- [ ] Timestamp shows "< 1 m ago" or "Just now"
- [ ] Works when app is backgrounded

---

## Technical Details

### Packages Used

**`health_kit_reporter: ^2.3.1`**
- Provides native access to `HKObserverQuery`
- Supports background delivery
- Allows setting `UpdateFrequency.immediate`

### API Methods

```dart
// Enable background notifications
await HealthKitReporter.enableBackgroundDelivery(
  QuantityType.heartRate.identifier,
  UpdateFrequency.immediate,
);

// Set up observer
HealthKitReporter.observerQuery(
  [QuantityType.heartRate.identifier],
  null, // No predicate (all data)
  onUpdate: (identifier) async {
    // Callback fires when new data arrives
  },
);
```

### Background Modes (Already Configured)

File: `ios/Runner/Info.plist`

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
</array>
```

This allows iOS to wake the app when HealthKit sends notifications.

---

## Troubleshooting

### Error: "Missing entitlement"
**Solution**: Follow Step 3 above - add HealthKit capability with Background Delivery

### Observer starts but no notifications arrive
**Possible causes**:
1. Apple Watch not writing data (not in workout mode, battery saving)
2. Background delivery frequency being throttled by iOS
3. App not properly registered with HealthKit

**Solution**: Trigger active measurement with Breathe app or start a workout

### Timestamps still showing old data
**Causes**:
1. Apple Watch hasn't written new measurements (normal at rest)
2. Observers not enabled (check logs for errors)

**Solution**: Wait for Apple Watch to write data, or manually trigger with workout

---

## Rollback Plan

If observers don't work after entitlement setup, revert to polling:

```bash
git checkout lib/screens/health_dashboard_screen.dart
flutter run
```

This restores the 5-minute timer implementation.

---

## Summary

**Current**: 5-minute polling (works, but slow)
**Permanent**: Observer-based (requires 5-minute Xcode setup)

**Benefits of permanent solution**:
- ⚡ 1-3 second latency (vs 0-5 minutes)
- 🔋 Better battery life
- 📱 Real-time synchronization
- ✅ Professional user experience

**Setup time**: ~5 minutes (one-time configuration)
