import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';
import '../model/chat_model.dart';

class ChatService {
  static const String baseUrl = 'http://delegator.ch';

  // Get headers with authentication token
  Map<String, String> _getAuthHeaders() {
    final token = TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Set token manually
  void setToken(String token) {
    TokenManager.setToken(token);
  }

  // Fetch chats with authentication and auto-retry
  Future<List<Chat>> fetchChats() async {
    try {
      final headers = _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/chats/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> results = data['results'];
        return results.map((json) => Chat.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        // Token might be expired, try to refresh
        print('Authentication failed, attempting to fetch new token...');
        bool tokenFetched =
            await TokenManager.fetchTokenWithDefaultCredentials();

        if (tokenFetched) {
          // Try again with the new token
          return fetchChats();
        } else {
          // Still failed
          TokenManager.clearToken();
          throw Exception('Authentication failed. Please login again.');
        }
      } else {
        throw Exception('Failed to load chats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchChats: $e');
      throw e;
    }
  }

  // Login method for JWT
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access'] ?? data['token'];

        if (token != null) {
          TokenManager.setToken(token);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
}
