import 'package:flutter/services.dart';

/// Apple Native TTS Service using iOS AVSpeechSynthesizer
/// Provides instant, intelligent text-to-speech with Samantha voice
class AppleTTSService {
  static const platform = MethodChannel('apple_tts');
  bool _isPlaying = false;

  AppleTTSService() {
    // Listen for completion callbacks from native side
    platform.setMethodCallHandler(_handleNativeMethod);
  }

  Future<void> _handleNativeMethod(MethodCall call) async {
    switch (call.method) {
      case 'onSpeechComplete':
        print('✅ [AppleTTS] Speech complete callback received');
        _isPlaying = false;
        break;
      default:
        print('⚠️ [AppleTTS] Unknown method: ${call.method}');
    }
  }

  /// Speak text using Apple's native TTS engine
  ///
  /// Benefits over ElevenLabs:
  /// - Intelligent text processing (handles ranges, numbers, dates automatically)
  /// - Zero latency (no API call)
  /// - Works offline
  /// - Free (no API costs)
  /// - Handles "3-4" as "three to four" correctly
  ///
  /// Parameters:
  /// - text: The text to convert to speech
  ///
  /// Returns: true if successful, false otherwise
  Future<bool> speak(String text) async {
    if (_isPlaying) {
      print('⚠️ [AppleTTS] Already playing audio, stopping previous audio');
      await stop();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      print('🔊 [AppleTTS] Speaking: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');

      // Strip references section (just like ElevenLabs version)
      final cleanText = _stripReferences(text);
      print('📝 [AppleTTS] Clean text (${cleanText.length} chars)');

      _isPlaying = true;

      // Call native iOS TTS
      print('🚀 [AppleTTS] Calling platform.invokeMethod("speak")...');
      final result = await platform.invokeMethod('speak', {
        'text': cleanText,
        'voice': 'com.apple.ttsbundle.Samantha-compact',  // Samantha voice
        'rate': 0.5,     // Speech rate (0.0-1.0, default 0.5)
        'pitch': 1.0,    // Pitch (0.5-2.0, default 1.0)
        'volume': 1.0,   // Volume (0.0-1.0)
      });

      print('✅ [AppleTTS] platform.invokeMethod returned: $result (type: ${result.runtimeType})');
      print('✅ [AppleTTS] Speech started successfully');
      return result == true;

    } catch (e) {
      print('❌ [AppleTTS] Error: $e');
      print('❌ [AppleTTS] Error type: ${e.runtimeType}');
      print('❌ [AppleTTS] Stack trace: ${StackTrace.current}');
      _isPlaying = false;
      return false;
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    if (!_isPlaying) return;

    try {
      await platform.invokeMethod('stop');
      print('🛑 [AppleTTS] Speech stopped');
    } catch (e) {
      print('❌ [AppleTTS] Error stopping: $e');
    } finally {
      _isPlaying = false;
    }
  }

  /// Check if currently speaking
  bool get isPlaying => _isPlaying;

  /// Set playing state (called from native side via callback)
  void setPlaying(bool playing) {
    _isPlaying = playing;
  }

  /// Dispose of resources (required by Flutter widget lifecycle)
  Future<void> dispose() async {
    await stop();
    print('🧹 [AppleTTS] Disposed');
  }

  /// Strip "References:" section from text
  /// Same logic as ElevenLabs version for consistency
  String _stripReferences(String text) {
    // Remove everything from "References:" or "---\nReferences:" onwards
    final referencesPattern = RegExp(
      r'(\n---\nReferences:|\n\nReferences:)[\s\S]*$',
      caseSensitive: false,
    );

    final cleanedText = text.replaceAll(referencesPattern, '');

    if (text != cleanedText) {
      print('📝 [AppleTTS] Stripped References section');
    }

    return cleanedText;
  }
}
