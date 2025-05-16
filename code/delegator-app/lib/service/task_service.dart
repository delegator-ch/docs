// lib/service/task_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';
import 'user_service.dart';
import 'project_service.dart';
import '../model/task_model.dart';
import 'dart:async';
import 'dart:io';

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
    // Make sure this function runs on a background isolate to avoid UI freezing
    return compute(_createTaskIsolate, {
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'assignedTo': assignedTo,
      'project': project,
      'baseUrl': baseUrl,
      'authToken': await TokenManager.getToken(), // Pass token explicitly
    });
  }

  // This function runs in a separate isolate
  Future<Task> _createTaskIsolate(Map<String, dynamic> params) async {
    final String title = params['title'];
    final String? description = params['description'];
    final String? dueDate = params['dueDate'];
    final int? assignedTo = params['assignedTo'];
    final int? project = params['project'];
    final String baseUrl = params['baseUrl'];
    final String? token = params['authToken'];

    // Create auth headers manually since we're in an isolate
    final Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Format request according to API structure
    final Map<String, dynamic> payload = {
      'title': title,
      'status': 1, // Default to Backlog
    };

    // Map our fields to API expected fields
    if (description != null) payload['content'] = description;
    if (dueDate != null) payload['deadline'] = dueDate;
    if (assignedTo != null) payload['user'] = assignedTo;
    if (project != null) payload['project'] = project;

    print('Creating task with payload: $payload');

    // Check for connectivity first
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception(
          'No internet connection. Please check your network and try again.',
        );
      }

      // Try both HTTP and HTTPS if needed
      String finalUrl = '$baseUrl/tasks/';
      if (!finalUrl.startsWith('http')) {
        finalUrl = 'https://$finalUrl';
      }

      print('Sending request to: $finalUrl');

      // Create a client with shorter timeout
      final client = http.Client();
      try {
        final response = await client
            .post(
              Uri.parse(finalUrl),
              headers: headers,
              body: json.encode(payload),
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                print('Request timed out after 15 seconds');
                throw TimeoutException('Request timed out');
              },
            );

        print('Response received: ${response.statusCode}');

        if (response.statusCode == 201) {
          final data = json.decode(response.body);
          return Task.fromJson(data);
        } else if (response.statusCode == 401) {
          throw Exception('Authentication failed. Please login again.');
        } else {
          throw Exception(
            'Failed to create task: ${response.statusCode} - ${response.body}',
          );
        }
      } finally {
        client.close();
      }
    } on TimeoutException {
      print('Network request timed out - server may be unreachable');
      throw Exception('Server not responding. Please try again later.');
    } on SocketException catch (e) {
      print('Socket exception: $e');

      // Try alternative URL with different protocol
      if (baseUrl.startsWith('http://')) {
        final httpsUrl = baseUrl.replaceFirst('http://', 'https://');
        print('Retrying with HTTPS: $httpsUrl/tasks/');

        try {
          final client = http.Client();
          try {
            final response = await client
                .post(
                  Uri.parse('$httpsUrl/tasks/'),
                  headers: headers,
                  body: json.encode(payload),
                )
                .timeout(const Duration(seconds: 15));

            print('HTTPS Response received: ${response.statusCode}');

            if (response.statusCode == 201) {
              final data = json.decode(response.body);
              return Task.fromJson(data);
            } else {
              throw Exception('Failed with HTTPS too: ${response.statusCode}');
            }
          } finally {
            client.close();
          }
        } catch (e) {
          print('HTTPS attempt also failed: $e');
          throw Exception(
            'Network error. Please check your connection and server URL.',
          );
        }
      } else {
        throw Exception(
          'Network error. Please check your connection and server URL.',
        );
      }
    } catch (e) {
      print('Exception during HTTP request: $e');
      throw Exception('Failed to create task: $e');
    }
  }

  // Update an existing task
  Future<Task> updateTask(Task task) async {
    final headers = _getAuthHeaders();

    // Format API request according to API structure
    final Map<String, dynamic> payload = {
      'title': task.title,
      'status': task.status,
    };

    // Map our fields to API expected fields
    if (task.description != null) payload['content'] = task.description;
    if (task.dueDate != null) payload['deadline'] = task.dueDate;
    if (task.assignedTo != null) payload['user'] = task.assignedTo;
    if (task.project != null) payload['project'] = task.project;
    if (task.duration != null) payload['duration'] = task.duration;
    if (task.dependentOnTask != null)
      payload['dependent_on_task'] = task.dependentOnTask;
    if (task.event != null) payload['event'] = task.event;

    print('Updating task with payload: $payload'); // For debugging

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
      throw Exception(
        'Failed to update task: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Toggle task completion status (update task status)
  Future<Task> toggleTaskCompletion(Task task) async {
    // If task is completed (status 3), change to Backlog (1)
    // Otherwise change to Done (3)
    final newStatus = task.status == 3 ? 1 : 3;
    final updatedTask = task.copyWith(status: newStatus);
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
      throw Exception(
        'Failed to delete task: ${response.statusCode} - ${response.body}',
      );
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
