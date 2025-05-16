// lib/service/project_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';
import '../model/project_model.dart';

class ProjectService {
  static const String baseUrl = 'http://delegator.ch';

  // Get headers with authentication token
  Map<String, String> _getAuthHeaders() {
    final token = TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Fetch all projects
  Future<List<Project>> fetchProjects() async {
    final headers = _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/projects/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> results = data['results'];

      // Convert the JSON data to Project objects
      List<Project> projects =
          results.map((json) => Project.fromJson(json)).toList();

      // Fetch organisation names for all projects
      await _enrichProjectsWithOrganisationNames(projects);

      return projects;
    } else if (response.statusCode == 401) {
      // Token might be expired
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to load projects: ${response.statusCode}');
    }
  }

  // Fetch a single project by ID
  Future<Project> fetchProjectById(int projectId) async {
    final headers = _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/projects/$projectId/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final projectData = json.decode(response.body);
      Project project = Project.fromJson(projectData);

      // Fetch organisation name for this project
      await _enrichProjectWithOrganisationName(project);

      return project;
    } else if (response.statusCode == 401) {
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to load project: ${response.statusCode}');
    }
  }

  // Helper method to fetch organisation names for a list of projects
  Future<void> _enrichProjectsWithOrganisationNames(
    List<Project> projects,
  ) async {
    // Create a set of unique organisation IDs to reduce API calls
    final Set<int> organisationIds =
        projects.map((p) => p.organisation).toSet();

    // Map to store organisation data once fetched
    final Map<int, String> organisationNames = {};

    // Fetch each organisation name
    for (int orgId in organisationIds) {
      try {
        final name = await _fetchOrganisationName(orgId);
        organisationNames[orgId] = name;
      } catch (e) {
        print('Error fetching organisation $orgId: $e');
        organisationNames[orgId] = 'Unknown Organisation';
      }
    }

    // Update each project with its organisation name
    for (var project in projects) {
      project.organisationName =
          organisationNames[project.organisation] ??
          'Organisation #${project.organisation}';

      // Set a default name if needed
      if (project.name == null || project.name!.isEmpty) {
        project.name = 'Project #${project.id}';
      }
    }
  }

  // Helper method to fetch organisation name for a single project
  Future<void> _enrichProjectWithOrganisationName(Project project) async {
    try {
      final name = await _fetchOrganisationName(project.organisation);
      project.organisationName = name;
    } catch (e) {
      print('Error fetching organisation ${project.organisation}: $e');
      project.organisationName = 'Organisation #${project.organisation}';
    }

    // Set a default name if needed
    if (project.name == null || project.name!.isEmpty) {
      project.name = 'Project #${project.id}';
    }
  }

  // Fetch organisation name by ID
  Future<String> _fetchOrganisationName(int organisationId) async {
    final headers = _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/organisations/$organisationId/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['name'] ?? 'Organisation #$organisationId';
    } else {
      return 'Organisation #$organisationId';
    }
  }

  // Create a new project
  Future<Project> createProject(
    String name,
    int organisationId,
    int priority, {
    String? deadline,
    int? eventId,
  }) async {
    final headers = _getAuthHeaders();

    final Map<String, dynamic> payload = {
      'name': name,
      'organisation': organisationId,
      'priority': priority,
    };

    if (deadline != null) {
      payload['deadline'] = deadline;
    }

    if (eventId != null) {
      payload['event'] = eventId;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/projects/'),
      headers: headers,
      body: json.encode(payload),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      Project project = Project.fromJson(data);
      project.name = name;
      project.organisationName = await _fetchOrganisationName(organisationId);
      return project;
    } else if (response.statusCode == 401) {
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to create project: ${response.statusCode}');
    }
  }

  // Update an existing project
  Future<Project> updateProject(Project project) async {
    final headers = _getAuthHeaders();

    final Map<String, dynamic> payload = {
      'id': project.id,
      'organisation': project.organisation,
      'priority': project.priority,
    };

    if (project.deadline != null) {
      payload['deadline'] = project.deadline;
    }

    if (project.event != null) {
      payload['event'] = project.event;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/projects/${project.id}/'),
      headers: headers,
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Project.fromJson(data)
        ..name = project.name
        ..organisationName = project.organisationName;
    } else if (response.statusCode == 401) {
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to update project: ${response.statusCode}');
    }
  }

  // Delete a project
  Future<bool> deleteProject(int projectId) async {
    final headers = _getAuthHeaders();

    final response = await http.delete(
      Uri.parse('$baseUrl/projects/$projectId/'),
      headers: headers,
    );

    if (response.statusCode == 204) {
      return true;
    } else if (response.statusCode == 401) {
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to delete project: ${response.statusCode}');
    }
  }
}
