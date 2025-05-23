// lib/services/project_service.dart

import 'dart:async';
import '../models/project.dart';
import 'base_service.dart';
import 'api_client.dart';
import '../config/api_config.dart';

/// Service for managing Project entities
///
/// This service provides methods for CRUD operations on Project entities,
/// along with specialized query methods for filtering projects.
class ProjectService implements BaseService<Project> {
  final ApiClient _apiClient;

  /// Creates a new ProjectService instance
  ///
  /// Optionally accepts a custom [apiClient], otherwise creates a default one
  ProjectService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetches all projects
  ///
  /// Returns a list of all projects the user has access to
  @override
  Future<List<Project>> getAll() async {
    try {
      final response = await _apiClient.get(ApiConfig.projects);

      // Convert response directly to list of projects
      final List<dynamic> projectsJson = response['results'] as List<dynamic>;
      return projectsJson.map((json) => Project.fromJson(json)).toList();
    } on ApiException catch (e) {
      _handleApiException('Failed to get all projects', e);
    } catch (e) {
      throw Exception('Failed to get all projects: $e');
    }
  }

  /// Get a project by its ID
  ///
  /// Returns the project with the specified [id]
  /// Throws an exception if the project doesn't exist
  @override
  Future<Project> getById(int id) async {
    if (id <= 0) {
      throw ArgumentError('Project ID must be a positive integer');
    }

    try {
      final response = await _apiClient.get('${ApiConfig.projects}$id/');
      return Project.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Project with ID $id not found');
      }
      _handleApiException('Failed to get project with ID $id', e);
    } catch (e) {
      throw Exception('Failed to get project with ID $id: $e');
    }
  }

  /// Create a new project
  ///
  /// Takes a [project] object and creates it in the backend
  /// Returns the created project with its assigned ID
  @override
  Future<Project> create(Project project) async {
    try {
      // Validate the project before sending
      _validateProject(project);

      final response = await _apiClient.post(
        ApiConfig.projects,
        project.toJson(),
      );
      return Project.fromJson(response);
    } on ApiException catch (e) {
      _handleApiException('Failed to create project', e);
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  /// Update an existing project
  ///
  /// Takes a [project] object with an ID and updates it in the backend
  /// Returns the updated project
  @override
  Future<Project> update(Project project) async {
    if (project.id == null) {
      throw ArgumentError('Cannot update a project without an ID');
    }

    try {
      // Validate the project before sending
      _validateProject(project);

      final response = await _apiClient.put(
        '${ApiConfig.projects}${project.id}/',
        project.toJson(),
      );
      return Project.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Project with ID ${project.id} not found');
      }
      _handleApiException('Failed to update project', e);
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  /// Delete a project by its ID
  ///
  /// Returns true if the deletion was successful
  @override
  Future<bool> delete(int id) async {
    if (id <= 0) {
      throw ArgumentError('Project ID must be a positive integer');
    }

    try {
      await _apiClient.delete('${ApiConfig.projects}$id/');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Project with ID $id not found');
      }
      _handleApiException('Failed to delete project with ID $id', e);
    } catch (e) {
      throw Exception('Failed to delete project with ID $id: $e');
    }
  }

  /// Get projects for a specific organization
  ///
  /// Returns a list of projects belonging to the organization with [organizationId]
  Future<List<Project>> getByOrganizationId(int organizationId) async {
    if (organizationId <= 0) {
      throw ArgumentError('Organization ID must be a positive integer');
    }

    try {
      final response = await _apiClient.get(
        '${ApiConfig.projects}?organisation=$organizationId',
      );

      final List<dynamic> projectsJson = response['results'] as List<dynamic>;
      return projectsJson.map((json) => Project.fromJson(json)).toList();
    } on ApiException catch (e) {
      _handleApiException(
        'Failed to get projects for organization $organizationId',
        e,
      );
    } catch (e) {
      throw Exception(
        'Failed to get projects for organization $organizationId: $e',
      );
    }
  }

  /// Get projects with a deadline before a specific date
  ///
  /// Returns a list of projects with deadlines before [date]
  Future<List<Project>> getByDeadlineBefore(DateTime date) async {
    try {
      final formattedDate = date.toIso8601String();
      final response = await _apiClient.get(
        '${ApiConfig.projects}?deadline_before=$formattedDate',
      );

      final List<dynamic> projectsJson = response['results'] as List<dynamic>;
      return projectsJson.map((json) => Project.fromJson(json)).toList();
    } on ApiException catch (e) {
      _handleApiException(
        'Failed to get projects with deadline before $date',
        e,
      );
    } catch (e) {
      throw Exception('Failed to get projects with deadline before $date: $e');
    }
  }

  /// Get projects with a specific status (updated to use int instead of string)
  ///
  /// Returns a list of projects with the specified [statusId]
  Future<List<Project>> getByStatus(int statusId) async {
    if (statusId <= 0) {
      throw ArgumentError('Status ID must be a positive integer');
    }

    try {
      final response = await _apiClient.get(
        '${ApiConfig.projects}?status=$statusId',
      );

      final List<dynamic> projectsJson = response['results'] as List<dynamic>;
      return projectsJson.map((json) => Project.fromJson(json)).toList();
    } on ApiException catch (e) {
      _handleApiException('Failed to get projects with status $statusId', e);
    } catch (e) {
      throw Exception('Failed to get projects with status $statusId: $e');
    }
  }

  /// Get projects with status 2 specifically
  ///
  /// Returns a list of projects with status 2
  Future<List<Project>> getActiveProjects() async {
    return [...await getByStatus(2), ...await getByStatus(1)];
  }

  /// Search projects by name or description
  ///
  /// Returns a list of projects matching the search [query]
  Future<List<Project>> search(String query) async {
    if (query.isEmpty) {
      throw ArgumentError('Search query cannot be empty');
    }

    try {
      final response = await _apiClient.get(
        '${ApiConfig.projects}?search=$query',
      );

      final List<dynamic> projectsJson = response['results'] as List<dynamic>;
      return projectsJson.map((json) => Project.fromJson(json)).toList();
    } on ApiException catch (e) {
      _handleApiException('Failed to search projects with query "$query"', e);
    } catch (e) {
      throw Exception('Failed to search projects with query "$query": $e');
    }
  }

  /// Validate project data before sending to API
  void _validateProject(Project project) {
    if (project.name == null || project.name!.isEmpty) {
      throw ArgumentError('Project name cannot be empty');
    }

    // Add more validation as needed based on your Project model
  }

  /// Handle API exceptions with appropriate logging and error propagation
  Never _handleApiException(String message, ApiException e) {
    final errorMessage = '$message: [${e.statusCode}] ${e.message}';
    // Here you could add logging to a service like Sentry or Firebase Crashlytics
    throw Exception(errorMessage);
  }

  /// Dispose of resources
  void dispose() {
    // No need to dispose the _apiClient if it was passed in externally
    // This would be the responsibility of the caller
  }
}
