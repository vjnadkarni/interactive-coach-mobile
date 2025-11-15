//
//  HeyGenConfig.swift
//  Runner
//
//  Created for Interactive Coach - Native HeyGen Avatar Implementation
//

import Foundation

struct HeyGenConfig {
    // API Configuration
    static let baseUrl: String = "https://api.heygen.com"

    // Get API key from environment or Flutter
    static var apiKey: String {
        // Will be set via Flutter platform channel
        return UserDefaults.standard.string(forKey: "HEYGEN_API_KEY") ?? ""
    }

    // Avatar Configuration
    struct AvatarSettings {
        static let avatarId: String = "Marianne_Chair_Sitting_public"
        static let quality: String = "high"
        static let voiceId: String = "834239226a1242e89a9fe228e0ba61d4" // ElevenLabs Rachel voice

        // Opening message when avatar starts
        static let openingMessage: String = "Hi! I'm Hera, your health and wellness coach. I'm here to help you with fitness, nutrition, and reaching your health goals. What would you like to work on today?"
    }
}
