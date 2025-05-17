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

  // Fetch all tasks with auto-retry
  Future<List<Task>> fetchTasks() async {
    try {
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
        // Token might be expired, try to refresh
        print('Authentication failed, attempting to fetch new token...');
        bool tokenFetched =
            await TokenManager.fetchTokenWithDefaultCredentials();

        if (tokenFetched) {
          // Try again with the new token
          return fetchTasks();
        } else {
          // Still failed
          TokenManager.clearToken();
          throw Exception('Authentication failed. Please login again.');
        }
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchTasks: $e');
      throw e;
    }
  }

  // Fetch tasks for a specific project with auto-retry
  Future<List<Task>> fetchTasksByProject(int projectId) async {
    try {
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
        // Token might be expired, try to refresh
        print('Authentication failed, attempting to fetch new token...');
        bool tokenFetched =
            await TokenManager.fetchTokenWithDefaultCredentials();

        if (tokenFetched) {
          // Try again with the new token
          return fetchTasksByProject(projectId);
        } else {
          // Still failed
          TokenManager.clearToken();
          throw Exception('Authentication failed. Please login again.');
        }
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchTasksByProject: $e');
      throw e;
    }
  }

  // Create a new task with auto-retry, using API naming conventions
  Future<Task> createTask({
    required String title,
    int status = 1,
    String? content, // Changed from description to content to match API
    String? deadline, // Changed from dueDate to deadline to match API
    int? user, // Changed from assignedTo to user to match API
    required int project,
  }) async {
    try {
      final headers = _getAuthHeaders();

      // Format request according to API structure using API field names directly
      final Map<String, dynamic> payload = {
        'title': title,
        'status': status,
        'project': project,
      };

      // Add optional fields (already using API names)
      if (content != null) payload['content'] = content;
      if (deadline != null) payload['deadline'] = deadline;
      if (user != null) payload['user'] = user;

      // Log the payload for debugging
      print('Creating task with payload: ${json.encode(payload)}');

      final response = await http.post(
        Uri.parse('$baseUrl/tasks/'),
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Task created successfully: ${data['id']}');
        Task task = Task.fromJson(data);

        // Get user name if assigned
        if (task.user != null) {
          try {
            final user = await UserService.fetchUserById(task.user!);
            task = task.copyWith(userName: user.displayName);
          } catch (e) {
            print('Error fetching user: $e');
          }
        }

        // Get project name if assigned
        if (task.project != null) {
          try {
            final project = await _projectService.fetchProjectById(
              task.project,
            );
            task = task.copyWith(projectName: project.name);
          } catch (e) {
            print('Error fetching project: $e');
          }
        }

        return task;
      } else if (response.statusCode == 401) {
        // Token might be expired, try to refresh
        print('Authentication failed, attempting to fetch new token...');
        bool tokenFetched =
            await TokenManager.fetchTokenWithDefaultCredentials();

        if (tokenFetched) {
          // Try again with the new token
          return createTask(
            title: title,
            content: content,
            deadline: deadline,
            user: user,
            project: project,
          );
        } else {
          // Still failed
          TokenManager.clearToken();
          throw Exception('Authentication failed. Please login again.');
        }
      } else {
        // Enhanced error message with response body
        print(
          'Failed to create task: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to create task: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in createTask: $e');
      throw e;
    }
  }

  // Update an existing task with auto-retry, using API naming conventions
  Future<Task> updateTask(Task task) async {
    try {
      final headers = _getAuthHeaders();

      // Format API request using API field names directly
      final Map<String, dynamic> payload = {
        'title': task.title,
        'status': task.status,
        'project': task.project,
      };

      // Add optional fields (already using API names)
      if (task.content != null) payload['content'] = task.content;
      if (task.deadline != null) payload['deadline'] = task.deadline;
      if (task.user != null) payload['user'] = task.user;
      if (task.duration != null) payload['duration'] = task.duration;
      if (task.dependentOnTask != null)
        payload['dependent_on_task'] = task.dependentOnTask;
      if (task.event != null) payload['event'] = task.event;

      // Log the payload for debugging
      print('Updating task ${task.id} with payload: ${json.encode(payload)}');

      final response = await http.put(
        Uri.parse('$baseUrl/tasks/${task.id}/'),
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Task.fromJson(data)
          ..userName = task.userName
          ..projectName = task.projectName;
      } else if (response.statusCode == 401) {
        // Token might be expired, try to refresh
        print('Authentication failed, attempting to fetch new token...');
        bool tokenFetched =
            await TokenManager.fetchTokenWithDefaultCredentials();

        if (tokenFetched) {
          // Try again with the new token
          return updateTask(task);
        } else {
          // Still failed
          TokenManager.clearToken();
          throw Exception('Authentication failed. Please login again.');
        }
      } else {
        // Enhanced error message with response body
        print(
          'Failed to update task: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to update task: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in updateTask: $e');
      throw e;
    }
  }

  // Toggle task completion status with auto-retry
  Future<Task> toggleTaskCompletion(Task task) async {
    // If task is completed (status 3), change to Backlog (1)
    // Otherwise change to Done (3)
    final newStatus = task.status == 3 ? 1 : 3;
    final updatedTask = task.copyWith(status: newStatus);
    return updateTask(updatedTask);
  }

  // Delete a task with auto-retry
  Future<bool> deleteTask(int taskId) async {
    try {
      final headers = _getAuthHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskId/'),
        headers: headers,
      );

      if (response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 401) {
        // Token might be expired, try to refresh
        print('Authentication failed, attempting to fetch new token...');
        bool tokenFetched =
            await TokenManager.fetchTokenWithDefaultCredentials();

        if (tokenFetched) {
          // Try again with the new token
          return deleteTask(taskId);
        } else {
          // Still failed
          TokenManager.clearToken();
          throw Exception('Authentication failed. Please login again.');
        }
      } else {
        // Enhanced error message with response body
        print(
          'Failed to delete task: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to delete task: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in deleteTask: $e');
      throw e;
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
      if (task.user != null) {
        if (userNames.containsKey(task.user)) {
          // Use cached name
          task.userName = userNames[task.user];
        } else {
          try {
            final user = await UserService.fetchUserById(task.user!);
            userNames[task.user!] = user.displayName;
            task.userName = user.displayName;
          } catch (e) {
            print('Error fetching user ${task.user}: $e');
            task.userName = 'User #${task.user}';
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
              task.project,
            );
            projectNames[task.project] =
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
