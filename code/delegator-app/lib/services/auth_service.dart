// lib/services/auth_service.dart (Enhanced version with better error handling)

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:delegator/models/http_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/api_client.dart';
import '../models/auth_result.dart';
import '../models/http_response.dart';
import '../config/api_config.dart';

/// Service for handling authentication with JWT tokens and secure storage
class AuthService {
  final ApiClient _apiClient;

  // Secure storage for sensitive data
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Token storage keys (in secure storage)
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'current_user';

  // App preferences (in shared preferences - non-sensitive)
  static const _rememberMeKey = 'remember_me';
  static const _lastUsernameKey = 'last_username';

  // Stream controller for authentication state changes
  final _authStateController = StreamController<bool>.broadcast();
  Stream<bool> get authStateChanges => _authStateController.stream;

  // Current user cache
  User? _currentUser;

  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Initialize the service and check if user is already logged in
  Future<bool> init() async {
    try {
      print("🔧 Initializing AuthService...");

      // Check if user wants to be remembered
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      if (!rememberMe) {
        print("👤 Remember Me is disabled, user needs to login manually");
        return false;
      }

      // Try to restore session from secure storage
      final accessToken = await _secureStorage.read(key: _accessTokenKey);

      if (accessToken != null) {
        print("🔑 Found stored access token, attempting to restore session");

        // Set token in API client
        _apiClient.setAuthToken(accessToken);

        // Try to get current user to validate token
        try {
          await getCurrentUser();
          print("✅ Session restored successfully");
          _authStateController.add(true);
          return true;
        } catch (e) {
          print("🔄 Access token invalid, trying to refresh...");

          // Try to refresh the token
          final refreshSuccess = await refreshToken();
          if (refreshSuccess) {
            print("✅ Session restored via token refresh");
            _authStateController.add(true);
            return true;
          } else {
            print("❌ Token refresh failed, user needs to login");
            await _clearSecureStorage();
            return false;
          }
        }
      } else {
        print("👤 No stored tokens found, user needs to login");
        return false;
      }
    } catch (e) {
      print("❌ Error during auth initialization: $e");
      await _clearSecureStorage();
      return false;
    }
  }

  Future<AuthResult> register(String username, String password,
      {bool rememberMe = true}) async {
    print("🔄 Attempting registration for user: $username");
    Response response = await _apiClient.post(
      'register/',
      {'username': username, 'password': password},
    );

    if (response.statusCode == 400) {
      return AuthResult.error('Username is taken');
    }
    return login(username, password, rememberMe: rememberMe);
  }

  Future<AuthResult> login(String username, String password,
      {bool rememberMe = true}) async {
    print("🔄 Attempting login for user: $username");

    try {
      final response = await _apiClient.post(
        ApiConfig.token,
        {'username': username, 'password': password},
      );

      if (response.statusCode == 401) {
        return AuthResult.error('Prodivded Information does not match');
      }

      print("📡 Received login response: ${response.data.keys}");

      final accessToken = response.data['access'];
      final refreshToken = response.data['refresh'];

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

        // Store tokens securely
        await _storeTokensSecurely(accessToken, refreshToken, userData);

        // Store preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_rememberMeKey, rememberMe);
        await prefs.setString(_lastUsernameKey, username);

        // Set token in API client
        _apiClient.setAuthToken(accessToken);

        // Cache current user
        _currentUser = user;

        // Notify listeners that auth state changed
        _authStateController.add(true);

        print("✅ Login completed successfully");
        return AuthResult.success(user);
      } else {
        print("❌ Login failed - tokens not found in response");
        return AuthResult.error('Invalid login response - tokens not found');
      }
    } on ApiException catch (e) {
      final errorMessage = _parseApiError(e);
      print("❌ Login failed: $errorMessage");
      return AuthResult.error(errorMessage);
    } catch (e) {
      print("❌ Login failed with unexpected error: $e");
      return AuthResult.error('Login failed: ${e.toString()}');
    }
  }

  /// Parse API error responses into user-friendly messages
  String _parseApiError(ApiException e) {
    try {
      // Try to parse the error message as JSON
      final errorData = jsonDecode(e.message);

      if (errorData is Map<String, dynamic>) {
        // Handle field-specific errors like {"username": ["A user with that username already exists."]}
        if (errorData.containsKey('username')) {
          final usernameErrors = errorData['username'];
          if (usernameErrors is List && usernameErrors.isNotEmpty) {
            return usernameErrors.first.toString();
          }
        }

        if (errorData.containsKey('email')) {
          final emailErrors = errorData['email'];
          if (emailErrors is List && emailErrors.isNotEmpty) {
            return emailErrors.first.toString();
          }
        }

        if (errorData.containsKey('password')) {
          final passwordErrors = errorData['password'];
          if (passwordErrors is List && passwordErrors.isNotEmpty) {
            return passwordErrors.first.toString();
          }
        }

        // Handle general detail errors like {"detail": "No active account found with the given credentials"}
        if (errorData.containsKey('detail')) {
          return errorData['detail'].toString();
        }

        // Handle non_field_errors
        if (errorData.containsKey('non_field_errors')) {
          final nonFieldErrors = errorData['non_field_errors'];
          if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
            return nonFieldErrors.first.toString();
          }
        }

        // If we have a map but can't parse it, return the first error
        final firstKey = errorData.keys.first;
        final firstValue = errorData[firstKey];
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        return firstValue.toString();
      }

      // If it's not a map, return the message as is
      return e.message;
    } catch (parseError) {
      // If JSON parsing fails, handle common status codes
      switch (e.statusCode) {
        case 400:
          return 'Invalid credentials or data provided';
        case 401:
          return 'Invalid username or password';
        case 403:
          return 'Access forbidden';
        case 404:
          return 'Authentication service not found';
        case 429:
          return 'Too many login attempts. Please try again later';
        case 500:
          return 'Server error. Please try again later';
        default:
          return 'Authentication failed. Please check your credentials';
      }
    }
  }

  /// Refresh the access token using the refresh token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

      if (refreshToken == null) {
        print("❌ No refresh token available");
        return false;
      }

      print("🔄 Attempting to refresh access token");

      final response = await _apiClient.post(
        ApiConfig.refreshToken,
        {'refresh': refreshToken},
      );

      final newAccessToken = response['access'];

      if (newAccessToken != null) {
        print("✅ Access token refreshed successfully");

        // Store the new access token securely
        await _secureStorage.write(key: _accessTokenKey, value: newAccessToken);

        // Update the API client
        _apiClient.setAuthToken(newAccessToken);

        return true;
      }

      print("❌ Token refresh failed - no new access token received");
      return false;
    } catch (e) {
      print("❌ Token refresh failed: $e");
      // If refresh fails, clear stored data and require re-login
      await logout();
      return false;
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    print("🚪 Logging out user");

    // Clear secure storage
    await _clearSecureStorage();

    // Clear current user cache
    _currentUser = null;

    // Clear API client token
    _apiClient.setAuthToken('');

    // Optionally clear preferences (keep last username for convenience)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, false);

    // Notify listeners that auth state changed
    _authStateController.add(false);

    print("✅ Logout completed");
  }

  /// Get the current logged in user
  Future<User?> getCurrentUser() async {
    // Return cached user if available
    if (_currentUser != null) {
      return _currentUser;
    }

    // Try to get user data from secure storage
    final userDataString = await _secureStorage.read(key: _userKey);

    if (userDataString != null) {
      try {
        final userMap = jsonDecode(userDataString) as Map<String, dynamic>;
        _currentUser = User(
          id: userMap['user_id'],
          username: userMap['username'] ?? '',
          email: userMap['email'],
        );
        return _currentUser;
      } catch (e) {
        print("❌ Error parsing stored user data: $e");
        await _clearSecureStorage();
        return null;
      }
    }

    return null;
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    return accessToken != null;
  }

  /// Get the last used username for convenience
  Future<String?> getLastUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastUsernameKey);
  }

  /// Check if remember me is enabled
  Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  /// Store tokens and user data securely
  Future<void> _storeTokensSecurely(String accessToken, String refreshToken,
      Map<String, dynamic> userData) async {
    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
      _secureStorage.write(key: _userKey, value: jsonEncode(userData)),
    ]);
    print("🔐 Tokens stored securely");
  }

  /// Clear all secure storage data
  Future<void> _clearSecureStorage() async {
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _secureStorage.delete(key: _userKey),
    ]);
    print("🧹 Secure storage cleared");
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

  /// Clear all authentication data (for debugging/testing)
  Future<void> clearAllAuthData() async {
    await _clearSecureStorage();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_lastUsernameKey);
    _currentUser = null;
    _apiClient.setAuthToken('');
    _authStateController.add(false);
    print("🧹 All authentication data cleared");
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
