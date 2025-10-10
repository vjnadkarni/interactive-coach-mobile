import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  // Stream chat response from backend
  Stream<String> streamChat(String message, String userId) async* {
    final url = Uri.parse(AppConstants.chatStreamEndpoint);

    final request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.body = json.encode({
      'message': message,
      'user_id': userId,
    });

    final streamedResponse = await request.send();

    await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
      // Parse Server-Sent Events (SSE)
      final lines = chunk.split('\n');

      for (var line in lines) {
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6); // Remove 'data: ' prefix
          try {
            final data = json.decode(jsonStr);

            if (data['text'] != null) {
              yield data['text'] as String;
            }

            if (data['done'] == true) {
              break;
            }
          } catch (e) {
            print('Error parsing SSE: $e');
          }
        }
      }
    }
  }

  // Check for existing conversation
  Future<Map<String, dynamic>> checkConversation(String userId) async {
    final url = Uri.parse('${AppConstants.conversationCheckEndpoint}/$userId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error checking conversation: $e');
    }

    return {'has_conversation': false, 'message_count': 0};
  }

  // Clear conversation
  Future<bool> clearConversation(String userId) async {
    final url = Uri.parse('${AppConstants.conversationClearEndpoint}/$userId');

    try {
      final response = await http.post(url);
      return response.statusCode == 200;
    } catch (e) {
      print('Error clearing conversation: $e');
      return false;
    }
  }
}
