// lib/services/user_service.dart

import 'dart:async';
import '../models/user.dart';
import '../models/paginated_response.dart';
import 'base_service.dart';
import '../models/api_client.dart';

/// Service for managing User entities
class UserService implements BaseService<User> {
  final ApiClient _apiClient;

  UserService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<User>> getAll() async {
    try {
      final fullResponse = await _apiClient.get('users/');
      final response = fullResponse.data;
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<User>.fromJson(
          response,
          (json) => User.fromJson(json),
        );
        return paginatedResponse.results;
      } else if (response is List) {
        return response.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format: ${response.runtimeType}');
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get all users', e);
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  @override
  Future<User> getById(int id) async {
    if (id <= 0) {
      throw ArgumentError('User ID must be a positive integer');
    }

    try {
      final fullResponse = await _apiClient.get('users/$id/');
      final response = fullResponse.data;
      return User.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        //todo
        throw Exception('User with ID $id not found');
      }
      _handleApiException('Failed to get user with ID $id', e);
    } catch (e) {
      throw Exception('Failed to get user with ID $id: $e');
    }
  }

  @override
  Future<User> create(User user) async {
    try {
      final fullResponse = await _apiClient.post('users/', user.toJson());
      final response = fullResponse.data;
      return User.fromJson(response);
    } on ApiException catch (e) {
      _handleApiException('Failed to create user', e);
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  @override
  Future<User> update(User user) async {
    if (user.id == null) {
      throw ArgumentError('Cannot update a user without an ID');
    }

    try {
      final fullResponse =
          await _apiClient.put('users/${user.id}/', user.toJson());
      final response = fullResponse.data;
      return User.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        //todo
        throw Exception('User with ID ${user.id} not found');
      }
      _handleApiException('Failed to update user', e);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  @override
  Future<bool> delete(int id) async {
    if (id <= 0) {
      throw ArgumentError('User ID must be a positive integer');
    }

    try {
      await _apiClient.delete('users/$id/');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('User with ID $id not found');
      }
      _handleApiException('Failed to delete user with ID $id', e);
    } catch (e) {
      throw Exception('Failed to delete user with ID $id: $e');
    }
  }

  /// Get current user's profile information
  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final response = await _apiClient.get('my-profile/');

      return response.data;
    } on ApiException catch (e) {
      _handleApiException('Failed to get my profile', e);
    } catch (e) {
      throw Exception('Failed to get my profile: $e');
    }
  }

  /// Get users for a specific project with their roles and access details
  Future<List<User>> getByProjectId(int projectId) async {
    if (projectId <= 0) {
      throw ArgumentError('Project ID must be a positive integer');
    }

    try {
      final fullResponse = await _apiClient.get('projects/$projectId/users/');
      final response = fullResponse.data;
      if (response is Map<String, dynamic> && response.containsKey('users')) {
        final List<dynamic> usersJson = response['users'];
        return usersJson.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format: ${response.runtimeType}');
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get users for project $projectId', e);
    } catch (e) {
      throw Exception('Failed to get users for project $projectId: $e');
    }
  }

  /// Upgrade user to premium
  Future<Map<String, dynamic>> upgradeToPremium() async {
    try {
      final fullResponse = await _apiClient.post('upgrade-to-premium/', "");
      final response = fullResponse.data;
      return response;
    } on ApiException catch (e) {
      _handleApiException('Failed to upgrade to premium', e);
    } catch (e) {
      throw Exception('Failed to upgrade to premium: $e');
    }
  }

  Never _handleApiException(String message, ApiException e) {
    final errorMessage = '$message: [${e.statusCode}] ${e.message}';
    throw Exception(errorMessage);
  }

  void dispose() {
    // No resources to dispose
  }
}
