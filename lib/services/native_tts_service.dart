import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import '../utils/constants.dart';

/// Native TTS Service using iOS AVAudioPlayer
/// Bypasses just_audio package issues with consecutive playback
class NativeTTSService {
  static const platform = MethodChannel('native_audio_player');
  bool _isPlaying = false;

  /// Generate and play audio from text using ElevenLabs + Native iOS player
  ///
  /// Parameters:
  /// - text: The text to convert to speech
  ///
  /// Returns: true if successful, false otherwise
  Future<bool> speak(String text) async {
    if (_isPlaying) {
      print('⚠️ [NativeTTS] Already playing audio, stopping previous audio');
      await stop();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      print('🔊 [NativeTTS] Generating speech for: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');

      // Strip references section
      final cleanText = _stripReferences(text);

      // CRITICAL FIX: Add explicit silence markers at start
      // Use multiple periods and commas to create ~1 second of silence in ElevenLabs TTS
      // This ensures the actual first word is NOT the first audio in the file
      // Testing showed timer delays don't help - silence must be IN the audio file itself
      final textWithPause = '. . . , , , $cleanText';
      print('📝 [NativeTTS] Clean text (${cleanText.length} chars) + silence markers (dots + commas)');

      // Call ElevenLabs API
      final url = Uri.parse(
        'https://api.elevenlabs.io/v1/text-to-speech/${AppConstants.elevenLabsVoiceId}/stream'
      );

      print('🌐 [NativeTTS] Calling ElevenLabs API...');
      final response = await http.post(
        url,
        headers: {
          'xi-api-key': AppConstants.elevenLabsApiKey,
          'Content-Type': 'application/json',
          'Accept': 'audio/mpeg',  // Request MP3 format
        },
        body: json.encode({
          'text': textWithPause,
          'model_id': 'eleven_monolingual_v1',
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
          },
          // Use high-quality MP3 format (AVAudioPlayer handles MP3 natively)
          'output_format': 'mp3_44100_128',  // MP3 44.1kHz, 128kbps
        }),
      );

      if (response.statusCode != 200) {
        print('❌ [NativeTTS] ElevenLabs API error: ${response.statusCode}');
        print('❌ [NativeTTS] Response body: ${response.body}');
        _isPlaying = false;
        return false;
      }

      print('✅ [NativeTTS] Received audio (${response.bodyBytes.length} bytes)');

      // Play audio using native iOS player
      _isPlaying = true;

      try {
        final result = await platform.invokeMethod('play', {
          'audioData': response.bodyBytes,
        });

        if (result == true) {
          print('✅ [NativeTTS] Native player started successfully');

          // Wait for playback to complete
          await _waitForPlaybackComplete();

          print('✅ [NativeTTS] Audio playback complete');
          _isPlaying = false;
          return true;
        } else {
          print('❌ [NativeTTS] Native player failed to start');
          _isPlaying = false;
          return false;
        }
      } on PlatformException catch (e) {
        print('❌ [NativeTTS] Platform error: ${e.message}');
        _isPlaying = false;
        return false;
      }

    } catch (e, stackTrace) {
      print('❌ [NativeTTS] Error: $e');
      print('❌ [NativeTTS] Stack trace: $stackTrace');
      _isPlaying = false;
      return false;
    }
  }

  /// Wait for native playback to complete
  Future<void> _waitForPlaybackComplete() async {
    // Poll isPlaying status until it becomes false
    while (_isPlaying) {
      await Future.delayed(const Duration(milliseconds: 500));

      try {
        final playing = await platform.invokeMethod('isPlaying');
        if (playing == false) {
          _isPlaying = false;
          break;
        }
      } catch (e) {
        print('⚠️ [NativeTTS] Error checking playback status: $e');
        break;
      }
    }
  }

  /// Stop current audio playback
  Future<void> stop() async {
    if (_isPlaying) {
      print('🛑 [NativeTTS] Stopping audio playback');
      try {
        await platform.invokeMethod('stop');
        _isPlaying = false;
      } catch (e) {
        print('⚠️ [NativeTTS] Error stopping playback: $e');
      }
    }
  }

  /// Strip references section from text before TTS
  String _stripReferences(String text) {
    final pattern = RegExp(r'(\n---\nReferences:|\n\nReferences:)[\s\S]*$', caseSensitive: false);
    final cleanText = text.replaceAll(pattern, '').trim();

    if (cleanText.length < text.length) {
      print('📄 [NativeTTS] Stripped references section (${text.length - cleanText.length} chars removed)');
    }

    return cleanText;
  }

  /// Check if audio is currently playing
  bool get isPlaying => _isPlaying;

  /// Dispose (cleanup)
  void dispose() {
    stop();
  }
}
