//
//  HeyGenAvatarViewController.swift
//  Runner
//
//  Native iOS View Controller for HeyGen Interactive Avatar
//  Integrates with Flutter via Platform Channel
//

import UIKit
import Flutter

class HeyGenAvatarViewController: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var viewModel: HeyGenAvatarViewModel?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView(frame: frame)
        super.init()

        // Parse arguments from Flutter
        var apiKey: String?
        if let argsDict = args as? [String: Any] {
            apiKey = argsDict["apiKey"] as? String
        }

        // Set API key if provided
        if let key = apiKey {
            UserDefaults.standard.set(key, forKey: "HEYGEN_API_KEY")
        }

        // Create method channel for communication with Flutter
        let channel = FlutterMethodChannel(
            name: "heygen_avatar_\(viewId)",
            binaryMessenger: messenger
        )

        // Initialize view model
        viewModel = HeyGenAvatarViewModel(
            containerView: _view,
            methodChannel: channel
        )

        // Set up method call handler
        channel.setMethodCallHandler { [weak self] (call, result) in
            self?.handle(call, result: result)
        }
    }

    func view() -> UIView {
        return _view
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let viewModel = viewModel else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "ViewModel not initialized", details: nil))
            return
        }

        switch call.method {
        case "start":
            // Extract API key from arguments
            if let args = call.arguments as? [String: Any],
               let apiKey = args["apiKey"] as? String {
                // Store API key in UserDefaults for HeyGenConfig to access
                UserDefaults.standard.set(apiKey, forKey: "HEYGEN_API_KEY")
                print("✅ [HeyGenVC] Stored API key in UserDefaults")
            } else {
                print("⚠️ [HeyGenVC] No API key provided in arguments")
            }

            Task {
                do {
                    try await viewModel.startSession()
                    await MainActor.run {
                        result(nil)
                    }
                } catch {
                    await MainActor.run {
                        result(FlutterError(
                            code: "START_FAILED",
                            message: error.localizedDescription,
                            details: nil
                        ))
                    }
                }
            }

        case "stop":
            Task {
                do {
                    try await viewModel.stopSession()
                    await MainActor.run {
                        result(nil)
                    }
                } catch {
                    await MainActor.run {
                        result(FlutterError(
                            code: "STOP_FAILED",
                            message: error.localizedDescription,
                            details: nil
                        ))
                    }
                }
            }

        case "speak":
            guard let args = call.arguments as? [String: Any],
                  let text = args["text"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing 'text' argument", details: nil))
                return
            }

            Task {
                do {
                    try await viewModel.speak(text: text)
                    await MainActor.run {
                        result(nil)
                    }
                } catch {
                    await MainActor.run {
                        result(FlutterError(
                            code: "SPEAK_FAILED",
                            message: error.localizedDescription,
                            details: nil
                        ))
                    }
                }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - Platform View Factory

class HeyGenAvatarViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return HeyGenAvatarViewController(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
