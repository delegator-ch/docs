// lib/service/token_manager.dart
class TokenManager {
  // Store token in memory
  static String? _token;

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
}
