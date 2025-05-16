// lib/service/task_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';
import 'user_service.dart';
import 'project_service.dart';
import '../model/task_model.dart';

class TaskService {
  static const String baseUrl = 'http://delegator.ch';
  final ProjectService _projectService = ProjectService();

  // Get headers with authentication token
  Map<String, String> _getAuthHeaders() {
    final token = TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Fetch all tasks
  Future<List<Task>> fetchTasks() async {
    final headers = _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> results = data['results'];

      // Convert the JSON data to Task objects
      List<Task> tasks = results.map((json) => Task.fromJson(json)).toList();

      // Enrich tasks with user and project names
      await _enrichTasksWithNames(tasks);

      return tasks;
    } else if (response.statusCode == 401) {
      // Token might be expired
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to load tasks: ${response.statusCode}');
    }
  }

  // Fetch tasks for a specific project
  Future<List<Task>> fetchTasksByProject(int projectId) async {
    final headers = _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/?project=$projectId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> results = data['results'];

      // Convert the JSON data to Task objects
      List<Task> tasks = results.map((json) => Task.fromJson(json)).toList();

      // Enrich tasks with user and project names
      await _enrichTasksWithNames(tasks);

      return tasks;
    } else if (response.statusCode == 401) {
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to load tasks: ${response.statusCode}');
    }
  }

  // Create a new task
  Future<Task> createTask({
    required String title,
    String? description,
    String? dueDate,
    int? assignedTo,
    int? project,
  }) async {
    final headers = _getAuthHeaders();

    final Map<String, dynamic> payload = {'title': title, 'completed': false};

    if (description != null) payload['description'] = description;
    if (dueDate != null) payload['due_date'] = dueDate;
    if (assignedTo != null) payload['assigned_to'] = assignedTo;
    if (project != null) payload['project'] = project;

    final response = await http.post(
      Uri.parse('$baseUrl/tasks/'),
      headers: headers,
      body: json.encode(payload),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      Task task = Task.fromJson(data);

      // Get user name if assigned
      if (task.assignedTo != null) {
        try {
          final user = await UserService.fetchUserById(task.assignedTo!);
          task = task.copyWith(assignedToName: user.displayName);
        } catch (e) {
          print('Error fetching user: $e');
        }
      }

      // Get project name if assigned
      if (task.project != null) {
        try {
          final project = await _projectService.fetchProjectById(task.project!);
          task = task.copyWith(projectName: project.name);
        } catch (e) {
          print('Error fetching project: $e');
        }
      }

      return task;
    } else if (response.statusCode == 401) {
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to create task: ${response.statusCode}');
    }
  }

  // Update an existing task
  Future<Task> updateTask(Task task) async {
    final headers = _getAuthHeaders();

    final Map<String, dynamic> payload = {
      'title': task.title,
      'completed': task.completed,
    };

    if (task.description != null) payload['description'] = task.description;
    if (task.dueDate != null) payload['due_date'] = task.dueDate;
    if (task.assignedTo != null) payload['assigned_to'] = task.assignedTo;
    if (task.project != null) payload['project'] = task.project;

    final response = await http.put(
      Uri.parse('$baseUrl/tasks/${task.id}/'),
      headers: headers,
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Task.fromJson(data)
        ..assignedToName = task.assignedToName
        ..projectName = task.projectName;
    } else if (response.statusCode == 401) {
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to update task: ${response.statusCode}');
    }
  }

  // Toggle task completion status
  Future<Task> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(completed: !task.completed);
    return updateTask(updatedTask);
  }

  // Delete a task
  Future<bool> deleteTask(int taskId) async {
    final headers = _getAuthHeaders();

    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$taskId/'),
      headers: headers,
    );

    if (response.statusCode == 204) {
      return true;
    } else if (response.statusCode == 401) {
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to delete task: ${response.statusCode}');
    }
  }

  // Helper method to enrich tasks with user and project names
  Future<void> _enrichTasksWithNames(List<Task> tasks) async {
    // Map to store user and project data once fetched
    final Map<int, String> userNames = {};
    final Map<int, String> projectNames = {};

    // Process each task
    for (var task in tasks) {
      // Handle assigned user
      if (task.assignedTo != null) {
        if (userNames.containsKey(task.assignedTo)) {
          // Use cached name
          task.assignedToName = userNames[task.assignedTo];
        } else {
          try {
            final user = await UserService.fetchUserById(task.assignedTo!);
            userNames[task.assignedTo!] = user.displayName;
            task.assignedToName = user.displayName;
          } catch (e) {
            print('Error fetching user ${task.assignedTo}: $e');
            task.assignedToName = 'User #${task.assignedTo}';
          }
        }
      }

      // Handle project
      if (task.project != null) {
        if (projectNames.containsKey(task.project)) {
          // Use cached name
          task.projectName = projectNames[task.project];
        } else {
          try {
            final project = await _projectService.fetchProjectById(
              task.project!,
            );
            projectNames[task.project!] =
                project.name ?? 'Project #${task.project}';
            task.projectName = project.name;
          } catch (e) {
            print('Error fetching project ${task.project}: $e');
            task.projectName = 'Project #${task.project}';
          }
        }
      }
    }
  }
}
