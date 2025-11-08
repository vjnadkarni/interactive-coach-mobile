import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

class ApiService {
  // Stream chat response from backend
  Stream<String> streamChat(String message, String userId) async* {
    final url = Uri.parse(AppConstants.chatStreamEndpoint);
    print('🌐 [ApiService] URL: $url');
    print('🌐 [ApiService] Message: "$message"');
    print('🌐 [ApiService] User ID: "$userId"');

    // Get JWT token from Supabase session
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      print('❌ [ApiService] No JWT token found - user not authenticated');
      throw Exception('Not authenticated - please log in again');
    }

    print('✅ [ApiService] JWT token found (${token.substring(0, 20)}...)');

    final request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';
    request.body = json.encode({
      'message': message,
    });

    print('🌐 [ApiService] Sending request with Authorization header...');

    final streamedResponse = await request.send();

    print('🌐 [ApiService] Response status: ${streamedResponse.statusCode}');
    print('🌐 [ApiService] Response headers: ${streamedResponse.headers}');

    if (streamedResponse.statusCode != 200) {
      print('❌ [ApiService] HTTP error: ${streamedResponse.statusCode}');
      final errorBody = await streamedResponse.stream.bytesToString();
      print('❌ [ApiService] Error body: $errorBody');
      throw Exception('HTTP ${streamedResponse.statusCode}: $errorBody');
    }

    int chunkCount = 0;
    await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
      chunkCount++;
      print('📦 [ApiService] Raw chunk #$chunkCount: "$chunk"');

      // Parse Server-Sent Events (SSE)
      final lines = chunk.split('\n');

      for (var line in lines) {
        if (line.trim().isNotEmpty) {
          print('📄 [ApiService] Line: "$line"');
        }

        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6); // Remove 'data: ' prefix
          print('🔍 [ApiService] JSON string: "$jsonStr"');

          try {
            final data = json.decode(jsonStr);
            print('✅ [ApiService] Parsed data: $data');

            if (data['text'] != null) {
              print('📤 [ApiService] Yielding text: "${data['text']}"');
              yield data['text'] as String;
            }

            if (data['done'] == true) {
              print('✅ [ApiService] Stream done');
              break;
            }
          } catch (e) {
            print('❌ [ApiService] Error parsing SSE: $e');
            print('❌ [ApiService] Failed JSON: "$jsonStr"');
          }
        }
      }
    }

    print('✅ [ApiService] Stream complete. Total raw chunks: $chunkCount');
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
