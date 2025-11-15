# Xcode Swift Package Setup Guide

**CRITICAL**: LiveKit SDK (required for HeyGen native implementation) is **only available via Swift Package Manager**, not CocoaPods.

---

## Step-by-Step: Adding LiveKit SDK to Xcode Project

### 1. Open the Project in Xcode

```bash
cd /Users/vijay/venv/interactive-coach-mobile/ios
open Runner.xcworkspace  # NOT Runner.xcodeproj (important for CocoaPods projects)
```

### 2. Add LiveKit Package

1. In Xcode, select the **Runner** project (blue icon) in the Project Navigator
2. Select the **Runner** target (under TARGETS)
3. Click the **"+"** button at the bottom of "Frameworks, Libraries, and Embedded Content"
4. In the dialog, click **"Add Other..." → "Add Package Dependency..."**
5. Paste this URL: `https://github.com/livekit/client-sdk-swift`
6. **Dependency Rule**: Choose "Up to Next Major Version" with `2.0.0`
7. Click **"Add Package"**
8. Wait for Xcode to resolve the package (may take 1-2 minutes)
9. In the package products list, select:
   - **LiveKit**
10. Click **"Add Package"**

### 3. Verify Package Installation

After adding the package:

1. In Project Navigator, you should see **"Package Dependencies"** section
2. Expand it to see **"client-sdk-swift"**
3. The package is now available to import in Swift files

### 4. Build the Project

```bash
# Clean and rebuild to ensure packages are integrated
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ios --no-codesign
```

If you see errors like `"No such module 'LiveKit'"`, the package didn't install correctly. Retry Step 2.

---

## Alternative: Add Package via File Menu

If the above doesn't work:

1. **File** → **Add Package Dependencies...**
2. Paste URL: `https://github.com/livekit/client-sdk-swift`
3. Continue with steps 6-10 above

---

## Why Swift Package Manager (not CocoaPods)?

LiveKit discontinued CocoaPods support in v2.0. The SDK is now distributed exclusively via SPM.

Flutter projects using CocoaPods **can still use SPM** for specific packages. Xcode handles this automatically.

---

## Testing Package Import

Create a test Swift file to verify LiveKit is accessible:

**Test file** (`ios/Runner/LiveKitTest.swift`):

```swift
import LiveKit

class LiveKitTest {
    func testImport() {
        print("✅ LiveKit SDK imported successfully")
        let room = Room()
        print("✅ LiveKit Room created: \(room)")
    }
}
```

Build the project. If it compiles without errors, LiveKit is correctly installed.

---

## Troubleshooting

### "No such module 'LiveKit'"

**Solution**:
1. Xcode → File → Packages → Reset Package Caches
2. Clean build: Cmd+Shift+K
3. Rebuild: Cmd+B

### "Package.resolved is corrupted"

**Solution**:
1. Close Xcode
2. Delete `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
3. Reopen Xcode
4. File → Packages → Resolve Package Versions

### Package download hangs

**Solution**:
1. Check internet connection
2. Try different WiFi network (corporate proxies sometimes block GitHub)
3. Manually clone LiveKit repo and add as local package:
   ```bash
   cd /tmp
   git clone https://github.com/livekit/client-sdk-swift
   ```
   Then in Xcode: **Add Local Package** → select `/tmp/client-sdk-swift`

---

## Next Steps After Package Installation

1. ✅ Verify LiveKit imports without errors
2. Create `HeyGenAvatarViewModel.swift` (uses LiveKit Room)
3. Register platform view in AppDelegate
4. Update Flutter code to use native view
5. Test on physical device

---

**Status**: Ready to execute once LiveKit package is added
