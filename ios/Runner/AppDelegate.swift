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

    // Configure audio session for playback
    // SIMPLIFIED: Use basic .playback category without mode to avoid Error -50
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback,
        options: [.allowBluetooth, .defaultToSpeaker]
      )
      try AVAudioSession.sharedInstance().setActive(true)

      // Log available audio routes
      let currentRoute = AVAudioSession.sharedInstance().currentRoute
      print("🔊 [AppDelegate] Audio session configured successfully")
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
