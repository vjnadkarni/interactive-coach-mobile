# HeyGen Native iOS SDK Implementation

## Overview

This guide walks through implementing HeyGen's Interactive Avatar using **native iOS** (bypassing WebView restrictions) for Video + Voice mode in the Flutter app.

---

## Architecture

```
Flutter UI (avatar_screen.dart)
        ↓
Platform Channel (heygen_avatar)
        ↓
Native iOS View Controller
        ↓
LiveKit SDK (WebRTC)
        ↓
HeyGen Streaming API
```

---

## Prerequisites

1. **HeyGen API Key**: Required for authentication
2. **Xcode 14.0+**: For iOS development
3. **iOS 14.0+**: Minimum deployment target
4. **Flutter**: Existing Flutter project setup

---

## Implementation Steps

### Step 1: Add Swift Package Dependencies

The following packages must be added through Xcode's **Swift Package Manager**:

1. **LiveKit Swift SDK** (required for WebRTC)
   - URL: `https://github.com/livekit/client-sdk-swift`
   - Version: `2.0.0` or later

2. **Alamofire** (HTTP networking - optional, can use URLSession)
   - URL: `https://github.com/Alamofire/Alamofire`
   - Version: `5.0.0` or later

#### How to Add via Xcode:

1. Open `interactive-coach-mobile/ios/Runner.xcworkspace` in Xcode
2. Select the `Runner` project in the navigator
3. Select the `Runner` target
4. Click the `+` button under "Frameworks, Libraries, and Embedded Content"
5. Choose "Add Package Dependency..."
6. Enter package URL (e.g., `https://github.com/livekit/client-sdk-swift`)
7. Choose version requirements
8. Click "Add Package"
9. Repeat for each dependency

**IMPORTANT**: Swift packages added this way will be tracked in `Runner.xcodeproj/project.pbxproj`. The packages themselves are downloaded to `~/Library/Developer/Xcode/DerivedData/`.

---

### Step 2: Files Created

The following Swift files have been created in `ios/Runner/HeyGen/`:

1. **HeyGenConfig.swift**
   - API configuration
   - Avatar settings (Marianne with Rachel voice)
   - Opening message

2. **HeyGenAPIModels.swift**
   - Codable data models for API requests/responses
   - Streaming event types
   - Chat message model

3. **HeyGenAPI.swift**
   - API client for HeyGen endpoints
   - Session creation, start, stop
   - Token generation
   - Send task (text-to-speech)

4. **HeyGenAvatarViewController.swift**
   - Flutter Platform View implementation
   - Method channel handler
   - Bridges Flutter ↔ Native iOS

5. **HeyGenAvatarViewModel.swift** (TO BE CREATED)
   - LiveKit Room management
   - WebRTC connection
   - Audio/video track handling
   - Speech recognition integration

---

### Step 3: Register Platform View in AppDelegate

Modify `ios/Runner/AppDelegate.swift` to register the platform view factory:

```swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register native speech recognizer
    if let registrar = self.registrar(forPlugin: "NativeSpeechRecognizer") {
      NativeSpeechRecognizer.register(with: registrar)
    }

    // ✅ NEW: Register HeyGen Avatar Platform View
    if let registrar = self.registrar(forPlugin: "HeyGenAvatarView") {
      let factory = HeyGenAvatarViewFactory(messenger: registrar.messenger())
      registrar.register(factory, withId: "heygen_avatar_view")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

### Step 4: Flutter Integration

Update `lib/screens/avatar_screen.dart` to use the native platform view:

```dart
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

class AvatarScreen extends StatefulWidget {
  // ... existing code
}

class _AvatarScreenState extends State<AvatarScreen> {
  MethodChannel? _avatarChannel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with Hera')),
      body: Column(
        children: [
          // Native HeyGen Avatar View
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black,
              child: UiKitView(
                viewType: 'heygen_avatar_view',
                layoutDirection: TextDirection.ltr,
                creationParams: {
                  'apiKey': dotenv.env['HEYGEN_API_KEY'] ?? '',
                },
                creationParamsCodec: const StandardMessageCodec(),
                onPlatformViewCreated: _onPlatformViewCreated,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                },
              ),
            ),
          ),
          // Chat Panel (existing code)
          Expanded(
            flex: 1,
            child: ChatPanel(), // Existing widget
          ),
        ],
      ),
    );
  }

  void _onPlatformViewCreated(int viewId) {
    _avatarChannel = MethodChannel('heygen_avatar_$viewId');

    // Start HeyGen session
    _startSession();
  }

  Future<void> _startSession() async {
    try {
      await _avatarChannel?.invokeMethod('start');
      print('✅ HeyGen session started');
    } catch (e) {
      print('❌ Failed to start HeyGen session: $e');
    }
  }

  Future<void> _stopSession() async {
    try {
      await _avatarChannel?.invokeMethod('stop');
      print('✅ HeyGen session stopped');
    } catch (e) {
      print('❌ Failed to stop HeyGen session: $e');
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _avatarChannel?.invokeMethod('speak', {'text': text});
    } catch (e) {
      print('❌ Failed to send text to avatar: $e');
    }
  }

  @override
  void dispose() {
    _stopSession();
    super.dispose();
  }
}
```

---

### Step 5: Connect to Existing Speech Recognition

The native speech recognition (`NativeSpeechRecognizer.swift`) is already implemented. We need to:

1. **Listen to speech results** in `avatar_screen.dart`
2. **Send transcript to backend** (existing `/chat/stream` endpoint)
3. **Get response from Claude**
4. **Send response to HeyGen avatar** via `_speak(response)`

This maintains the same flow as the WebView implementation, just using the native view instead.

---

## ViewModel Implementation (Next Step)

The `HeyGenAvatarViewModel.swift` needs to:

1. **Connect to LiveKit Room**
   - Use session URL and access token from HeyGen API
   - Subscribe to remote participant (avatar)

2. **Display Video Track**
   - Render avatar video in UIView
   - Handle aspect ratio and layout

3. **Handle Audio Playback**
   - Subscribe to audio track
   - Audio will play natively (no WebView restrictions!)

4. **Receive Data Channel Events**
   - Avatar talking events
   - User talking events
   - Chat messages

5. **Send Messages to Flutter**
   - Use Method Channel to notify Flutter of events
   - Update chat UI with avatar responses

---

## Testing Checklist

Once implementation is complete:

- [ ] Video loads and displays Hera avatar
- [ ] Audio plays from avatar (CRITICAL - this was broken in WebView)
- [ ] Speech recognition works (existing native implementation)
- [ ] Backend integration works (existing `/chat/stream` endpoint)
- [ ] Chat messages display correctly
- [ ] Session start/stop works
- [ ] No memory leaks on session termination

---

## Key Differences from WebView Approach

| Aspect | WebView (Old) | Native iOS (New) |
|--------|---------------|------------------|
| Audio Playback | ❌ Blocked by iOS | ✅ Works natively |
| Performance | Slower | Faster |
| Battery Usage | Higher | Lower |
| Complexity | React + Flutter | Swift + Flutter |
| Debugging | Difficult | Easier |

---

## Next Steps

1. ✅ Create Swift API models and client
2. ✅ Create Platform View controller
3. ⏳ Create ViewModel with LiveKit integration
4. ⏳ Add Swift packages via Xcode
5. ⏳ Update Flutter code
6. ⏳ Test on physical device

---

## Troubleshooting

### Swift Packages Not Resolving

**Problem**: Xcode fails to download LiveKit SDK

**Solution**:
1. Xcode → File → Packages → Reset Package Caches
2. Clean build folder: Cmd+Shift+K
3. Rebuild project

### Audio Still Not Playing

**Problem**: Native iOS implementation but audio still silent

**Solution**:
1. Check AVAudioSession configuration in AppDelegate
2. Verify microphone permissions in Info.plist
3. Test with headphones connected
4. Check iOS Settings → Privacy → Microphone

### LiveKit Connection Fails

**Problem**: Room connection fails with timeout

**Solution**:
1. Verify HeyGen API key is correct
2. Check network connectivity
3. Enable verbose logging in LiveKit SDK
4. Check HeyGen session is started before connecting

---

**Last Updated**: November 14, 2025
**Status**: Implementation in progress (Swift files created, ViewModel pending)
