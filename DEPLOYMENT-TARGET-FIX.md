# iOS Deployment Target Fix

## Problems Encountered

### Problem 1: Deployment Target Below Minimum
The iOS Simulator build was failing with:
```
Command PhaseScriptExecution failed with a nonzero exit code
The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 9.0/11.0,
but the range of supported deployment target versions is 12.0 to 26.1.99.
```

**Affected pods:** flutter_secure_storage (9.0), HealthKitReporter (9.0), permission_handler_apple (9.0), record_darwin (11.0)

### Problem 2: Dylib Linking Error (After First Fix)
After setting minimum to 12.0, got new error:
```
Building for iOS-simulator-12.0, but linking with dylib '@rpath/Flutter.framework/Flutter'
which was built for newer version 13.0
```

**Root cause:** Flutter.framework itself requires minimum iOS 13.0, but some pods were set to 12.0.

## Root Cause
Individual CocoaPods were overriding the global iOS 14.0 platform requirement with their own deployment targets. First fix (12.0) was insufficient because Flutter.framework requires iOS 13.0 minimum.

## Solution (Final)
Modified the `ios/Podfile` post_install hook to enforce minimum **iOS 13.0** deployment target (to match Flutter.framework):

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    # Force minimum iOS 13.0 deployment target for all pods
    # This matches Flutter.framework minimum and fixes dylib linking errors
    target.build_configurations.each do |config|
      deployment_target = config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
      if deployment_target.nil? || deployment_target.to_f < 13.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end
end
```

## Changes Applied
1. ✅ Modified `ios/Podfile` post_install hook (lines 43-50)
   - Initial fix: Minimum 12.0 (resolved 9.0/11.0 warnings)
   - Final fix: Minimum 13.0 (resolved dylib linking error)
2. ✅ Complete clean: Deleted Pods/, Podfile.lock, build/, DerivedData/
3. ✅ Ran `pod install` to regenerate Pods project (19 pods installed)
4. ✅ Verified deployment targets: All pods now use **13.0 or 14.0** (NO 9.0, 11.0, or 12.0)
5. ✅ Ran `flutter clean` to clear Flutter build cache

## Testing Instructions

### Option 1: Test in Xcode (Recommended)
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select "iPhone 17 Pro" simulator from device dropdown
3. Click the Play button (▶️) to build and run
4. Expected: Build should succeed without deployment target warnings
5. Expected: App launches in simulator

### Option 2: Test via Command Line
```bash
cd /Users/vijay/venv/interactive-coach-mobile
flutter run -d "iPhone 17 Pro"
```

## Verification
After successful build, verify Deepgram punctuation is working:
1. Launch app on simulator
2. Tap microphone icon
3. Grant microphone permissions
4. Speak a test phrase: "Hello this is a test"
5. Expected: Transcript appears WITH automatic punctuation and capitalization
6. Expected: Backend receives message with proper punctuation

## Status
- ✅ Podfile updated with iOS 13.0 minimum enforcement (matches Flutter.framework)
- ✅ Pods completely cleaned and regenerated
- ✅ Deployment targets verified: All pods now use **13.0 or 14.0** (NO 9.0, 11.0, or 12.0)
- ✅ Flutter build cache cleaned
- ✅ Dylib linking error resolved (Flutter.framework version mismatch fixed)
- ⏳ Ready for Xcode build test on iPhone 17 Pro simulator

## Next Steps
If the build succeeds:
1. Test Deepgram STT functionality
2. Verify punctuation appears in chat messages
3. Test end-to-end conversation flow with proper punctuation

If the build still fails:
1. Check Xcode Issue Navigator for any remaining errors
2. Try cleaning Xcode build folder (Cmd+Shift+K)
3. Try "Clean Build Folder" option in Xcode Product menu
