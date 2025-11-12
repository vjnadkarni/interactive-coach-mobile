import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../services/native_speech_service.dart';
import 'health_dashboard_screen.dart';
import 'avatar_screen.dart';

/// Voice + Text Chat Screen (No Avatar)
///
/// Provides text and voice input for chatting with Hera
/// without the video avatar (WebView) component.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TTSService _ttsService = TTSService();
  final NativeSpeechService _nativeSpeech = NativeSpeechService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isListening = false;
  bool _isLoading = false;
  bool _isSpeaking = false;
  bool _speechAvailable = false;
  String _userId = 'default_user';
  int _selectedIndex = 1; // Chat tab selected by default
  List<Map<String, String>> _messages = [];
  String _currentTranscript = '';
  Timer? _silenceTimer;

  // Mode toggle: false = Voice+Text, true = Video+Voice
  bool _videoMode = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _addMessage('assistant', 'Hi! I\'m Hera, your health and wellness coach. How can I help you today?');
  }

  @override
  void dispose() {
    _ttsService.dispose();
    _silenceTimer?.cancel();
    _nativeSpeech.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _nativeSpeech.initialize();

    // Listen to final transcripts
    _nativeSpeech.finalTranscriptStream.listen((transcript) {
      print('✅ [ChatScreen] Final transcript: "$transcript"');
      _silenceTimer?.cancel();
      _sendMessage(transcript);
      _currentTranscript = '';
      _stopListening();
    });

    // Listen to interim transcripts
    _nativeSpeech.transcriptStream.listen((transcript) {
      print('📝 [ChatScreen] Interim transcript: "$transcript"');
      setState(() {
        _currentTranscript = transcript;
      });
      _resetSilenceTimer();
    });

    // Listen to errors
    _nativeSpeech.errorStream.listen((error) {
      print('❌ [ChatScreen] Speech error: $error');
      _addMessage('error', 'Speech recognition error: $error');
      _stopListening();
    });

    setState(() {});
    print('🎤 [ChatScreen] Native speech available: $_speechAvailable');
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 3), () {
      if (_currentTranscript.isNotEmpty) {
        print('⏱️ [ChatScreen] Silence timeout - sending: "$_currentTranscript"');
        _sendMessage(_currentTranscript);
        _currentTranscript = '';
        _stopListening();
      }
    });
  }

  void _addMessage(String role, String content) {
    setState(() {
      _messages.add({'role': role, 'content': content});
    });

    // Auto-scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    print('📤 [ChatScreen] Sending message: "$message"');
    print('📤 [ChatScreen] User ID: $_userId');

    // Add user message to chat
    _addMessage('user', message);
    _textController.clear();

    setState(() {
      _isLoading = true;
    });

    try {
      // Stream response from backend API
      String fullResponse = '';
      int chunkCount = 0;

      print('🔄 [ChatScreen] Starting stream...');

      await for (var chunk in _apiService.streamChat(message, _userId)) {
        chunkCount++;
        fullResponse += chunk;
        print('📥 [ChatScreen] Chunk $chunkCount: "$chunk"');

        // Update the last message (assistant response) with accumulated text
        if (_messages.isNotEmpty && _messages.last['role'] == 'assistant') {
          setState(() {
            _messages[_messages.length - 1]['content'] = fullResponse;
          });
        } else {
          // First chunk - add new assistant message
          _addMessage('assistant', fullResponse);
        }

        // Auto-scroll to bottom as text streams in
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      }

      print('✅ [ChatScreen] Stream complete. Total chunks: $chunkCount');
      print('✅ [ChatScreen] Full response length: ${fullResponse.length} chars');

      // Play audio response using TTS
      if (fullResponse.isNotEmpty) {
        setState(() {
          _isSpeaking = true;
        });

        print('🔊 [ChatScreen] Playing audio response...');
        final success = await _ttsService.speak(fullResponse);

        setState(() {
          _isSpeaking = false;
        });

        if (success) {
          print('✅ [ChatScreen] Audio playback complete');
        } else {
          print('⚠️ [ChatScreen] Audio playback failed (non-blocking)');
        }
      }

    } catch (e) {
      print('❌ [ChatScreen] Error sending message: $e');
      print('❌ [ChatScreen] Stack trace: ${StackTrace.current}');
      _addMessage('error', 'Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startListening() async {
    if (!_speechAvailable) {
      print('❌ [ChatScreen] Speech not available');
      _addMessage('error', 'Speech recognition not available on this device');
      return;
    }

    print('🎤 [ChatScreen] Starting native iOS speech recognition with enhanced punctuation...');

    setState(() {
      _isListening = true;
      _currentTranscript = '';
    });

    await _nativeSpeech.startListening();

    print('✅ [ChatScreen] Native speech listening started');
  }

  void _stopListening() async {
    await _nativeSpeech.stopListening();
    _silenceTimer?.cancel();

    setState(() {
      _isListening = false;
    });

    print('🛑 [ChatScreen] Native speech stopped');
  }

  void _onNavItemTapped(int index) {
    if (index == 0) {
      // Navigate to Health Dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HealthDashboardScreen()),
      );
    } else if (index == 2) {
      // Navigate to User Dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User Dashboard - Coming Soon')),
      );
    }
    // index == 1 is current screen (Chat), do nothing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Hera'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Mode Toggle Switch
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Text(
                  'Video',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                Switch(
                  value: _videoMode,
                  onChanged: (value) {
                    if (value) {
                      // Navigate to Avatar Screen (Video + Voice mode)
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const AvatarScreen()),
                      );
                    }
                  },
                  activeColor: Colors.white,
                  inactiveThumbColor: Colors.white70,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                final isError = message['role'] == 'error';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isError
                          ? Colors.red.shade100
                          : isUser
                              ? Colors.blue.shade100
                              : Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Text(
                      message['content'] ?? '',
                      style: TextStyle(
                        color: isError ? Colors.red.shade900 : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),

          // Interim transcript display (while listening)
          if (_isListening && _currentTranscript.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentTranscript,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input area
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
              children: [
                // Microphone button
                IconButton(
                  onPressed: () {
                    print('🎙️ [ChatScreen] Mic button pressed! isListening=$_isListening');
                    if (_isListening) {
                      _stopListening();
                    } else {
                      _startListening();
                    }
                  },
                  icon: Icon(
                    _isListening ? Icons.mic_off : Icons.mic,
                    color: _isListening ? Colors.red : Theme.of(context).colorScheme.primary,
                  ),
                  iconSize: 32,
                  tooltip: _isListening ? 'Stop listening' : 'Start voice input',
                ),
                const SizedBox(width: 8),

                // Text input field
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: _isListening ? 'Listening...' : 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (value) => _sendMessage(value),
                    enabled: !_isListening && !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                IconButton(
                  onPressed: _isLoading || _isListening
                      ? null
                      : () => _sendMessage(_textController.text),
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).colorScheme.primary,
                  iconSize: 32,
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
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
