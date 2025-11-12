import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:webview_flutter/webview_flutter.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'health_test_screen.dart';
import 'health_dashboard_screen.dart';
import 'chat_screen.dart';

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  final ApiService _apiService = ApiService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late WebViewController _webViewController;
  bool _isListening = false;
  bool _isLoading = false;
  bool _isWebViewReady = false;
  String _userId = 'default_user';
  String _avatarStatus = 'Loading...';
  List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initWebView();
    _addMessage('assistant', 'Hi! I\'m Hera, your health and wellness coach. How can I help you today?');
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

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print('🔵 WebView loading: $progress%');
          },
          onPageStarted: (String url) {
            print('🔵 Page started loading: $url');
            setState(() {
              _avatarStatus = 'Connecting...';
            });
          },
          onPageFinished: (String url) {
            print('✅ Page finished loading: $url');
            setState(() {
              _isWebViewReady = true;
              _avatarStatus = 'Ready';
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView error: ${error.description}');
            setState(() {
              _avatarStatus = 'Error loading avatar';
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleWebViewMessage(message.message);
        },
      )
      ..loadRequest(Uri.parse(AppConstants.mobileAvatarUrl));
  }

  void _handleWebViewMessage(String message) {
    print('📨 Message from WebView: $message');

    try {
      // Parse JSON message from WebView
      // Expected format: {"type": "status", "status": "speaking"}
      // For now, just log it
      setState(() {
        if (message.contains('speaking')) {
          _avatarStatus = 'Speaking';
        } else if (message.contains('listening')) {
          _avatarStatus = 'Listening';
        } else if (message.contains('ready')) {
          _avatarStatus = 'Ready';
        }
      });
    } catch (e) {
      print('Error parsing WebView message: $e');
    }
  }

  void _sendToWebView(String type, String text) {
    if (!_isWebViewReady) {
      print('⚠️ WebView not ready yet');
      return;
    }

    // Send message to WebView JavaScript
    final jsCode = '''
      window.postMessage({
        type: '$type',
        text: `$text`
      }, '*');
    ''';

    _webViewController.runJavaScript(jsCode);
    print('📤 Sent to WebView: $type');
  }

  void _addMessage(String role, String content) {
    setState(() {
      _messages.add({'role': role, 'content': content});
    });

    // Scroll to bottom
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    _addMessage('user', text);
    _textController.clear();

    setState(() {
      _isLoading = true;
      _avatarStatus = 'Thinking...';
    });

    try {
      // Stream response from backend
      String fullResponse = '';

      await for (var chunk in _apiService.streamChat(text, _userId)) {
        fullResponse += chunk;

        // Update UI with streaming response
        setState(() {
          if (_messages.isNotEmpty && _messages.last['role'] == 'assistant_streaming') {
            _messages.last['content'] = fullResponse;
          } else {
            _messages.add({'role': 'assistant_streaming', 'content': fullResponse});
          }
        });

        // Scroll to bottom
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      }

      // Finalize message
      setState(() {
        if (_messages.isNotEmpty && _messages.last['role'] == 'assistant_streaming') {
          _messages.last['role'] = 'assistant';
        }
      });

      // Send to WebView to make Hera speak
      if (_isWebViewReady && fullResponse.isNotEmpty) {
        _sendToWebView('speak', fullResponse);
        setState(() => _avatarStatus = 'Speaking');
      } else {
        setState(() => _avatarStatus = 'Listening');
      }
    } catch (e) {
      print('Error: $e');
      _addMessage('error', 'Failed to get response. Please check backend is running.');
      setState(() => _avatarStatus = 'Error');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);

        await _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              // iOS automatically includes punctuation and capitalization!
              final transcript = result.recognizedWords;
              print('✅ [AvatarScreen] Final transcript: "$transcript"');
              _textController.text = transcript;
              _sendMessage(transcript);
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          localeId: 'en_US',
          listenMode: stt.ListenMode.dictation, // Dictation mode provides better punctuation
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hera - Your Health Coach'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Mode Toggle Switch (Video + Voice)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                const Text(
                  'Video',
                  style: TextStyle(fontSize: 12),
                ),
                Switch(
                  value: true, // Always true in Video mode
                  onChanged: (value) {
                    if (!value) {
                      // Navigate back to Chat Screen (Voice-Only mode)
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const ChatScreen()),
                      );
                    }
                  },
                  activeColor: Colors.white,
                ),
              ],
            ),
          ),
          // Dashboard button
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'Health Dashboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HealthDashboardScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Avatar WebView
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width * 0.75, // 4:3 aspect ratio
            color: Colors.black,
            child: Stack(
              children: [
                // WebView with HeyGen avatar
                WebViewWidget(controller: _webViewController),

                // Status overlay (only show while loading)
                if (!_isWebViewReady)
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            _avatarStatus,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Messages
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isError
                          ? Colors.red[100]
                          : isUser
                              ? Colors.blue[100]
                              : Colors.purple[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Text(
                      message['content'] ?? '',
                      style: TextStyle(
                        color: isError ? Colors.red[900] : Colors.black87,
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
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Voice button
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleListening,
                ),

                const SizedBox(width: 8),

                // Text input
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.purple,
                  onPressed: () => _sendMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HealthTestScreen()),
          );
        },
        icon: const Icon(Icons.favorite),
        label: const Text('Health Test'),
        backgroundColor: Colors.red.shade400,
        tooltip: 'Test HealthKit Integration',
      ),
    );
  }

  @override
  void dispose() {
    // Stop HeyGen avatar session
    _sendToWebView('stop', '');

    _textController.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }
}
