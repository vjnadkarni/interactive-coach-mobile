# HealthKit Setup Guide for iOS

## 📱 **Prerequisites**

- Xcode 15+ installed
- iPhone 12 (for testing)
- Apple Watch Series 9 (paired with iPhone)
- Apple Developer account (for code signing)

---

## 🔧 **Step 1: Enable HealthKit Capability in Xcode**

### **IMPORTANT:** This step MUST be done manually in Xcode (cannot be automated via Flutter)

1. **Open the iOS project in Xcode:**
   ```bash
   cd /Users/vijay/venv/interactive-coach-mobile
   open ios/Runner.xcworkspace
   ```
   ⚠️ **Note:** Open `.xcworkspace`, NOT `.xcodeproj`

2. **Select the Runner target:**
   - In Xcode's project navigator (left panel), click on "Runner" (blue icon at top)
   - Make sure "Runner" target is selected (not the project)

3. **Go to Signing & Capabilities tab:**
   - Click the "Signing & Capabilities" tab at the top of the editor

4. **Add HealthKit capability:**
   - Click the "+ Capability" button
   - Search for "HealthKit"
   - Double-click "HealthKit" to add it

   ✅ You should see "HealthKit" appear in the capabilities list with a checkmark

5. **Enable Clinical Health Records (Optional):**
   - If you see "Clinical Health Records (Background Delivery)" option, you can leave it unchecked
   - This is only needed for accessing clinical health data from medical institutions

6. **Verify the entitlements file:**
   - Xcode automatically creates `ios/Runner/Runner.entitlements`
   - This file should contain:
   ```xml
   <key>com.apple.developer.healthkit</key>
   <true/>
   ```

---

## 📝 **Step 2: Verify Info.plist Permissions (Already Done)**

The following permissions have already been added to `ios/Runner/Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Interactive Coach needs access to your health data from Apple Watch to provide personalized fitness coaching, track your progress, and give you insights based on your heart rate, activity, sleep, and other health metrics.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Interactive Coach may save workout and health data to your Health app for comprehensive tracking and analysis.</string>
```

These descriptions will appear in the permission dialog when users first launch the app.

---

## 🧪 **Step 3: Test on Real iPhone**

⚠️ **CRITICAL:** HealthKit does NOT work on the iOS Simulator. You MUST use a real iPhone.

### **Connect iPhone 12:**

1. **USB Connection (Recommended):**
   - Connect iPhone 12 to Mac via Lightning cable
   - Unlock iPhone and trust computer when prompted

2. **Wireless Debugging (Alternative):**
   - Enable wireless debugging in Xcode (Window → Devices and Simulators)
   - Pair iPhone wirelessly

### **Build and Run:**

1. **In Xcode:**
   - Select iPhone 12 from the device dropdown (top toolbar)
   - Click the "Run" button (▶️) or press Cmd+R

2. **Or from Flutter CLI:**
   ```bash
   flutter run --release
   # or
   flutter run --debug
   ```

3. **Grant permissions on iPhone:**
   - When app launches, you'll see permission dialog
   - Tap "Turn On All" to grant access to all health data types
   - Or individually select which data types to allow

---

## ✅ **Step 4: Verify Health Data Access**

### **Check Health App on iPhone:**

1. Open Health app on iPhone 12
2. Go to Browse → Heart → Heart Rate
3. Verify there's data from Apple Watch Series 9
4. Note: If no recent data, wear the watch and do a quick workout or check your heart rate manually

### **Test App Permissions:**

After running the app and granting permissions:

1. Go to iPhone Settings → Health → Data Access & Devices
2. Find "Interactive Coach Mobile"
3. Verify the app has permission to read:
   - Heart Rate
   - Heart Rate Variability
   - Blood Oxygen
   - Sleep Analysis
   - Steps
   - Active Energy
   - Exercise Time
   - (and other metrics we'll request)

---

## 🔍 **Troubleshooting**

### **Issue: HealthKit capability not appearing**

**Solution:**
- Make sure you opened `Runner.xcworkspace` (NOT `Runner.xcodeproj`)
- Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)
- Restart Xcode

---

### **Issue: "Signing requires a development team"**

**Solution:**
- In Signing & Capabilities tab, select your Apple Developer team from dropdown
- If you don't see your team, add it in Xcode → Preferences → Accounts

---

### **Issue: Permission dialog not showing**

**Solution:**
- Delete app from iPhone
- Rebuild and reinstall
- Permission dialog shows only on first launch after granting HealthKit capability

---

### **Issue: "No health data found"**

**Possible causes:**
1. Apple Watch not paired with iPhone
2. Health app not syncing
3. No recent health data on watch (wear it for a bit)
4. Permissions not granted correctly

**Solutions:**
- Open Health app and verify data exists
- Restart Apple Watch and iPhone
- Re-grant permissions: Settings → Health → Data Access & Devices → Interactive Coach Mobile → Toggle permissions off and on

---

## 📱 **Next Steps**

After successfully enabling HealthKit and verifying permissions:

1. ✅ Proceed to implement `lib/services/health_service.dart`
2. ✅ Test fetching heart rate data from HealthKit
3. ✅ Display data in health dashboard UI
4. ✅ Sync data to backend API

---

## 🔗 **Resources**

- [Apple HealthKit Documentation](https://developer.apple.com/documentation/healthkit)
- [Flutter `health` package](https://pub.dev/packages/health)
- [HealthKit Data Types](https://developer.apple.com/documentation/healthkit/data_types)

---

## ✅ **Checklist**

Before continuing to code:

- [ ] HealthKit capability enabled in Xcode
- [ ] Runner.entitlements file created with HealthKit key
- [ ] Info.plist has NSHealthShareUsageDescription
- [ ] Info.plist has NSHealthUpdateUsageDescription
- [ ] App builds successfully in Xcode
- [ ] App runs on iPhone 12 (real device)
- [ ] Permission dialog appears on first launch
- [ ] Permissions granted for health data types
- [ ] Health app shows data from Apple Watch Series 9

Once all checkboxes are marked, you're ready to implement HealthService!
