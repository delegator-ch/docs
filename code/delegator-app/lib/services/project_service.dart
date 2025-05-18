// lib/services/project_service.dart

import 'dart:async';
import '../models/project.dart';
import '../models/paginated_response.dart';
import 'base_service.dart';
import 'api_client.dart';
import '../config/api_config.dart';

/// Service for managing Project entities
class ProjectService implements BaseService<Project> {
  final ApiClient _apiClient;

  ProjectService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<Project>> getAll() async {
    final response = await _apiClient.get(ApiConfig.projects);

    // Handle paginated response
    final paginatedResponse = PaginatedResponse<Project>.fromJson(
      response,
      (json) => Project.fromJson(json),
    );

    return paginatedResponse.results;
  }

  /// Get all projects with pagination details
  Future<PaginatedResponse<Project>> getAllPaginated() async {
    final response = await _apiClient.get(ApiConfig.projects);

    return PaginatedResponse<Project>.fromJson(
      response,
      (json) => Project.fromJson(json),
    );
  }

  /// Get next page of projects
  Future<PaginatedResponse<Project>?> getNextPage(
    PaginatedResponse<Project> currentPage,
  ) async {
    if (currentPage.next == null) {
      return null;
    }

    final response = await _apiClient.getFromUrl(currentPage.next!);

    return PaginatedResponse<Project>.fromJson(
      response,
      (json) => Project.fromJson(json),
    );
  }

  @override
  Future<Project> getById(int id) async {
    final response = await _apiClient.get('${ApiConfig.projects}$id/');
    return Project.fromJson(response);
  }

  @override
  Future<Project> create(Project project) async {
    final response = await _apiClient.post(
      ApiConfig.projects,
      project.toJson(),
    );
    return Project.fromJson(response);
  }

  @override
  Future<Project> update(Project project) async {
    if (project.id == null) {
      throw Exception('Cannot update a project without an ID');
    }

    final response = await _apiClient.put(
      '${ApiConfig.projects}${project.id}/',
      project.toJson(),
    );
    return Project.fromJson(response);
  }

  @override
  Future<bool> delete(int id) async {
    await _apiClient.delete('${ApiConfig.projects}$id/');
    return true;
  }

  /// Get projects for a specific organization
  Future<List<Project>> getByOrganizationId(int organizationId) async {
    final response = await _apiClient.get(
      '${ApiConfig.projects}?organisation=$organizationId',
    );

    final paginatedResponse = PaginatedResponse<Project>.fromJson(
      response,
      (json) => Project.fromJson(json),
    );

    return paginatedResponse.results;
  }

  /// Get projects with a deadline before a specific date
  Future<List<Project>> getByDeadlineBefore(DateTime date) async {
    final formattedDate = date.toIso8601String();
    final response = await _apiClient.get(
      '${ApiConfig.projects}?deadline_before=$formattedDate',
    );

    final paginatedResponse = PaginatedResponse<Project>.fromJson(
      response,
      (json) => Project.fromJson(json),
    );

    return paginatedResponse.results;
  }
}
