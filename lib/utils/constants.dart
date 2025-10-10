import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Environment variables
  static String get backendUrl => dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';
  static String get heygenApiKey => dotenv.env['HEYGEN_API_KEY'] ?? '';
  static String get deepgramApiKey => dotenv.env['DEEPGRAM_API_KEY'] ?? '';

  // HeyGen Avatar Configuration
  static const String avatarId = 'Elenora_FitnessCoach2_public';
  static const String avatarQuality = 'high';

  // Session Configuration
  static const int sessionLimitSeconds = 300; // 5 minutes
  static const int countdownStartSeconds = 30; // Show countdown at 30s remaining
  static const int keepAliveIntervalSeconds = 60;

  // Speech Recognition
  static const double silenceTimeoutSeconds = 2.2;

  // API Endpoints
  static String get chatStreamEndpoint => '$backendUrl/chat/stream';
  static String get conversationCheckEndpoint => '$backendUrl/conversation/check';
  static String get conversationClearEndpoint => '$backendUrl/conversation/clear';

  // Colors
  static const primaryColor = 0xFF9C27B0; // Purple
  static const secondaryColor = 0xFF2196F3; // Blue
}
