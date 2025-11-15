//
//  HeyGenAPI.swift
//  Runner
//
//  HeyGen Streaming API client
//

import Foundation

enum HeyGenAPIError: Error {
    case invalidURL
    case invalidResponse
    case serverError(String)
    case decodingError(Error)
    case networkError(Error)
}

class HeyGenAPI {
    private let baseURL = HeyGenConfig.baseUrl

    // MARK: - Create New Session

    func createSession() async throws -> SessionResponse.SessionData {
        let endpoint = "/v1/streaming.new"
        guard let url = URL(string: baseURL + endpoint) else {
            throw HeyGenAPIError.invalidURL
        }

        let request = CreateSessionRequest(
            quality: HeyGenConfig.AvatarSettings.quality,
            avatarName: HeyGenConfig.AvatarSettings.avatarId,
            voice: CreateSessionRequest.Voice(voiceId: HeyGenConfig.AvatarSettings.voiceId),
            knowledgeBase: nil  // We use our own backend for responses
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(HeyGenConfig.apiKey, forHTTPHeaderField: "X-Api-Key")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        print("🌐 [HeyGenAPI] POST \(url)")
        print("🔑 [HeyGenAPI] API Key: \(HeyGenConfig.apiKey.prefix(10))...")
        print("📤 [HeyGenAPI] Request body: \(String(data: urlRequest.httpBody!, encoding: .utf8) ?? "N/A")")

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [HeyGenAPI] Invalid HTTP response")
                throw HeyGenAPIError.invalidResponse
            }

            print("📥 [HeyGenAPI] Response status: \(httpResponse.statusCode)")
            print("📥 [HeyGenAPI] Response body: \(String(data: data, encoding: .utf8) ?? "N/A")")

            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ [HeyGenAPI] Server error: \(errorMessage)")
                throw HeyGenAPIError.serverError("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }

            let sessionResponse = try JSONDecoder().decode(SessionResponse.self, from: data)

            guard let sessionData = sessionResponse.data else {
                throw HeyGenAPIError.invalidResponse
            }

            return sessionData

        } catch let error as DecodingError {
            throw HeyGenAPIError.decodingError(error)
        } catch let error as HeyGenAPIError {
            throw error
        } catch {
            throw HeyGenAPIError.networkError(error)
        }
    }

    // MARK: - Start Session

    func startSession(sessionId: String) async throws {
        let endpoint = "/v1/streaming.start"
        guard let url = URL(string: baseURL + endpoint) else {
            throw HeyGenAPIError.invalidURL
        }

        let requestBody: [String: String] = ["session_id": sessionId]

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(HeyGenConfig.apiKey, forHTTPHeaderField: "X-Api-Key")
        urlRequest.httpBody = try JSONEncoder().encode(requestBody)

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw HeyGenAPIError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw HeyGenAPIError.serverError("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }

        } catch let error as HeyGenAPIError {
            throw error
        } catch {
            throw HeyGenAPIError.networkError(error)
        }
    }

    // MARK: - Stop Session

    func stopSession(sessionId: String) async throws {
        let endpoint = "/v1/streaming.stop"
        guard let url = URL(string: baseURL + endpoint) else {
            throw HeyGenAPIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(HeyGenConfig.apiKey, forHTTPHeaderField: "X-Api-Key")

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw HeyGenAPIError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw HeyGenAPIError.serverError("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }

        } catch let error as HeyGenAPIError {
            throw error
        } catch {
            throw HeyGenAPIError.networkError(error)
        }
    }

    // MARK: - Create Token for WebSocket

    func createToken(sessionId: String) async throws -> String {
        let endpoint = "/v1/streaming.ice"
        guard let url = URL(string: baseURL + endpoint) else {
            throw HeyGenAPIError.invalidURL
        }

        let requestBody: [String: String] = ["session_id": sessionId]

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(HeyGenConfig.apiKey, forHTTPHeaderField: "X-Api-Key")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw HeyGenAPIError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw HeyGenAPIError.serverError("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }

            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

            guard let token = tokenResponse.data?.token else {
                throw HeyGenAPIError.invalidResponse
            }

            return token

        } catch let error as DecodingError {
            throw HeyGenAPIError.decodingError(error)
        } catch let error as HeyGenAPIError {
            throw error
        } catch {
            throw HeyGenAPIError.networkError(error)
        }
    }

    // MARK: - Send Task (Text to Avatar)

    func sendTask(sessionId: String, accessToken: String, text: String) async throws {
        let endpoint = "/v1/streaming.task"
        guard let url = URL(string: baseURL + endpoint) else {
            throw HeyGenAPIError.invalidURL
        }

        let request = TaskRequest(
            sessionId: sessionId,
            text: text,
            taskType: "repeat",  // Avatar speaks exact text
            taskMode: "sync"
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(HeyGenConfig.apiKey, forHTTPHeaderField: "X-Api-Key")
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        print("🌐 [HeyGenAPI] POST \(url)")
        print("📤 [HeyGenAPI] Task request: \(String(data: urlRequest.httpBody!, encoding: .utf8) ?? "N/A")")

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [HeyGenAPI] Invalid HTTP response for task")
                throw HeyGenAPIError.invalidResponse
            }

            print("📥 [HeyGenAPI] Task response status: \(httpResponse.statusCode)")
            print("📥 [HeyGenAPI] Task response body: \(String(data: data, encoding: .utf8) ?? "N/A")")

            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ [HeyGenAPI] Task server error: \(errorMessage)")
                throw HeyGenAPIError.serverError("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }

        } catch let error as HeyGenAPIError {
            throw error
        } catch {
            throw HeyGenAPIError.networkError(error)
        }
    }
}
