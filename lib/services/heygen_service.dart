import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/constants.dart';

class HeyGenService {
  WebSocketChannel? _channel;
  String? _sessionId;
  bool _isConnected = false;
  String? _streamUrl;

  // Stream controllers for avatar events
  final _streamUrlController = StreamController<String>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  Stream<String> get streamUrlStream => _streamUrlController.stream;
  Stream<String> get statusStream => _statusController.stream;

  bool get isConnected => _isConnected;
  String? get streamUrl => _streamUrl;

  // Initialize HeyGen session
  Future<bool> initializeSession() async {
    try {
      print('🔵 Initializing HeyGen session...');

      final url = Uri.parse('https://api.heygen.com/v1/streaming.new');
      final response = await http.post(
        url,
        headers: {
          'X-Api-Key': AppConstants.heygenApiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'quality': 'high',
          'avatar_name': AppConstants.avatarId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _sessionId = data['data']['session_id'];
        final serverUrl = data['data']['url'];

        print('✅ HeyGen session created: $_sessionId');

        // Connect WebSocket
        await _connectWebSocket(serverUrl);

        return true;
      } else {
        print('❌ HeyGen session failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ HeyGen initialization error: $e');
      return false;
    }
  }

  // Connect to HeyGen WebSocket
  Future<void> _connectWebSocket(String serverUrl) async {
    try {
      print('🔵 Connecting to HeyGen WebSocket...');

      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));

      _channel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _isConnected = false;
          _statusController.add('error');
        },
        onDone: () {
          print('🔴 WebSocket disconnected');
          _isConnected = false;
          _statusController.add('disconnected');
        },
      );

      print('✅ WebSocket connected');
    } catch (e) {
      print('❌ WebSocket connection error: $e');
    }
  }

  // Handle WebSocket messages
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final type = data['type'];

      print('📨 HeyGen message: $type');

      switch (type) {
        case 'stream_ready':
          _streamUrl = data['url'];
          _isConnected = true;
          _streamUrlController.add(_streamUrl!);
          _statusController.add('ready');
          print('✅ Stream ready: $_streamUrl');
          break;

        case 'avatar_start_talking':
          _statusController.add('talking');
          break;

        case 'avatar_stop_talking':
          _statusController.add('idle');
          break;

        case 'error':
          print('❌ HeyGen error: ${data['message']}');
          _statusController.add('error');
          break;
      }
    } catch (e) {
      print('❌ Error handling WebSocket message: $e');
    }
  }

  // Start avatar session
  Future<void> startSession() async {
    if (!_isConnected || _channel == null) {
      print('❌ Cannot start session: Not connected');
      return;
    }

    try {
      print('🔵 Starting HeyGen avatar session...');

      _channel!.sink.add(json.encode({
        'type': 'start',
      }));

      print('✅ Avatar session started');
    } catch (e) {
      print('❌ Error starting session: $e');
    }
  }

  // Send text to avatar (make Hera speak)
  Future<void> speak(String text) async {
    if (!_isConnected || _channel == null) {
      print('❌ Cannot speak: Not connected');
      return;
    }

    try {
      // Remove emojis from text (sounds awkward when spoken)
      final cleanText = _removeEmojis(text);

      print('🗣️ Hera speaking: $cleanText');

      _channel!.sink.add(json.encode({
        'type': 'repeat',
        'text': cleanText,
        'task_type': 'repeat',
      }));
    } catch (e) {
      print('❌ Error sending speech: $e');
    }
  }

  // Remove emojis from text
  String _removeEmojis(String text) {
    return text.replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}]|'  // Emoticons
        r'[\u{1F300}-\u{1F5FF}]|'  // Misc Symbols and Pictographs
        r'[\u{1F680}-\u{1F6FF}]|'  // Transport and Map
        r'[\u{1F1E0}-\u{1F1FF}]|'  // Flags
        r'[\u{2600}-\u{26FF}]|'    // Misc symbols
        r'[\u{2700}-\u{27BF}]|'    // Dingbats
        r'[\u{FE00}-\u{FE0F}]|'    // Variation Selectors
        r'[\u{1F900}-\u{1F9FF}]|'  // Supplemental Symbols and Pictographs
        r'[\u{1FA70}-\u{1FAFF}]',  // Symbols and Pictographs Extended-A
        unicode: true,
      ),
      '',
    ).trim();
  }

  // Close session
  Future<void> closeSession() async {
    try {
      print('🔵 Closing HeyGen session...');

      if (_channel != null) {
        _channel!.sink.add(json.encode({
          'type': 'stop',
        }));

        await Future.delayed(const Duration(milliseconds: 500));
        await _channel!.sink.close();
        _channel = null;
      }

      _isConnected = false;
      _sessionId = null;
      _streamUrl = null;

      print('✅ HeyGen session closed');
    } catch (e) {
      print('❌ Error closing session: $e');
    }
  }

  void dispose() {
    _streamUrlController.close();
    _statusController.close();
    closeSession();
  }
}
