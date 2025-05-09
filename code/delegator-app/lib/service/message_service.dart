// Create a new file: lib/service/message_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';
import '../model/message_model.dart';

class MessageService {
  static const String baseUrl = 'http://10.0.2.2';

  // Get headers with authentication token
  Map<String, String> _getAuthHeaders() {
    final token = TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Fetch messages for a specific chat
  Future<List<Message>> fetchMessages(int chatId) async {
    final headers = _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/chats/$chatId/messages/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> results = data['results'];
      return results.map((json) => Message.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      // Token might be expired
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to load messages: ${response.statusCode}');
    }
  }

  // Send a message
  Future<Message> sendMessage(int chatId, String content) async {
    final headers = _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/chats/$chatId/messages/'),
      headers: headers,
      body: json.encode({'chat_id': chatId, 'content': content}),
    );

    if (response.statusCode == 201) {
      return Message.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }
}
