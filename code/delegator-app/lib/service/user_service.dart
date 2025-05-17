// lib/service/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';

class User {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String created;
  final String? profileImage;

  User({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    required this.created,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      created: json['created'],
      profileImage: json['profile_image'],
    );
  }

  String get displayName {
    if ((firstName?.isNotEmpty ?? false) || (lastName?.isNotEmpty ?? false)) {
      return [
        firstName ?? '',
        lastName ?? '',
      ].where((s) => s.isNotEmpty).join(' ');
    }
    return username;
  }
}

class UserService {
  static const String baseUrl = 'http://delegator.ch';
  static User? _currentUser;

  // Get the current authenticated user
  static User? get currentUser => _currentUser;

  // Get headers with authentication token
  static Map<String, String> _getAuthHeaders() {
    final token = TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Fetch all users with auto-retry
  static Future<List<User>> fetchUsers() async {
    try {
      final headers = _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> results = data['results'];
        return results.map((json) => User.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        // Token might be expired, try to refresh
        print('Authentication failed, attempting to fetch new token...');
        bool tokenFetched =
            await TokenManager.fetchTokenWithDefaultCredentials();

        if (tokenFetched) {
          // Try again with the new token
          return fetchUsers();
        } else {
          // Still failed
          TokenManager.clearToken();
          throw Exception('Authentication failed. Please login again.');
        }
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchUsers: $e');
      throw e;
    }
  }

  // Fetch current user info with auto-retry
  static Future<User> fetchCurrentUser() async {
    try {
      final headers = _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        _currentUser = User.fromJson(userData);
        return _currentUser!;
      } else if (response.statusCode == 401) {
        // Token might be expired, try to refresh
        print('Authentication failed, attempting to fetch new token...');
        bool tokenFetched =
            await TokenManager.fetchTokenWithDefaultCredentials();

        if (tokenFetched) {
          // Try again with the new token
          return fetchCurrentUser();
        } else {
          // Still failed
          TokenManager.clearToken();
          throw Exception('Authentication failed. Please login again.');
        }
      } else {
        throw Exception('Failed to load current user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchCurrentUser: $e');
      throw e;
    }
  }

  // Get user by ID with auto-retry
  static Future<User> fetchUserById(int userId) async {
    try {
      final headers = _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        // Token might be expired, try to refresh
        print('Authentication failed, attempting to fetch new token...');
        bool tokenFetched =
            await TokenManager.fetchTokenWithDefaultCredentials();

        if (tokenFetched) {
          // Try again with the new token
          return fetchUserById(userId);
        } else {
          // Still failed
          TokenManager.clearToken();
          throw Exception('Authentication failed. Please login again.');
        }
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchUserById: $e');
      throw e;
    }
  }

  // Initialize the user service (fetch current user)
  static Future<void> initialize() async {
    if (!TokenManager.hasToken()) {
      // Try to fetch a token first
      await TokenManager.fetchTokenWithDefaultCredentials();
    }

    if (TokenManager.hasToken()) {
      try {
        await fetchCurrentUser();
        print('Current user initialized: ${_currentUser?.username}');
      } catch (e) {
        print('Error initializing user service: $e');
      }
    } else {
      print('No token available, skipping user initialization');
    }
  }

  // Check if a message belongs to the current user
  static bool isCurrentUserMessage(int userId) {
    return _currentUser != null && _currentUser!.id == userId;
  }
}
