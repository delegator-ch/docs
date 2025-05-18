// lib/services/organisation_service.dart

import 'dart:async';
import '../models/organisation.dart';
import '../models/project.dart';
import '../models/paginated_response.dart';
import 'base_service.dart';
import 'api_client.dart';
import '../config/api_config.dart';

/// Service for managing Organisation entities
class OrganisationService implements BaseService<Organisation> {
  final ApiClient _apiClient;

  OrganisationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<Organisation>> getAll() async {
    final response = await _apiClient.get(ApiConfig.organisations);

    // Handle paginated response
    final paginatedResponse = PaginatedResponse<Organisation>.fromJson(
      response,
      (json) => Organisation.fromJson(json),
    );

    return paginatedResponse.results;
  }

  @override
  Future<Organisation> getById(int id) async {
    final response = await _apiClient.get('${ApiConfig.organisations}$id/');
    return Organisation.fromJson(response);
  }

  @override
  Future<Organisation> create(Organisation organisation) async {
    final response = await _apiClient.post(
      ApiConfig.organisations,
      organisation.toJson(),
    );
    return Organisation.fromJson(response);
  }

  @override
  Future<Organisation> update(Organisation organisation) async {
    final response = await _apiClient.put(
      '${ApiConfig.organisations}${organisation.id}/',
      organisation.toJson(),
    );
    return Organisation.fromJson(response);
  }

  @override
  Future<bool> delete(int id) async {
    await _apiClient.delete('${ApiConfig.organisations}$id/');
    return true;
  }

  /// Enhance projects with full organisation details
  Future<List<Project>> enhanceProjectsWithOrganisations(
    List<Project> projects,
  ) async {
    // Get unique organisation IDs
    final organisationIds =
        projects.map((p) => p.organisationId).toSet().toList();

    // Fetch each organisation (this could be optimized with batch requests if API supports it)
    final Map<int, Organisation> organisationsMap = {};
    for (final id in organisationIds) {
      try {
        final org = await getById(id);
        organisationsMap[id] = org;
      } catch (e) {
        print('⚠️ Failed to fetch organisation $id: $e');
        // Continue with other organisations
      }
    }

    // Enhance projects with full organisation details
    return projects.map((project) {
      if (organisationsMap.containsKey(project.organisationId)) {
        return project.withOrganisation(
          organisationsMap[project.organisationId]!,
        );
      }
      return project;
    }).toList();
  }
}
