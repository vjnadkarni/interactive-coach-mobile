import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-Speech Service using Apple's native AVSpeechSynthesizer
/// Replaces ElevenLabs to fix:
/// 1. First word truncation issue
/// 2. Imperfect transcription of numbers, abbreviations, ranges
class TTSService {
  FlutterTts? _flutterTts;
  bool _isPlaying = false;
  bool _isInitialized = false;

  /// Initialize the TTS engine
  Future<void> _ensureInitialized() async {
    if (_isInitialized && _flutterTts != null) return;

    _flutterTts = FlutterTts();

    // Configure for iOS
    await _flutterTts!.setSharedInstance(true);
    await _flutterTts!.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ],
      IosTextToSpeechAudioMode.voicePrompt,
    );

    // Set voice parameters for natural speech
    await _flutterTts!.setLanguage("en-US");
    await _flutterTts!.setSpeechRate(0.5); // 0.0 to 1.0, 0.5 is normal
    await _flutterTts!.setVolume(1.0);
    await _flutterTts!.setPitch(1.0);

    // Try to use Samantha voice (high quality female voice)
    // Fall back to default if not available
    final voices = await _flutterTts!.getVoices;
    print('🎤 [TTSService] Available voices: ${voices.length}');

    // Look for Samantha or a good alternative
    Map<String, String>? selectedVoice;
    for (var voice in voices) {
      final name = voice['name']?.toString() ?? '';
      final locale = voice['locale']?.toString() ?? '';

      // Prefer Samantha (enhanced) or similar high-quality voices
      if (locale.startsWith('en-US')) {
        if (name.contains('Samantha')) {
          selectedVoice = {'name': name, 'locale': locale};
          print('🎤 [TTSService] Found Samantha voice: $name');
          break;
        }
        // Keep first US English voice as fallback
        selectedVoice ??= {'name': name, 'locale': locale};
      }
    }

    if (selectedVoice != null) {
      await _flutterTts!.setVoice(selectedVoice);
      print('🎤 [TTSService] Using voice: ${selectedVoice['name']}');
    }

    // Set up completion handler
    _flutterTts!.setCompletionHandler(() {
      print('✅ [TTSService] Speech completed');
      _isPlaying = false;
    });

    _flutterTts!.setErrorHandler((msg) {
      print('❌ [TTSService] Error: $msg');
      _isPlaying = false;
    });

    _flutterTts!.setCancelHandler(() {
      print('🛑 [TTSService] Speech cancelled');
      _isPlaying = false;
    });

    _flutterTts!.setStartHandler(() {
      print('▶️ [TTSService] Speech started');
    });

    _isInitialized = true;
    print('✅ [TTSService] Apple TTS initialized');
  }

  /// Generate and play audio from text using Apple TTS
  ///
  /// Parameters:
  /// - text: The text to convert to speech
  ///
  /// Returns: true if successful, false otherwise
  Future<bool> speak(String text) async {
    if (_isPlaying) {
      print('⚠️ [TTSService] Already playing audio, stopping previous audio');
      await stop();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      await _ensureInitialized();

      print('🔊 [TTSService] Generating speech for: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');

      // Strip references section
      final cleanText = _stripReferences(text);
      print('📝 [TTSService] Clean text (${cleanText.length} chars): "${cleanText.substring(0, cleanText.length > 50 ? 50 : cleanText.length)}..."');

      _isPlaying = true;

      // Speak the text
      final result = await _flutterTts!.speak(cleanText);

      if (result != 1) {
        print('❌ [TTSService] speak() returned: $result');
        _isPlaying = false;
        return false;
      }

      // Wait for completion (with timeout)
      final startTime = DateTime.now();
      while (_isPlaying) {
        await Future.delayed(const Duration(milliseconds: 100));

        // Timeout after 60 seconds
        if (DateTime.now().difference(startTime).inSeconds > 60) {
          print('❌ [TTSService] Timeout waiting for speech completion');
          await stop();
          return false;
        }
      }

      print('✅ [TTSService] Audio playback complete');
      return true;

    } catch (e) {
      print('❌ [TTSService] Error: $e');
      print('❌ [TTSService] Stack trace: ${StackTrace.current}');
      _isPlaying = false;
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
    if (_flutterTts != null) {
      print('🛑 [TTSService] Stopping audio playback');
      await _flutterTts!.stop();
      _isPlaying = false;
    }
  }

  /// Strip references section from text before TTS
  /// Removes everything after "---\nReferences:" or "\n\nReferences:"
  String _stripReferences(String text) {
    final pattern = RegExp(r'(\n---\nReferences:|\n\nReferences:)[\s\S]*$', caseSensitive: false);
    final cleanText = text.replaceAll(pattern, '').trim();

    if (cleanText.length < text.length) {
      print('📄 [TTSService] Stripped references section (${text.length - cleanText.length} chars removed)');
    }

    return cleanText;
  }

  /// Check if audio is currently playing
  bool get isPlaying => _isPlaying;

  /// Dispose TTS resources
  void dispose() {
    _flutterTts?.stop();
    _isInitialized = false;
  }
}
