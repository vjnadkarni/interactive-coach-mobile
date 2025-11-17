import Flutter
import AVFoundation

/// Native audio player using AVAudioPlayer for reliable TTS playback
/// Bypasses just_audio package issues with consecutive playback
class NativeAudioPlayer: NSObject, FlutterPlugin, AVAudioPlayerDelegate {
    static var channel: FlutterMethodChannel?
    var audioPlayer: AVAudioPlayer?
    var isPlaying: Bool = false

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "native_audio_player", binaryMessenger: registrar.messenger())
        let instance = NativeAudioPlayer()
        registrar.addMethodCallDelegate(instance, channel: channel)
        NativeAudioPlayer.channel = channel
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "play":
            guard let args = call.arguments as? [String: Any],
                  let audioData = args["audioData"] as? FlutterStandardTypedData else {
                result(FlutterError(code: "INVALID_ARGS", message: "Audio data required", details: nil))
                return
            }
            playAudio(data: audioData.data, result: result)

        case "stop":
            stopAudio(result: result)

        case "isPlaying":
            result(isPlaying)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func playAudio(data: Data, result: @escaping FlutterResult) {
        print("🎵 [NativeAudioPlayer] Playing audio (\(data.count) bytes)")

        // Stop any existing playback
        if audioPlayer != nil && isPlaying {
            print("⚠️ [NativeAudioPlayer] Stopping previous audio")
            audioPlayer?.stop()
            audioPlayer = nil
        }

        do {
            // Create new player with fresh audio data
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()

            // Configure audio session
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)

            // Start playback
            let success = audioPlayer?.play() ?? false

            if success {
                isPlaying = true
                print("✅ [NativeAudioPlayer] Audio started successfully")
                result(true)
            } else {
                print("❌ [NativeAudioPlayer] Failed to start audio")
                result(FlutterError(code: "PLAYBACK_FAILED", message: "Failed to start audio", details: nil))
            }
        } catch {
            print("❌ [NativeAudioPlayer] Error: \(error)")
            result(FlutterError(code: "PLAYBACK_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    private func stopAudio(result: @escaping FlutterResult) {
        print("🛑 [NativeAudioPlayer] Stopping audio")
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        result(true)
    }

    // AVAudioPlayerDelegate methods
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("✅ [NativeAudioPlayer] Audio finished (success: \(flag))")
        isPlaying = false
        audioPlayer = nil

        // Notify Flutter that playback finished
        NativeAudioPlayer.channel?.invokeMethod("onPlaybackComplete", arguments: flag)
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ [NativeAudioPlayer] Decode error: \(error?.localizedDescription ?? "unknown")")
        isPlaying = false
        audioPlayer = nil

        // Notify Flutter of error
        NativeAudioPlayer.channel?.invokeMethod("onPlaybackError", arguments: error?.localizedDescription)
    }
}
