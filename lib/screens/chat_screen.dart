import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/api_service.dart';
import '../services/tts_service.dart';
import 'health_dashboard_screen.dart';

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
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isListening = false;
  bool _isLoading = false;
  bool _isSpeaking = false;
  String _userId = 'default_user';
  int _selectedIndex = 1; // Chat tab selected by default
  List<Map<String, String>> _messages = [];

  // Mode toggle: false = Voice+Text, true = Video+Voice (coming soon)
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
    _speech.cancel();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );

    if (available) {
      print('✅ Speech recognition initialized');
    } else {
      print('❌ Speech recognition not available');
    }
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
    print('🎤 [ChatScreen] Starting voice input...');

    if (!_speech.isAvailable) {
      print('❌ [ChatScreen] Speech recognition not available');
      _addMessage('error', 'Speech recognition not available. Please check microphone permissions.');
      return;
    }

    print('✅ [ChatScreen] Speech recognition available');

    setState(() {
      _isListening = true;
    });

    print('🎤 [ChatScreen] Starting to listen...');

    try {
      await _speech.listen(
        onResult: (result) {
          print('🎤 [ChatScreen] Got result - Final: ${result.finalResult}, Text: "${result.recognizedWords}"');

          if (result.finalResult) {
            final recognizedText = result.recognizedWords;
            print('✅ [ChatScreen] Final recognized text: "$recognizedText"');

            // Send the recognized text
            _sendMessage(recognizedText);

            // Stop listening after final result
            _stopListening();
          } else {
            print('🎤 [ChatScreen] Partial result: "${result.recognizedWords}"');
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      print('🎤 [ChatScreen] Listen method called');
    } catch (e) {
      print('❌ [ChatScreen] Speech error: $e');
      _addMessage('error', 'Speech error: $e');
      _stopListening();
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
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
                      // Show "Coming Soon" dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Video + Voice Mode'),
                          content: const Text(
                            'Video avatar coming soon!\n\nFor now, use Voice + Text mode to chat with Hera.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
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
