import Flutter
import AVFoundation

/// Apple Native TTS Handler using AVSpeechSynthesizer
/// Provides intelligent text-to-speech with automatic handling of numbers, ranges, dates, etc.
class AppleTTSHandler: NSObject, FlutterPlugin, AVSpeechSynthesizerDelegate {
    static var channel: FlutterMethodChannel?
    let synthesizer = AVSpeechSynthesizer()
    var isSpeaking: Bool = false

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "apple_tts",
            binaryMessenger: registrar.messenger()
        )
        let instance = AppleTTSHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
        AppleTTSHandler.channel = channel
        instance.synthesizer.delegate = instance

        print("🎤 [AppleTTSHandler] Registered Apple TTS channel")
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "speak":
            speak(call: call, result: result)
        case "stop":
            stop(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func speak(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let text = args["text"] as? String else {
            print("❌ [AppleTTSHandler] Missing text parameter")
            result(FlutterError(code: "INVALID_ARGS", message: "Missing text", details: nil))
            return
        }

        let voice = args["voice"] as? String ?? "com.apple.ttsbundle.Samantha-compact"
        let rate = args["rate"] as? Float ?? 0.5
        let pitch = args["pitch"] as? Float ?? 1.0
        let volume = args["volume"] as? Float ?? 1.0

        NSLog("🔊 [AppleTTSHandler] Speaking text (\(text.count) chars)")
        NSLog("🎵 [AppleTTSHandler] Voice: \(voice), Rate: \(rate), Pitch: \(pitch), Volume: \(volume)")

        // SIMPLEST audio session - just playback, no fancy routing
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            NSLog("✅ [AppleTTSHandler] Simple audio session activated")
        } catch {
            NSLog("❌ [AppleTTSHandler] Audio session error: \(error)")
        }

        // Stop any ongoing speech
        if synthesizer.isSpeaking {
            print("⚠️ [AppleTTSHandler] Stopping previous speech")
            synthesizer.stopSpeaking(at: .immediate)
        }

        // Create utterance
        let utterance = AVSpeechUtterance(string: text)

        // Set voice (Samantha)
        if let selectedVoice = AVSpeechSynthesisVoice(identifier: voice) {
            utterance.voice = selectedVoice
            print("✅ [AppleTTSHandler] Using voice: \(selectedVoice.name)")
        } else {
            // Fallback to Samantha by language
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            print("⚠️ [AppleTTSHandler] Voice identifier not found, using default en-US")
        }

        // Set speech parameters
        utterance.rate = rate           // 0.0-1.0 (default 0.5)
        utterance.pitchMultiplier = pitch   // 0.5-2.0 (default 1.0)
        utterance.volume = volume       // 0.0-1.0 (default 1.0)

        // Pre-utterance delay to reduce first-word truncation
        utterance.preUtteranceDelay = 0.1  // 100ms delay before speech starts

        isSpeaking = true

        // Start speaking
        synthesizer.speak(utterance)

        print("✅ [AppleTTSHandler] Speech started")
        result(true)
    }

    private func stop(result: @escaping FlutterResult) {
        print("🛑 [AppleTTSHandler] Stopping speech")
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        result(true)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("▶️ [AppleTTSHandler] Speech started")
        isSpeaking = true
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("✅ [AppleTTSHandler] Speech finished")
        isSpeaking = false

        // Notify Flutter that speech is complete
        AppleTTSHandler.channel?.invokeMethod("onSpeechComplete", arguments: nil)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("⚠️ [AppleTTSHandler] Speech cancelled")
        isSpeaking = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        print("⏸️ [AppleTTSHandler] Speech paused")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        print("▶️ [AppleTTSHandler] Speech resumed")
    }
}
