import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';
import '../model/message_model.dart';

class MessageService {
  static const String baseUrl = 'http://delegator.ch'; // Same as in ChatService

  // Get headers with authentication token
  Map<String, String> _getAuthHeaders() {
    final token = TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Fetch all messages
  Future<List<Message>> fetchMessages() async {
    final headers = _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/messages/'),
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

  // Fetch messages for a specific chat
  Future<List<Message>> fetchMessagesByChat(int chatId) async {
    final headers = _getAuthHeaders();

    // Use the filters to get messages for a specific chat
    final response = await http.get(
      Uri.parse('$baseUrl/messages/?chat=$chatId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> results = data['results'];

      // Sort messages by sent date (oldest first)
      final messages = results.map((json) => Message.fromJson(json)).toList();
      messages.sort(
        (a, b) => DateTime.parse(a.sent).compareTo(DateTime.parse(b.sent)),
      );

      return messages;
    } else if (response.statusCode == 401) {
      // Token might be expired
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to load messages: ${response.statusCode}');
    }
  }

  // Send a new message
  Future<Message> sendMessage(int chatId, String content) async {
    final headers = _getAuthHeaders();

    // Construct the exact payload format
    final Map<String, dynamic> payload = {'chat': chatId, 'content': content};

    final response = await http.post(
      Uri.parse('$baseUrl/messages/'),
      headers: headers,
      body: json.encode(payload),
    );

    if (response.statusCode == 201) {
      final dynamic data = json.decode(response.body);
      return Message.fromJson(data);
    } else if (response.statusCode == 401) {
      // Token might be expired
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }
}
