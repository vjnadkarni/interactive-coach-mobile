import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/native_speech_service.dart';
import 'health_dashboard_screen.dart';
import 'chat_screen.dart';
import 'user_dashboard_screen.dart';

class AvatarScreenNative extends StatefulWidget {
  const AvatarScreenNative({super.key});

  @override
  State<AvatarScreenNative> createState() => _AvatarScreenNativeState();
}

class _AvatarScreenNativeState extends State<AvatarScreenNative> {
  final ApiService _apiService = ApiService();
  final NativeSpeechService _nativeSpeech = NativeSpeechService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  MethodChannel? _avatarChannel;

  bool _isListening = false;
  bool _isLoading = false;
  bool _speechAvailable = false;
  bool _sessionStarted = false;
  String _userId = 'default_user';
  String _avatarStatus = 'Tap Start to begin';
  String _currentTranscript = '';
  Timer? _silenceTimer;
  List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _stopSession();
    _stopListening();
    _silenceTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // MARK: - Speech Recognition

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _nativeSpeech.initialize();

      // Listen to final transcripts
      _nativeSpeech.finalTranscriptStream.listen((transcript) {
        print('✅ [AvatarScreenNative] Final transcript: "$transcript"');

        // Cancel silence timer
        _silenceTimer?.cancel();

        // Send to backend and get response
        _textController.text = transcript;
        _sendMessage(transcript);

        // Reset
        _currentTranscript = '';
        _stopListening();
      });

      // Listen to interim transcripts for display
      _nativeSpeech.transcriptStream.listen((transcript) {
        print('📝 [AvatarScreenNative] Interim transcript: "$transcript"');

        setState(() {
          _currentTranscript = transcript;
        });

        // Reset silence timer
        _silenceTimer?.cancel();
        _silenceTimer = Timer(const Duration(seconds: 3, milliseconds: 500), () {
          print('⏱️ [AvatarScreenNative] Silence detected, processing transcript');

          // Process the current accumulated transcript
          if (_currentTranscript.isNotEmpty) {
            print('📤 [AvatarScreenNative] Sending accumulated transcript: "$_currentTranscript"');

            // Send to backend
            _textController.text = _currentTranscript;
            _sendMessage(_currentTranscript);

            // Reset
            setState(() {
              _currentTranscript = '';
            });
          }

          _nativeSpeech.stopListening();
        });
      });

      setState(() {
        _avatarStatus = _speechAvailable
            ? 'Ready - Tap Start'
            : 'Speech recognition not available';
      });

    } catch (e) {
      print('❌ [AvatarScreenNative] Failed to initialize speech: $e');
      setState(() {
        _avatarStatus = 'Speech unavailable: $e';
      });
    }
  }

  void _startListening() async {
    if (!_speechAvailable || _isListening) return;

    try {
      await _nativeSpeech.startListening();
      setState(() {
        _isListening = true;
        _avatarStatus = 'Listening...';
        _currentTranscript = '';
      });
    } catch (e) {
      print('❌ [AvatarScreenNative] Failed to start listening: $e');
    }
  }

  void _stopListening() async {
    if (!_isListening) return;

    try {
      await _nativeSpeech.stopListening();
      setState(() {
        _isListening = false;
        _avatarStatus = _sessionStarted ? 'Ready - speak again...' : 'Ready - Tap Start';
      });
    } catch (e) {
      print('❌ [AvatarScreenNative] Failed to stop listening: $e');
    }
  }

  // MARK: - Platform View

  void _onPlatformViewCreated(int viewId) {
    _avatarChannel = MethodChannel('heygen_avatar_$viewId');

    // Set up method call handler for callbacks from native code
    _avatarChannel?.setMethodCallHandler(_handleNativeMethod);

    print('✅ [AvatarScreenNative] Platform view created with channel: heygen_avatar_$viewId');
  }

  Future<dynamic> _handleNativeMethod(MethodCall call) async {
    print('📞 [AvatarScreenNative] Received native call: ${call.method}');

    switch (call.method) {
      case 'onSessionStarted':
        setState(() {
          _sessionStarted = true;
          _avatarStatus = 'Session active - Ready to chat';
        });
        break;

      case 'onSessionStopped':
        setState(() {
          _sessionStarted = false;
          _avatarStatus = 'Session ended';
        });
        break;

      case 'onConnected':
        setState(() {
          _avatarStatus = 'Connected to avatar';
        });
        break;

      case 'onDisconnected':
        setState(() {
          _avatarStatus = 'Disconnected';
        });
        break;

      case 'onAvatarStartedSpeaking':
        setState(() {
          _avatarStatus = 'Hera is speaking...';
        });
        break;

      case 'onAvatarStoppedSpeaking':
        setState(() {
          _avatarStatus = 'Ready - speak again...';
        });
        // Restart listening after avatar finishes speaking
        if (_sessionStarted) {
          _startListening();
        }
        break;

      case 'onAvatarMessage':
        // Avatar streamed message (could be used for real-time display)
        final text = call.arguments['text'] as String?;
        print('💬 [AvatarScreenNative] Avatar message: $text');
        break;

      case 'onUserTranscript':
        // User transcript from HeyGen (not used, we have our own speech recognition)
        break;

      default:
        print('⚠️ [AvatarScreenNative] Unknown method: ${call.method}');
    }
  }

  // MARK: - Session Control

  Future<void> _startSession() async {
    if (_avatarChannel == null) {
      print('❌ [AvatarScreenNative] Avatar channel not initialized');
      return;
    }

    setState(() {
      _isLoading = true;
      _avatarStatus = 'Starting session...';
    });

    try {
      await _avatarChannel!.invokeMethod('start', {
        'apiKey': dotenv.env['HEYGEN_API_KEY'] ?? '',
      });
      print('✅ [AvatarScreenNative] HeyGen session started');

      // Start listening automatically
      _startListening();

    } catch (e) {
      print('❌ [AvatarScreenNative] Failed to start session: $e');
      setState(() {
        _avatarStatus = 'Failed to start: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _stopSession() async {
    if (_avatarChannel == null || !_sessionStarted) return;

    try {
      await _avatarChannel!.invokeMethod('stop');
      print('✅ [AvatarScreenNative] HeyGen session stopped');
    } catch (e) {
      print('❌ [AvatarScreenNative] Failed to stop session: $e');
    }
  }

  // MARK: - Message Handling

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message to chat
    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
      });
    });

    _scrollToBottom();

    // Send to backend to get Claude response
    try {
      setState(() {
        _isLoading = true;
        _avatarStatus = 'Hera is thinking...';
      });

      // Stream the response from backend
      final responseBuffer = StringBuffer();

      await for (var chunk in _apiService.streamChat(text, _userId)) {
        responseBuffer.write(chunk);
      }

      final response = responseBuffer.toString();
      print('✅ [AvatarScreenNative] Got response from backend: ${response.substring(0, 100)}...');

      // Add assistant message to chat
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response,
        });
      });

      _scrollToBottom();

      // Send response to HeyGen avatar to speak
      await _speakResponse(response);

    } catch (e) {
      print('❌ [AvatarScreenNative] Failed to get response: $e');
      setState(() {
        _avatarStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _speakResponse(String text) async {
    if (_avatarChannel == null) {
      print('❌ [AvatarScreenNative] Cannot speak - channel not initialized');
      return;
    }

    try {
      // Remove references section (not spoken by avatar)
      final cleanText = _removeReferences(text);

      await _avatarChannel!.invokeMethod('speak', {'text': cleanText});
      print('✅ [AvatarScreenNative] Sent text to avatar: ${cleanText.substring(0, 50)}...');

    } catch (e) {
      print('❌ [AvatarScreenNative] Failed to send text to avatar: $e');
    }
  }

  String _removeReferences(String text) {
    // Remove "References:" section at the end
    return text.replaceAll(RegExp(r'(\n---\nReferences:|\n\nReferences:)[\s\S]*$', caseSensitive: false), '');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // MARK: - UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Hera (Native)'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Session control button
          if (_sessionStarted)
            IconButton(
              icon: const Icon(Icons.stop_circle),
              tooltip: 'End Session',
              onPressed: _stopSession,
            )
          else
            IconButton(
              icon: const Icon(Icons.play_circle),
              tooltip: 'Start Session',
              onPressed: _startSession,
            ),
        ],
      ),
      body: Column(
        children: [
          // Avatar View (Native iOS Platform View)
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  // Native HeyGen Avatar View
                  UiKitView(
                    viewType: 'heygen_avatar_view',
                    layoutDirection: TextDirection.ltr,
                    creationParams: {
                      'apiKey': dotenv.env['HEYGEN_API_KEY'] ?? '',
                    },
                    creationParamsCodec: const StandardMessageCodec(),
                    onPlatformViewCreated: _onPlatformViewCreated,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                    },
                  ),

                  // Status overlay
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _avatarStatus,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // Loading indicator
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                ],
              ),
            ),
          ),

          // Chat Panel
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[100],
              child: Column(
                children: [
                  // Messages list
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isUser = message['role'] == 'user';

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.blue : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              message['content'] ?? '',
                              style: TextStyle(
                                color: isUser ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Current transcript display
                  if (_currentTranscript.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.blue.withOpacity(0.1),
                      child: Text(
                        'You: $_currentTranscript',
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.blue,
                        ),
                      ),
                    ),

                  // Microphone button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Microphone button
                        GestureDetector(
                          onTap: _isListening ? _stopListening : _startListening,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _isListening ? Colors.red : Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isListening ? Colors.red : Theme.of(context).colorScheme.primary).withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Chat tab selected (Video+Voice mode)
        onTap: (index) {
          if (index == 0) {
            // Navigate to Health Dashboard
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HealthDashboardScreen()),
            );
          } else if (index == 2) {
            // Navigate to User Dashboard
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const UserDashboardScreen()),
            );
          }
          // index == 1 is current screen (Chat - Video+Voice), do nothing
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Health',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}
