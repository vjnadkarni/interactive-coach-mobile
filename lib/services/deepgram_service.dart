import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import '../utils/constants.dart';

/// Deepgram Speech-to-Text Service
///
/// Provides real-time speech recognition using Deepgram's WebSocket API
/// with excellent punctuation and capitalization support.
class DeepgramService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  StreamSubscription<Uint8List>? _audioStreamSubscription;

  // Stream controllers
  final _transcriptController = StreamController<String>.broadcast();
  final _finalTranscriptController = StreamController<String>.broadcast();

  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<String> get finalTranscriptStream => _finalTranscriptController.stream;

  bool get isConnected => _isConnected;
  bool get isRecording => _isRecording;

  /// Connect to Deepgram WebSocket
  Future<void> connect() async {
    try {
      print('🔵 [DeepgramService] Connecting to Deepgram...');

      final apiKey = AppConstants.deepgramApiKey;
      if (apiKey.isEmpty) {
        throw Exception('Deepgram API key is not configured');
      }

      // Deepgram WebSocket URL with parameters for optimal punctuation
      final wsUrl = Uri.parse(
        'wss://api.deepgram.com/v1/listen?'
        'model=nova-2&'
        'language=en-US&'
        'smart_format=true&'        // Automatic punctuation and capitalization
        'punctuate=true&'            // Add punctuation
        'interim_results=true&'      // Get partial results
        'encoding=linear16&'         // Audio format
        'sample_rate=16000&'         // Sample rate
        'channels=1'                 // Mono audio
      );

      _channel = WebSocketChannel.connect(
        wsUrl,
        protocols: ['token', apiKey],
      );

      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: (error) {
          print('❌ [DeepgramService] WebSocket error: $error');
          _isConnected = false;
          _reconnect();
        },
        onDone: () {
          print('🔴 [DeepgramService] WebSocket disconnected');
          _isConnected = false;
        },
      );

      _isConnected = true;
      print('✅ [DeepgramService] Connected to Deepgram');
    } catch (e) {
      print('❌ [DeepgramService] Connection error: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// Handle incoming WebSocket messages from Deepgram
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = json.decode(message);

      // Deepgram sends transcript data with this structure
      if (data['type'] == 'Results') {
        final channel = data['channel'];
        if (channel != null && channel['alternatives'] != null) {
          final alternatives = channel['alternatives'] as List;
          if (alternatives.isNotEmpty) {
            final transcript = alternatives[0]['transcript'] as String;
            final isFinal = data['is_final'] as bool? ?? false;

            if (transcript.isNotEmpty) {
              if (isFinal) {
                print('✅ [DeepgramService] Final transcript: "$transcript"');
                _finalTranscriptController.add(transcript);
              } else {
                print('📝 [DeepgramService] Interim transcript: "$transcript"');
                _transcriptController.add(transcript);
              }
            }
          }
        }
      }
    } catch (e) {
      print('❌ [DeepgramService] Error parsing message: $e');
    }
  }

  /// Start recording and streaming audio to Deepgram
  Future<void> startRecording() async {
    if (_isRecording) {
      print('⚠️ [DeepgramService] Already recording');
      return;
    }

    if (!_isConnected) {
      print('⚠️ [DeepgramService] Cannot start recording - not connected');
      return;
    }

    try {
      print('🎤 [DeepgramService] Starting audio recording...');

      // Check microphone permission
      if (await _audioRecorder.hasPermission()) {
        // Start recording with streaming
        final stream = await _audioRecorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
        );

        // Listen to audio stream and forward to Deepgram
        _audioStreamSubscription = stream.listen(
          (audioData) {
            if (_isConnected && _channel != null) {
              _channel!.sink.add(audioData);
            }
          },
          onError: (error) {
            print('❌ [DeepgramService] Audio stream error: $error');
          },
        );

        _isRecording = true;
        print('✅ [DeepgramService] Recording started');
      } else {
        print('❌ [DeepgramService] Microphone permission denied');
      }
    } catch (e) {
      print('❌ [DeepgramService] Error starting recording: $e');
      _isRecording = false;
    }
  }

  /// Stop recording audio
  Future<void> stopRecording() async {
    if (!_isRecording) {
      return;
    }

    try {
      print('🎤 [DeepgramService] Stopping audio recording...');

      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;

      await _audioRecorder.stop();
      _isRecording = false;

      print('✅ [DeepgramService] Recording stopped');
    } catch (e) {
      print('❌ [DeepgramService] Error stopping recording: $e');
    }
  }

  /// Attempt to reconnect to Deepgram
  Future<void> _reconnect() async {
    print('🔄 [DeepgramService] Attempting to reconnect...');
    await Future.delayed(const Duration(seconds: 2));

    if (!_isConnected) {
      try {
        await connect();
      } catch (e) {
        print('❌ [DeepgramService] Reconnection failed: $e');
      }
    }
  }

  /// Close the Deepgram connection
  Future<void> disconnect() async {
    try {
      print('🔵 [DeepgramService] Disconnecting from Deepgram...');

      if (_channel != null) {
        // Send close frame to gracefully close connection
        await _channel!.sink.close();
        _channel = null;
      }

      _isConnected = false;
      print('✅ [DeepgramService] Disconnected from Deepgram');
    } catch (e) {
      print('❌ [DeepgramService] Error disconnecting: $e');
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await stopRecording();
    await _audioRecorder.dispose();
    _transcriptController.close();
    _finalTranscriptController.close();
    await disconnect();
  }
}
