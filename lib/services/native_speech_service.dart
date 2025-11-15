import 'dart:async';
import 'package:flutter/services.dart';

/// Native iOS Speech Recognition Service with Enhanced Punctuation
///
/// This service provides direct access to Apple's SFSpeech framework
/// with the `addsPunctuation` flag enabled for excellent punctuation quality.
class NativeSpeechService {
  static const MethodChannel _channel = MethodChannel('native_speech_recognizer');

  // Stream controllers for transcript results
  final _transcriptController = StreamController<String>.broadcast();
  final _finalTranscriptController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<String> get finalTranscriptStream => _finalTranscriptController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool _isListening = false;
  bool get isListening => _isListening;

  NativeSpeechService() {
    // Set up method call handler for callbacks from iOS
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onResult':
        final Map<dynamic, dynamic> args = call.arguments;
        final String transcript = args['transcript'] as String;
        final bool isFinal = args['isFinal'] as bool;

        if (isFinal) {
          print('✅ [NativeSpeech] Final transcript: "$transcript"');
          _finalTranscriptController.add(transcript);
        } else {
          print('📝 [NativeSpeech] Interim transcript: "$transcript"');
          _transcriptController.add(transcript);
        }
        break;

      case 'onError':
        final String error = call.arguments as String;

        // Filter out "canceled" errors - these are expected when stopping
        if (error.toLowerCase().contains('canceled') || error.toLowerCase().contains('cancelled')) {
          print('ℹ️ [NativeSpeech] Recognition canceled (expected)');
          _isListening = false;
          return;
        }

        print('❌ [NativeSpeech] Error: $error');
        _errorController.add(error);
        _isListening = false;
        break;

      case 'onAvailabilityChanged':
        final bool available = call.arguments as bool;
        print('🔔 [NativeSpeech] Availability changed: $available');
        break;
    }
  }

  /// Initialize the speech recognizer and request permissions
  Future<bool> initialize() async {
    try {
      final bool result = await _channel.invokeMethod('initialize');
      print('✅ [NativeSpeech] Initialized: $result');
      return result;
    } catch (e) {
      print('❌ [NativeSpeech] Initialization failed: $e');
      return false;
    }
  }

  /// Check if speech recognition permission is granted
  Future<bool> hasPermission() async {
    try {
      final bool result = await _channel.invokeMethod('hasPermission');
      return result;
    } catch (e) {
      print('❌ [NativeSpeech] Permission check failed: $e');
      return false;
    }
  }

  /// Start listening with enhanced punctuation support
  Future<void> startListening() async {
    if (_isListening) {
      print('⚠️ [NativeSpeech] Already listening');
      return;
    }

    try {
      print('🎤 [NativeSpeech] Starting speech recognition...');
      await _channel.invokeMethod('startListening');
      _isListening = true;
      print('✅ [NativeSpeech] Listening started');
    } catch (e) {
      print('❌ [NativeSpeech] Failed to start listening: $e');
      _errorController.add(e.toString());
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) {
      return;
    }

    try {
      print('🛑 [NativeSpeech] Stopping speech recognition...');
      await _channel.invokeMethod('stopListening');
      _isListening = false;
      print('✅ [NativeSpeech] Listening stopped');
    } catch (e) {
      print('❌ [NativeSpeech] Failed to stop listening: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    stopListening();
    _transcriptController.close();
    _finalTranscriptController.close();
    _errorController.close();
  }
}
