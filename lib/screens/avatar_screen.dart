import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/api_service.dart';
import '../services/native_speech_service.dart';
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
  final NativeSpeechService _nativeSpeech = NativeSpeechService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late WebViewController _webViewController;
  bool _isListening = false;
  bool _isLoading = false;
  bool _isWebViewReady = false;
  bool _speechAvailable = false;
  String _userId = 'default_user';
  String _avatarStatus = 'Loading...';
  String _currentTranscript = '';
  Timer? _silenceTimer;
  List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();

    // Show message that Video+Voice is not available on mobile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showVideoModeNotAvailableDialog();
    });
  }

  void _showVideoModeNotAvailableDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Video + Voice Mode'),
          content: const Text(
            'Video + Voice mode with the interactive avatar is currently not available on iOS mobile due to platform limitations.\n\n'
            'Please use Voice-Only mode for the best mobile experience with Hera. Voice-Only mode provides:\n\n'
            '• Crystal clear audio\n'
            '• Real-time transcription\n'
            '• Faster responses\n'
            '• Full AI coaching features\n\n'
            'Video + Voice mode is available on the web version.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const ChatScreen()),
                );
              },
              child: const Text('Switch to Voice-Only Mode'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _nativeSpeech.initialize();

      // Listen to final transcripts
      _nativeSpeech.finalTranscriptStream.listen((transcript) {
        print('✅ [AvatarScreen] Final transcript: "$transcript"');

        // Cancel silence timer since we got a final result
        _silenceTimer?.cancel();

        // Send the transcript
        _textController.text = transcript;
        _sendMessage(transcript);

        // Reset
        _currentTranscript = '';
        _stopListening();
      });

      // Listen to interim transcripts for display
      _nativeSpeech.transcriptStream.listen((transcript) {
        print('📝 [AvatarScreen] Interim transcript: "$transcript"');
        setState(() {
          _currentTranscript = transcript;
        });

        // Reset silence timer on new interim result
        _resetSilenceTimer();
      });

      // Listen to errors
      _nativeSpeech.errorStream.listen((error) {
        print('❌ [AvatarScreen] Speech error: $error');
        _addMessage('error', 'Speech recognition error: $error');
        _stopListening();
      });

      print('✅ [AvatarScreen] Native speech initialized successfully');
    } catch (e) {
      print('❌ [AvatarScreen] Failed to initialize speech: $e');
      setState(() {
        _speechAvailable = false;
      });
    }
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 3), () {
      // If we have a transcript after 3 seconds of silence, send it
      if (_currentTranscript.isNotEmpty) {
        print('⏱️ [AvatarScreen] Silence timeout - sending transcript: "$_currentTranscript"');
        _textController.text = _currentTranscript;
        _sendMessage(_currentTranscript);
        _currentTranscript = '';
        _stopListening();
      }
    });
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print('🔵 [AvatarScreen] WebView loading: $progress%');
          },
          onPageStarted: (String url) {
            print('🔵 [AvatarScreen] Page started loading: $url');
            setState(() {
              _avatarStatus = 'Connecting...';
            });
          },
          onPageFinished: (String url) {
            print('✅ [AvatarScreen] Page finished loading: $url');

            // Enable console logging from WebView
            _webViewController.runJavaScript('''
              console.log = (function(oldLog) {
                return function(...args) {
                  oldLog.apply(console, args);
                  FlutterChannel.postMessage(JSON.stringify({
                    type: 'console',
                    message: args.join(' ')
                  }));
                };
              })(console.log);
              console.error = console.log;
              console.warn = console.log;
              console.log('✅ Console logging forwarded to Flutter');

              // CRITICAL: Initialize AudioContext for iOS WebView audio playback
              try {
                console.log('🔊 Attempting AudioContext initialization...');
                if (typeof AudioContext !== 'undefined' || typeof webkitAudioContext !== 'undefined') {
                  const AudioContextClass = window.AudioContext || window.webkitAudioContext;
                  const audioContext = new AudioContextClass();
                  console.log('🔊 AudioContext created, state:', audioContext.state);

                  // Resume audio context
                  audioContext.resume().then(() => {
                    console.log('✅ AudioContext resumed successfully, state:', audioContext.state);
                  }).catch((e) => {
                    console.error('❌ AudioContext resume failed:', e);
                  });
                } else {
                  console.error('❌ AudioContext not supported');
                }
              } catch (e) {
                console.error('❌ AudioContext initialization error:', e);
              }
            ''');

            setState(() {
              _isWebViewReady = true;
              _avatarStatus = 'Ready';
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ [AvatarScreen] WebView error: ${error.description}');
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
    try {
      // Try to parse as JSON
      final data = jsonDecode(message);

      if (data['type'] == 'console') {
        // Forward console logs from WebView
        print('🌐 [WebView Console] ${data['message']}');
        return;
      }

      // Handle other message types
      print('📨 [AvatarScreen] Message from WebView: $message');

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
      // Not JSON, treat as plain text
      print('📨 [AvatarScreen] Message from WebView: $message');

      setState(() {
        if (message.contains('speaking')) {
          _avatarStatus = 'Speaking';
        } else if (message.contains('listening')) {
          _avatarStatus = 'Listening';
        } else if (message.contains('ready')) {
          _avatarStatus = 'Ready';
        }
      });
    }
  }

  void _sendToWebView(String type, String text) {
    if (!_isWebViewReady) {
      print('⚠️ [AvatarScreen] WebView not ready yet');
      return;
    }

    print('📤 [AvatarScreen] Sending to WebView - type: $type, text length: ${text.length}');
    print('📝 [AvatarScreen] Text preview: ${text.substring(0, text.length > 100 ? 100 : text.length)}...');

    // Escape single quotes and backticks in text to prevent JavaScript errors
    final escapedText = text
        .replaceAll('\\', '\\\\')
        .replaceAll('`', '\\`')
        .replaceAll('\$', '\\\$')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');

    // Send message to WebView JavaScript
    final jsCode = '''
      console.log('🔵 [WebView] Received postMessage call from Flutter');
      console.log('🔵 [WebView] Type: $type');
      console.log('🔵 [WebView] Text length: ${escapedText.length}');
      window.postMessage({
        type: '$type',
        text: `$escapedText`
      }, '*');
      console.log('✅ [WebView] postMessage sent');
    ''';

    _webViewController.runJavaScript(jsCode);
    print('✅ [AvatarScreen] JavaScript executed');
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
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      print('❌ [AvatarScreen] Speech recognition not available');
      _addMessage('error', 'Speech recognition not available. Please enable microphone permissions.');
      return;
    }

    print('🎤 [AvatarScreen] Starting speech recognition...');

    setState(() {
      _isListening = true;
      _currentTranscript = '';
      _avatarStatus = 'Listening';
    });

    // Start listening with native iOS speech
    await _nativeSpeech.startListening();

    print('✅ [AvatarScreen] Speech recognition started');
  }

  Future<void> _stopListening() async {
    await _nativeSpeech.stopListening();
    _silenceTimer?.cancel();

    setState(() {
      _isListening = false;
      _avatarStatus = 'Ready';
    });

    print('🛑 [AvatarScreen] Speech recognition stopped');
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

    _silenceTimer?.cancel();
    _nativeSpeech.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
