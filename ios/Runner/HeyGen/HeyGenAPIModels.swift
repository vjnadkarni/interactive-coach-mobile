//
//  HeyGenAPIModels.swift
//  Runner
//
//  Data models for HeyGen Streaming API
//

import Foundation

// MARK: - Session Request/Response Models

struct CreateSessionRequest: Codable {
    let quality: String
    let avatarName: String
    let voice: Voice?
    let knowledgeBase: String?

    struct Voice: Codable {
        let voiceId: String

        enum CodingKeys: String, CodingKey {
            case voiceId = "voice_id"
        }
    }

    enum CodingKeys: String, CodingKey {
        case quality
        case avatarName = "avatar_name"
        case voice
        case knowledgeBase = "knowledge_base"
    }
}

struct SessionResponse: Codable {
    let data: SessionData?

    struct SessionData: Codable {
        let sessionId: String
        let url: String
        let accessToken: String
        let sdp: SDP?

        struct SDP: Codable {
            let type: String
            let sdp: String
        }

        enum CodingKeys: String, CodingKey {
            case sessionId = "session_id"
            case url
            case accessToken = "access_token"
            case sdp
        }
    }
}

struct StartSessionRequest: Codable {
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
    }
}

struct TokenResponse: Codable {
    let data: TokenData?

    struct TokenData: Codable {
        let token: String
    }
}

// MARK: - Task Request Model

struct TaskRequest: Codable {
    let sessionId: String
    let text: String
    let taskType: String
    let taskMode: String?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case text
        case taskType = "task_type"
        case taskMode = "task_mode"
    }
}

// MARK: - Streaming Events (from WebSocket/LiveKit data channel)

protocol StreamingEvent {
    var type: String { get }
}

struct AvatarStartTalkingEvent: StreamingEvent {
    let type = "avatar_start_talking"
    let taskId: String
}

struct AvatarStopTalkingEvent: StreamingEvent {
    let type = "avatar_stop_talking"
    let taskId: String
}

struct AvatarTalkingMessageEvent: StreamingEvent {
    let type = "avatar_talking_message"
    let message: String
}

struct AvatarTalkingEndEvent: StreamingEvent {
    let type = "avatar_end_message"
}

struct UserTalkingMessageEvent: StreamingEvent {
    let type = "user_talking_message"
    let message: String
}

struct UserTalkingEndEvent: StreamingEvent {
    let type = "user_end_message"
}

struct UserStartTalkingEvent: StreamingEvent {
    let type = "user_start"
}

struct UserStopTalkingEvent: StreamingEvent {
    let type = "user_stop"
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable, Hashable {
    let id: UUID
    let isUser: Bool
    let text: String

    init(id: UUID = UUID(), isUser: Bool, text: String) {
        self.id = id
        self.isUser = isUser
        self.text = text
    }
}
