import Flutter
import AVFoundation

/// Native audio player using AVAudioPlayer with enhanced first-word truncation prevention
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
            // CRITICAL: Configure audio session FIRST, before creating player
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)

            // Create new player with audio data
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0  // Ensure full volume

            // Prepare audio for playback
            let prepareSuccess = audioPlayer?.prepareToPlay() ?? false

            if !prepareSuccess {
                print("❌ [NativeAudioPlayer] prepareToPlay() failed")
                result(FlutterError(code: "PREPARE_FAILED", message: "Failed to prepare audio", details: nil))
                return
            }

            // Verify audio is valid
            guard let duration = audioPlayer?.duration, duration > 0 else {
                print("❌ [NativeAudioPlayer] Invalid duration: \(audioPlayer?.duration ?? 0)")
                result(FlutterError(code: "INVALID_AUDIO", message: "Invalid audio duration", details: nil))
                return
            }

            print("✅ [NativeAudioPlayer] Audio prepared: \(duration)s, \(data.count) bytes")

            // Start playback immediately (no delay)
            // The silence is already in the audio file from TTS text prefix
            let success = audioPlayer?.play() ?? false

            if success {
                isPlaying = true
                print("✅ [NativeAudioPlayer] Playback started")
                result(true)
            } else {
                print("❌ [NativeAudioPlayer] play() failed")
                result(FlutterError(code: "PLAYBACK_FAILED", message: "Playback failed", details: nil))
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

        // Notify Flutter
        NativeAudioPlayer.channel?.invokeMethod("onPlaybackComplete", arguments: flag)
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ [NativeAudioPlayer] Decode error: \(error?.localizedDescription ?? "unknown")")
        isPlaying = false
        audioPlayer = nil

        // Notify Flutter
        NativeAudioPlayer.channel?.invokeMethod("onPlaybackError", arguments: error?.localizedDescription)
    }
}
