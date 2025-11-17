import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Environment variables
  static String get backendUrl => dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';
  static String get heygenApiKey => dotenv.env['HEYGEN_API_KEY'] ?? '';
  static String get deepgramApiKey => dotenv.env['DEEPGRAM_API_KEY'] ?? '';
  static String get elevenLabsApiKey => dotenv.env['ELEVENLABS_API_KEY'] ?? '';
  static String get elevenLabsVoiceId => dotenv.env['ELEVENLABS_VOICE_ID'] ?? '21m00Tcm4TlvDq8ikWAM';

  // HeyGen Avatar Configuration
  static const String avatarId = 'Marianne_Chair_Sitting_public';
  static const String avatarQuality = 'high';

  // Session Configuration
  static const int sessionLimitSeconds = 300; // 5 minutes
  static const int countdownStartSeconds = 30; // Show countdown at 30s remaining
  static const int keepAliveIntervalSeconds = 60;

  // Speech Recognition
  static const double silenceTimeoutSeconds = 2.2;

  // API Endpoints
  static String get chatStreamEndpoint => '$backendUrl/api/chat/stream';
  static String get conversationCheckEndpoint => '$backendUrl/api/conversation/check';
  static String get conversationClearEndpoint => '$backendUrl/api/conversation/clear';

  // Mobile Avatar WebView URL
  static String get mobileAvatarUrl {
    // In development, use local network
    // In production, this will be https://coach.galenogen.com/mobile-avatar
    final host = backendUrl.replaceAll(':8000', ':3000'); // Web app runs on port 3000
    return '$host/mobile-avatar';
  }

  // Colors
  static const primaryColor = 0xFF9C27B0; // Purple
  static const secondaryColor = 0xFF2196F3; // Blue
}
