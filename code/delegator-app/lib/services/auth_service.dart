// lib/services/auth_service.dart (updated for JWT)

import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_client.dart';
import '../config/api_config.dart';

/// Service for handling authentication with JWT tokens
class AuthService {
  final ApiClient _apiClient;

  // Token storage keys
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'current_user';

  // Stream controller for authentication state changes
  final _authStateController = StreamController<bool>.broadcast();
  Stream<bool> get authStateChanges => _authStateController.stream;

  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Initialize the service and check if user is already logged in
  Future<bool> init() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_accessTokenKey);

    if (accessToken != null) {
      _apiClient.setAuthToken(accessToken);
      _authStateController.add(true);
      return true;
    }
    return false;
  }

  /// Login with username and password
  Future<User> login(String username, String password) async {
    print("🔄 Attempting login for user: $username");

    final response = await _apiClient.post(
      ApiConfig.token, // Update this to match your actual token endpoint
      {'username': username, 'password': password},
    );

    print("📡 Received login response: ${response.keys}");

    final accessToken = response['access'];
    final refreshToken = response['refresh'];

    if (accessToken != null && refreshToken != null) {
      print("✅ Tokens received successfully");

      // Get user data from JWT payload
      final userData = _parseJwt(accessToken);
      print("👤 Extracted user data from token: ${userData['username']}");

      final user = User(
        id: userData['user_id'],
        username: userData['username'] ?? '',
        email: userData['email'],
      );

      final prefs = await SharedPreferences.getInstance();

      // Store tokens in preferences
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);

      // Store user data
      await prefs.setString(_userKey, jsonEncode(userData));

      // Set token in API client
      _apiClient.setAuthToken(accessToken);

      // Notify listeners that auth state changed
      _authStateController.add(true);

      return user;
    } else {
      print("❌ Login failed - tokens not found in response");
      throw Exception('Invalid login response - tokens not found');
    }
  }

  /// Refresh the access token using the refresh token
  Future<bool> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);

    if (refreshToken == null) {
      return false;
    }

    try {
      final response = await _apiClient.post(
        ApiConfig.refreshToken, // Update this to match your refresh endpoint
        {'refresh': refreshToken},
      );

      final newAccessToken = response['access'];

      if (newAccessToken != null) {
        // Store the new access token
        await prefs.setString(_accessTokenKey, newAccessToken);

        // Update the API client
        _apiClient.setAuthToken(newAccessToken);

        return true;
      }

      return false;
    } catch (e) {
      print("🔄 Token refresh failed: $e");
      // If refresh fails, log out the user
      await logout();
      return false;
    }
  }

  /// Decode JWT token to get user data
  Map<String, dynamic> _parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid JWT token format');
    }

    final payload = parts[1];
    var normalized = base64Url.normalize(payload);
    var resp = utf8.decode(base64Url.decode(normalized));
    final payloadMap = json.decode(resp);

    return payloadMap;
  }

  /// Logout the current user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear stored tokens and user data
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);

    // Notify listeners that auth state changed
    _authStateController.add(false);
  }

  /// Get the current logged in user
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);

    if (userData != null) {
      Map<String, dynamic> userMap = jsonDecode(userData);
      return User(
        id: userMap['user_id'],
        username: userMap['username'] ?? '',
        email: userMap['email'],
      );
    }
    return null;
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_accessTokenKey);
    return accessToken != null;
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
