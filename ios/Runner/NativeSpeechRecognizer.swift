import Foundation
import Speech
import Flutter

/// Native iOS Speech Recognizer with Enhanced Punctuation Support
///
/// This class provides direct access to Apple's SFSpeech framework
/// with proper configuration for excellent punctuation and capitalization.
class NativeSpeechRecognizer: NSObject, FlutterPlugin, SFSpeechRecognizerDelegate {

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var channel: FlutterMethodChannel?

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "native_speech_recognizer", binaryMessenger: registrar.messenger())
        let instance = NativeSpeechRecognizer()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(result: result)
        case "startListening":
            startListening(result: result)
        case "stopListening":
            stopListening(result: result)
        case "hasPermission":
            checkPermission(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func initialize(result: @escaping FlutterResult) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

        guard let recognizer = speechRecognizer else {
            result(FlutterError(code: "UNAVAILABLE", message: "Speech recognition not available", details: nil))
            return
        }

        recognizer.delegate = self

        // Request authorization
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    result(true)
                case .denied, .restricted, .notDetermined:
                    result(FlutterError(code: "PERMISSION_DENIED", message: "Speech recognition permission denied", details: nil))
                @unknown default:
                    result(FlutterError(code: "UNKNOWN", message: "Unknown authorization status", details: nil))
                }
            }
        }
    }

    private func checkPermission(result: @escaping FlutterResult) {
        let status = SFSpeechRecognizer.authorizationStatus()
        result(status == .authorized)
    }

    private func startListening(result: @escaping FlutterResult) {
        // Cancel any previous task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        // Configure audio session for recording
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            result(FlutterError(code: "AUDIO_SESSION", message: "Failed to configure audio session", details: error.localizedDescription))
            return
        }

        // Create recognition request with enhanced punctuation
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            result(FlutterError(code: "REQUEST_FAILED", message: "Unable to create recognition request", details: nil))
            return
        }

        // CRITICAL: Enable these flags for better punctuation
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true  // ← KEY: Enable automatic punctuation

        // For iOS 16+: Use on-device recognition for better privacy and speed
        if #available(iOS 16, *) {
            recognitionRequest.requiresOnDeviceRecognition = false  // Use server for best accuracy
        }

        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            result(FlutterError(code: "AUDIO_ENGINE", message: "Failed to start audio engine", details: error.localizedDescription))
            return
        }

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let transcript = result.bestTranscription.formattedString

                // Send interim results
                self.channel?.invokeMethod("onResult", arguments: [
                    "transcript": transcript,
                    "isFinal": result.isFinal
                ])

                // If final, stop listening
                if result.isFinal {
                    self.stopListeningInternal()
                }
            }

            if let error = error {
                print("❌ Recognition error: \(error.localizedDescription)")
                self.channel?.invokeMethod("onError", arguments: error.localizedDescription)
                self.stopListeningInternal()
            }
        }

        result(true)
    }

    private func stopListening(result: @escaping FlutterResult) {
        stopListeningInternal()
        result(true)
    }

    private func stopListeningInternal() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
    }

    // MARK: - SFSpeechRecognizerDelegate

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        channel?.invokeMethod("onAvailabilityChanged", arguments: available)
    }
}
