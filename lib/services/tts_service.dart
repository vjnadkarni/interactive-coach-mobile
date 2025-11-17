import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';

/// Custom StreamAudioSource for in-memory audio playback
class BytesAudioSource extends StreamAudioSource {
  final Uint8List _bytes;

  BytesAudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start = start ?? 0;
    end = end ?? _bytes.length;

    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}

/// Text-to-Speech Service using ElevenLabs API
/// Generates audio from text using Rachel voice (same as web app)
class TTSService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _sessionConfigured = false;

  /// Configure audio session for iOS playback
  Future<void> _configureAudioSession() async {
    if (_sessionConfigured) return;

    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      print('✅ [TTSService] Audio session configured for playback');
      _sessionConfigured = true;
    } catch (e) {
      print('⚠️ [TTSService] Failed to configure audio session: $e');
    }
  }

  /// Generate and play audio from text using ElevenLabs
  ///
  /// Parameters:
  /// - text: The text to convert to speech
  ///
  /// Returns: true if successful, false otherwise
  Future<bool> speak(String text) async {
    if (_isPlaying) {
      print('⚠️ [TTSService] Already playing audio, stopping previous audio');
      await stop();
      // Add small delay to ensure stop completes
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      // Configure audio session before playing
      await _configureAudioSession();

      print('🔊 [TTSService] Generating speech for: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');

      // Strip references section (everything after "---\nReferences:" or "\n\nReferences:")
      final cleanText = _stripReferences(text);
      print('📝 [TTSService] Clean text (${cleanText.length} chars): "${cleanText.substring(0, cleanText.length > 50 ? 50 : cleanText.length)}..."');

      final url = Uri.parse(
        'https://api.elevenlabs.io/v1/text-to-speech/${AppConstants.elevenLabsVoiceId}/stream'
      );

      print('🌐 [TTSService] Calling ElevenLabs API...');
      final response = await http.post(
        url,
        headers: {
          'xi-api-key': AppConstants.elevenLabsApiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'text': cleanText,
          'model_id': 'eleven_monolingual_v1',
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
          },
        }),
      );

      if (response.statusCode != 200) {
        print('❌ [TTSService] ElevenLabs API error: ${response.statusCode}');
        print('❌ [TTSService] Response body: ${response.body}');
        _isPlaying = false; // CRITICAL: Reset flag on API error
        return false;
      }

      print('✅ [TTSService] Received audio (${response.bodyBytes.length} bytes)');

      // Play audio using custom StreamAudioSource (no file storage needed!)
      _isPlaying = true;

      final audioSource = BytesAudioSource(response.bodyBytes);
      await _audioPlayer.setAudioSource(audioSource);
      print('🔊 [TTSService] Playing audio from memory stream...');
      await _audioPlayer.play();

      // Wait for playback to complete with timeout
      // If audio doesn't complete in 2 minutes, something is wrong
      try {
        await _audioPlayer.processingStateStream.firstWhere(
          (state) => state == ProcessingState.completed,
        ).timeout(
          const Duration(minutes: 2),
          onTimeout: () {
            print('❌ [TTSService] Audio playback timeout after 2 minutes');
            throw Exception('Audio playback timeout');
          },
        );
      } catch (timeoutError) {
        print('❌ [TTSService] Playback error: $timeoutError');
        _isPlaying = false;
        await stop();
        return false;
      }

      print('✅ [TTSService] Audio playback complete');
      _isPlaying = false;
      return true;

    } catch (e) {
      print('❌ [TTSService] Error: $e');
      print('❌ [TTSService] Stack trace: ${StackTrace.current}');
      _isPlaying = false;
      // Ensure player is stopped on error
      try {
        await stop();
      } catch (stopError) {
        print('⚠️ [TTSService] Error during stop: $stopError');
      }
      return false;
    }
  }

  /// Stop current audio playback
  Future<void> stop() async {
    if (_isPlaying) {
      print('🛑 [TTSService] Stopping audio playback');
      await _audioPlayer.stop();
      _isPlaying = false;
    }
  }

  /// Strip references section from text before TTS
  /// Removes everything after "---\nReferences:" or "\n\nReferences:"
  String _stripReferences(String text) {
    // Pattern matches both "\n---\nReferences:" and "\n\nReferences:"
    final pattern = RegExp(r'(\n---\nReferences:|\n\nReferences:)[\s\S]*$', caseSensitive: false);
    final cleanText = text.replaceAll(pattern, '').trim();

    if (cleanText.length < text.length) {
      print('📄 [TTSService] Stripped references section (${text.length - cleanText.length} chars removed)');
    }

    return cleanText;
  }

  /// Check if audio is currently playing
  bool get isPlaying => _isPlaying;

  /// Dispose audio player resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
