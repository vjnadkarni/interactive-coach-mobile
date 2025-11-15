//
//  HeyGenAvatarViewModel.swift
//  Runner
//
//  ViewModel for HeyGen Interactive Avatar with LiveKit integration
//  NOTE: Requires LiveKit SDK to be added via Swift Package Manager (see XCODE_PACKAGE_SETUP.md)
//

import UIKit
import Foundation
import AVFoundation
import Flutter

// IMPORTANT: Uncomment these imports after adding LiveKit via Xcode Swift Package Manager
import LiveKit

class HeyGenAvatarViewModel: NSObject, @unchecked Sendable {
    // MARK: - Properties

    private let api = HeyGenAPI()
    private let containerView: UIView
    private let methodChannel: FlutterMethodChannel

    private var session: SessionResponse.SessionData?
    private var sessionToken: String?

    // LiveKit Room (will be initialized after adding package)
    private var room: Room?
    private var videoView: UIView?

    private var isSessionActive = false
    private var chatMessages: [ChatMessage] = []

    // Track when session is ready for speak() calls
    private var hasVideoTrack = false
    private var hasAudioTrack = false
    private var hasSentOpeningMessage = false
    private var participantCheckTask: Task<Void, Never>?

    // MARK: - Initialization

    init(containerView: UIView, methodChannel: FlutterMethodChannel) {
        self.containerView = containerView
        self.methodChannel = methodChannel
        super.init()

        setupUI()
        configureAudioSession()
    }

    // MARK: - UI Setup

    private func setupUI() {
        containerView.backgroundColor = .black

        // Video view will be added when LiveKit track is available
        videoView = UIView(frame: containerView.bounds)
        videoView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        videoView?.backgroundColor = .black

        if let videoView = videoView {
            containerView.addSubview(videoView)
        }

        // Add loading indicator
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = containerView.center
        activityIndicator.startAnimating()
        activityIndicator.tag = 999  // For easy removal later
        containerView.addSubview(activityIndicator)
    }

    private func configureAudioSession() {
        // Audio session is already configured globally in AppDelegate
        // No need to configure it again here to avoid conflicts
        print("🔊 [HeyGenVM] Using global audio session (configured in AppDelegate)")
    }

    // MARK: - Session Management

    func startSession() async throws {
        print("🚀 [HeyGenVM] Starting HeyGen session...")

        // Verify API key is available
        let apiKey = HeyGenConfig.apiKey
        if apiKey.isEmpty {
            print("❌ [HeyGenVM] API key is empty!")
            throw HeyGenAPIError.invalidURL
        }
        print("✅ [HeyGenVM] API key available: \(apiKey.prefix(10))...")

        // Create new session (this also starts it and provides the access token)
        do {
            print("🔄 [HeyGenVM] Creating session...")
            let sessionData = try await api.createSession()
            self.session = sessionData
            print("✅ [HeyGenVM] Session created: \(sessionData.sessionId)")
            print("✅ [HeyGenVM] WebSocket URL: \(sessionData.url)")
            print("✅ [HeyGenVM] Access token received")
        } catch {
            print("❌ [HeyGenVM] Failed to create session: \(error)")
            throw error
        }

        // Connect to LiveKit room using the URL and token from session creation
        do {
            print("🔄 [HeyGenVM] Connecting to LiveKit room...")
            room = Room()
            room?.add(delegate: self)

            try await room?.connect(url: session!.url, token: session!.accessToken)
            print("✅ [HeyGenVM] Connected to LiveKit room")

            // Start polling for remote participant (HeyGen avatar)
            // The avatar takes a few seconds to join the room after session creation
            startParticipantPolling()
        } catch {
            print("❌ [HeyGenVM] Failed to connect to LiveKit: \(error)")
            throw error
        }

        // Mark session as active
        isSessionActive = true

        // Remove loading indicator
        await MainActor.run {
            if let indicator = containerView.viewWithTag(999) {
                indicator.removeFromSuperview()
            }
        }

        // DON'T send opening message yet - wait for video/audio tracks to be ready
        // Opening message will be sent from didSubscribeTrack callback
        print("⏳ [HeyGenVM] Waiting for tracks to be ready before speaking...")

        // Notify Flutter
        await MainActor.run {
            methodChannel.invokeMethod("onSessionStarted", arguments: nil)
        }
    }

    func stopSession() async throws {
        guard let sessionId = session?.sessionId else {
            print("⚠️ [HeyGenVM] No active session to stop")
            return
        }

        print("🛑 [HeyGenVM] Stopping session...")

        // Stop participant polling
        stopParticipantPolling()

        // Disconnect from LiveKit
        await room?.disconnect()

        // Stop HeyGen session
        try await api.stopSession(sessionId: sessionId)

        // Clean up
        session = nil
        sessionToken = nil
        isSessionActive = false
        hasVideoTrack = false
        hasAudioTrack = false
        hasSentOpeningMessage = false

        print("✅ [HeyGenVM] Session stopped")

        // Notify Flutter
        await MainActor.run {
            methodChannel.invokeMethod("onSessionStopped", arguments: nil)
        }
    }

    func speak(text: String) async throws {
        guard let sessionId = session?.sessionId,
              let accessToken = session?.accessToken,
              isSessionActive else {
            throw HeyGenAPIError.serverError("Session not active")
        }

        print("💬 [HeyGenVM] Sending text to avatar: \(text)")

        // Send task to HeyGen
        try await api.sendTask(sessionId: sessionId, accessToken: accessToken, text: text)

        print("✅ [HeyGenVM] Text sent successfully")
    }

    // MARK: - Participant Polling

    private func startParticipantPolling() {
        print("🔍 [HeyGenVM] Starting participant polling (waiting for HeyGen avatar to join)...")

        participantCheckTask = Task {
            var attempts = 0
            let maxAttempts = 30  // 30 seconds max wait

            while attempts < maxAttempts {
                guard let room = room else {
                    print("⚠️ [HeyGenVM] Room is nil, stopping polling")
                    return
                }

                let participantCount = room.remoteParticipants.count
                print("🔍 [HeyGenVM] Polling attempt \(attempts + 1)/\(maxAttempts) - Participant count: \(participantCount)")

                if participantCount > 0 {
                    // Found participant! Process it
                    print("✅ [HeyGenVM] Remote participant detected!")

                    for (_, participant) in room.remoteParticipants {
                        let participantName = participant.identity?.stringValue ?? "unknown"
                        print("👤 [HeyGenVM] Found participant: \(participantName)")

                        // Check for tracks
                        print("🔍 [HeyGenVM] Track count for \(participantName): \(participant.trackPublications.count)")

                        for (_, publication) in participant.trackPublications {
                            if let remotePublication = publication as? RemoteTrackPublication {
                                print("📹 [HeyGenVM] Found track: \(remotePublication.sid)")

                                if let track = remotePublication.track {
                                    if track is VideoTrack {
                                        await MainActor.run {
                                            self.hasVideoTrack = true
                                            if let videoTrack = track as? VideoTrack {
                                                self.setupVideoView(track: videoTrack)
                                            }
                                        }
                                        print("✅ [HeyGenVM] Video track ready")
                                    } else if track is AudioTrack {
                                        await MainActor.run {
                                            self.hasAudioTrack = true
                                        }
                                        print("🔊 [HeyGenVM] Audio track available")
                                    }

                                    await MainActor.run {
                                        self.checkAndSendOpeningMessage()
                                    }
                                } else {
                                    print("⚠️ [HeyGenVM] Track publication has no track yet")
                                }
                            }
                        }
                    }

                    // If we found tracks, stop polling
                    if hasVideoTrack && hasAudioTrack {
                        print("✅ [HeyGenVM] Both tracks found - stopping polling")
                        return
                    }
                }

                // Wait 1 second before next check
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                attempts += 1
            }

            print("⚠️ [HeyGenVM] Participant polling timeout after \(maxAttempts) seconds")
        }
    }

    private func stopParticipantPolling() {
        participantCheckTask?.cancel()
        participantCheckTask = nil
    }

    // MARK: - Cleanup

    deinit {
        Task {
            try? await stopSession()
        }
    }
}

// MARK: - LiveKit Room Delegate
// NOTE: Uncomment this after adding LiveKit package

extension HeyGenAvatarViewModel: RoomDelegate {
    func room(_ room: Room, didUpdateConnectionState connectionState: ConnectionState, from oldValue: ConnectionState) {
        Task { @MainActor in
            print("🔌 [HeyGenVM] Connection state: \(connectionState)")

            if case .connected = connectionState {
                methodChannel.invokeMethod("onConnected", arguments: nil)
            } else if case .disconnected = connectionState {
                methodChannel.invokeMethod("onDisconnected", arguments: nil)
            }
        }
    }

    func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
        Task { @MainActor in
            print("📹 [HeyGenVM] Track subscribed: \(publication.sid)")

            // If this is a video track, render it
            if let track = publication.track as? VideoTrack {
                hasVideoTrack = true
                setupVideoView(track: track)
                print("✅ [HeyGenVM] Video track ready")
            }

            // Audio tracks will automatically play through speakers/headphones
            if publication.track is AudioTrack {
                hasAudioTrack = true
                print("🔊 [HeyGenVM] Audio track available - should play automatically")
            }

            // Check if both tracks are ready
            checkAndSendOpeningMessage()
        }
    }

    func room(_ room: Room, participant: RemoteParticipant?, didReceiveData data: Data, forTopic topic: String, encryptionType: EncryptionType) {
        // Handle streaming events from HeyGen
        handleStreamingEvent(data: data)
    }

    private func setupVideoView(track: VideoTrack) {
        guard let videoView = videoView else { return }

        // Create LiveKit video renderer
        let renderer = VideoView(frame: videoView.bounds)
        renderer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        renderer.layoutMode = .fill
        renderer.track = track

        videoView.addSubview(renderer)

        print("✅ [HeyGenVM] Video view configured")
    }

    private func handleStreamingEvent(data: Data) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = json["type"] as? String else {
                return
            }

            switch type {
            case "avatar_start_talking":
                Task { @MainActor in
                    methodChannel.invokeMethod("onAvatarStartedSpeaking", arguments: nil)
                }

            case "avatar_stop_talking":
                Task { @MainActor in
                    methodChannel.invokeMethod("onAvatarStoppedSpeaking", arguments: nil)
                }

            case "avatar_talking_message":
                if let message = json["message"] as? String {
                    Task { @MainActor in
                        methodChannel.invokeMethod("onAvatarMessage", arguments: ["text": message])
                    }
                }

            case "user_talking_message":
                if let message = json["message"] as? String {
                    Task { @MainActor in
                        methodChannel.invokeMethod("onUserTranscript", arguments: ["text": message])
                    }
                }

            default:
                break
            }
        } catch {
            print("❌ [HeyGenVM] Failed to parse streaming event: \(error)")
        }
    }

    // Participant joined - check for existing tracks
    func room(_ room: Room, didAddParticipant participant: RemoteParticipant) {
        let participantName = participant.identity?.stringValue ?? "unknown"
        print("👤 [HeyGenVM] Participant joined: \(participantName)")

        // Check if participant already has tracks published
        Task {
            for (_, publication) in participant.trackPublications {
                if let remotePublication = publication as? RemoteTrackPublication {
                    print("📹 [HeyGenVM] Found existing track: \(remotePublication.sid)")

                    // Manually trigger subscription check
                    if let track = remotePublication.track {
                        if track is VideoTrack {
                            await MainActor.run {
                                self.hasVideoTrack = true
                                if let videoTrack = track as? VideoTrack {
                                    self.setupVideoView(track: videoTrack)
                                }
                            }
                            print("✅ [HeyGenVM] Video track ready (from existing)")
                        } else if track is AudioTrack {
                            await MainActor.run {
                                self.hasAudioTrack = true
                            }
                            print("🔊 [HeyGenVM] Audio track available (from existing)")
                        }

                        await MainActor.run {
                            self.checkAndSendOpeningMessage()
                        }
                    }
                }
            }
        }
    }

    // Helper to check if both tracks are ready and send opening message
    private func checkAndSendOpeningMessage() {
        if hasVideoTrack && hasAudioTrack && !hasSentOpeningMessage {
            hasSentOpeningMessage = true
            print("✅ [HeyGenVM] Both tracks ready - sending opening message")

            Task {
                do {
                    try await speak(text: HeyGenConfig.AvatarSettings.openingMessage)
                } catch {
                    print("❌ [HeyGenVM] Failed to send opening message: \(error)")
                }
            }
        }
    }

    // Required delegate methods (can be empty)
    func room(_ room: Room, participant: LocalParticipant, didPublishTrack publication: LocalTrackPublication) {}
    func room(_ room: Room, participant: LocalParticipant, didFailToPublish track: LocalTrackPublication, error: Error) {}
    func room(_ room: Room, participant: LocalParticipant, didUnpublishTrack publication: LocalTrackPublication) {}
    func room(_ room: Room, trackPublication: TrackPublication, didReceiveTranscriptionSegments segments: [TranscriptionSegment]) {}
    func room(_ room: Room, trackPublication: TrackPublication, didUpdateE2EEState state: E2EEState) {}
    func room(_ room: Room, participant: Participant, didUpdatePermissions permissions: ParticipantPermissions) {}
    func room(_ room: Room, didUpdateSpeakingParticipants participants: [Participant]) {}
    func room(_ room: Room, participant: LocalParticipant, remoteDidSubscribeTrack publication: LocalTrackPublication) {}
}
