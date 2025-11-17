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

    // REMOVED: Audio session configuration
    // Let just_audio plugin handle audio session automatically
    // Manual configuration was causing Error -50 conflicts

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
