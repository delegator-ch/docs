// lib/service/token_manager.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class TokenManager {
  // Store token in memory
  static String? _token;

  // Default credentials
  static const String defaultUsername = "test_user_2";
  static const String defaultPassword = "sml12345";
  static const String baseUrl = 'http://delegator.ch';

  // Get the stored token
  static String? getToken() {
    return _token;
  }

  // Set the token
  static void setToken(String token) {
    _token = token;
  }

  // Clear the token
  static void clearToken() {
    _token = null;
  }

  // Check if token exists
  static bool hasToken() {
    return _token != null && _token!.isNotEmpty;
  }

  // Fetch token with default credentials
  static Future<bool> fetchTokenWithDefaultCredentials() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': defaultUsername,
          'password': defaultPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access'] ?? data['token'];

        if (token != null) {
          setToken(token);
          return true;
        }
      }

      print('Failed to fetch token: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('Error fetching token: $e');
      return false;
    }
  }
}
