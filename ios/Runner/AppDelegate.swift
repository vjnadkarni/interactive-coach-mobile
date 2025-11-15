import Flutter
import UIKit
import WebKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register native speech recognizer plugin
    if let registrar = self.registrar(forPlugin: "NativeSpeechRecognizer") {
      NativeSpeechRecognizer.register(with: registrar)
    }

    // Register HeyGen Avatar Platform View
    if let registrar = self.registrar(forPlugin: "HeyGenAvatarView") {
      let factory = HeyGenAvatarViewFactory(messenger: registrar.messenger())
      registrar.register(factory, withId: "heygen_avatar_view")
    }

    // Configure audio session for playback with Bluetooth routing
    do {
      // Use .playback category with Bluetooth A2DP option to route to headphones
      try AVAudioSession.sharedInstance().setCategory(
        .playback,
        mode: .spokenAudio,  // Optimized for speech
        options: [.allowBluetoothA2DP, .duckOthers]
      )
      try AVAudioSession.sharedInstance().setActive(true)

      // Log available audio routes
      let currentRoute = AVAudioSession.sharedInstance().currentRoute
      print("🔊 [AppDelegate] Audio session configured")
      print("🔊 [AppDelegate] Current audio route:")
      for output in currentRoute.outputs {
        print("  - \(output.portType.rawValue): \(output.portName)")
      }
    } catch {
      print("❌ [AppDelegate] Failed to configure audio session: \(error)")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
