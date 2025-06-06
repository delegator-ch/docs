// lib/services/external_service.dart

import 'dart:async';
import '../models/user.dart';
import '../models/paginated_response.dart';
import '../models/api_client.dart';

/// Service for managing External Users
class ExternalService {
  final ApiClient _apiClient;

  ExternalService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get external users for a specific project
  Future<List<User>> getByProjectId(int projectId) async {
    if (projectId <= 0) {
      throw ArgumentError('Project ID must be a positive integer');
    }

    try {
      final fullResponse =
          await _apiClient.get('/projects/$projectId/externals/');
      final response = fullResponse.data;
      if (response is Map<String, dynamic> &&
          response.containsKey('externals')) {
        final List<dynamic> externalsJson = response['externals'];
        return externalsJson
            .map((json) => User.fromJson(json['user_details']))
            .toList();
      } else {
        throw Exception('Unexpected response format: ${response.runtimeType}');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Project with ID $projectId not found');
      }
      _handleApiException('Failed to get externals for project $projectId', e);
    } catch (e) {
      throw Exception('Failed to get externals for project $projectId: $e');
    }
  }

  Future<int?> getExternalId(int userId, int projectId) async {
    try {
      final fullResponse =
          await _apiClient.get('/projects/$projectId/externals/');
      final response = fullResponse.data;
      // Handle null or missing response data
      if (response == null || !response.containsKey('externals')) {
        return null;
      }

      final externals = response['externals'] as List?;
      if (externals == null || externals.isEmpty) {
        return null;
      }

      // Find matching external by userId
      for (final external in externals) {
        print(external);
        final id = external['user'];
        print('Search for $userId found $id');
        if (external is Map && external['user'] == userId) {
          return external['user'] as int?;
        }
      }

      return null;
    } catch (e) {
      // Log error with context
      print(
          'Error fetching external ID for user $userId in project $projectId: $e');
      return null;
    }
  }

  /// Get external users for a specific organisation
  Future<List<User>> getByOrganisationId(int organisationId) async {
    if (organisationId <= 0) {
      throw ArgumentError('Organisation ID must be a positive integer');
    }

    try {
      final fullResponse =
          await _apiClient.get('/organisations/$organisationId/externals/');
      final response = fullResponse.data;
      if (response is Map<String, dynamic> &&
          response.containsKey('external_users')) {
        final List<dynamic> externalsJson = response['external_users'];
        return externalsJson
            .map((json) => User.fromJson(json['user_details']))
            .toList();
      } else {
        throw Exception('Unexpected response format: ${response.runtimeType}');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Organisation with ID $organisationId not found');
      }
      _handleApiException(
          'Failed to get externals for organisation $organisationId', e);
    } catch (e) {
      throw Exception(
          'Failed to get externals for organisation $organisationId: $e');
    }
  }

  /// Add a user to an organisation as external
  Future<bool> addToOrganisation(int userId, int organisationId,
      {int roleId = 6}) async {
    if (userId <= 0) {
      throw ArgumentError('User ID must be a positive integer');
    }
    if (organisationId <= 0) {
      throw ArgumentError('Organisation ID must be a positive integer');
    }

    try {
      await _apiClient.post('/user-organisations/', {
        'user': userId,
        'organisation': organisationId,
        'role': roleId,
      });
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        throw Exception('User is already in this organisation');
      }
      _handleApiException('Failed to add user to organisation', e);
    } catch (e) {
      throw Exception('Failed to add user to organisation: $e');
    }
  }

  /// Remove a user from an organisation
  Future<bool> removeFromOrganisation(int userId, int organisationId) async {
    if (userId <= 0) {
      throw ArgumentError('User ID must be a positive integer');
    }
    if (organisationId <= 0) {
      throw ArgumentError('Organisation ID must be a positive integer');
    }

    try {
      await _apiClient.delete('/organisations/$organisationId/users/$userId/');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('User not found in organisation');
      }
      _handleApiException('Failed to remove user from organisation', e);
    } catch (e) {
      throw Exception('Failed to remove user from organisation: $e');
    }
  }

  /// Add an external user to a project
  Future<bool> addToProject(int userId, int projectId) async {
    if (userId <= 0) {
      throw ArgumentError('User ID must be a positive integer');
    }
    if (projectId <= 0) {
      throw ArgumentError('Project ID must be a positive integer');
    }

    try {
      final response = await _apiClient.post('/externals/', {
        'user': userId,
        'project': projectId,
        'role': 6,
      });

      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        throw Exception('External user is already in this project');
      }
      _handleApiException('Failed to add external to project', e);
    } catch (e) {
      throw Exception('Failed to add external to project: $e');
    }
  }

  /// Remove an external user from a project
  Future<bool> removeFromProject(int userId, int projectId) async {
    if (userId <= 0) {
      throw ArgumentError('User ID must be a positive integer');
    }
    if (projectId <= 0) {
      throw ArgumentError('Project ID must be a positive integer');
    }
    final external = await getExternalId(userId, projectId);
    if (external == null) {
      throw Exception('External user not found in project');
    }
    try {
      await _apiClient.delete('/externals/$external/');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return true;
      }
      _handleApiException('Failed to remove external from project', e);
    } catch (e) {
      throw Exception('Failed to remove external from project: $e');
    }
  }

  /// Create a new external user
  Future<User> create(User external) async {
    try {
      final response = await _apiClient.post('/externals/', external.toJson());
      return User.fromJson(response.data);
    } on ApiException catch (e) {
      _handleApiException('Failed to create external user', e);
    } catch (e) {
      throw Exception('Failed to create external user: $e');
    }
  }

  /// Update an external user
  Future<User> update(User external) async {
    if (external.id == null) {
      throw ArgumentError('Cannot update an external user without an ID');
    }

    try {
      final response =
          await _apiClient.put('/externals/${external.id}/', external.toJson());

      if (response.statusCode == 404) {
        throw Exception('External user with ID ${external.id} not found');
      }
      return User.fromJson(response.data);
    } on ApiException catch (e) {
      _handleApiException('Failed to update external user', e);
    } catch (e) {
      throw Exception('Failed to update external user: $e');
    }
  }

  /// Delete an external user
  Future<bool> delete(int id) async {
    if (id <= 0) {
      throw ArgumentError('External user ID must be a positive integer');
    }

    try {
      await _apiClient.delete('/externals/$id/');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('External user with ID $id not found');
      }
      _handleApiException('Failed to delete external user with ID $id', e);
    } catch (e) {
      throw Exception('Failed to delete external user with ID $id: $e');
    }
  }

  /// Search external users
  Future<List<User>> search(String query) async {
    if (query.isEmpty) {
      throw ArgumentError('Search query cannot be empty');
    }

    try {
      final fullResponse = await _apiClient.get('/externals/?search=$query');
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
      _handleApiException('Failed to search externals with query "$query"', e);
    } catch (e) {
      throw Exception('Failed to search externals with query "$query": $e');
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
