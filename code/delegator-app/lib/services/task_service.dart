// lib/services/task_service.dart

import 'dart:async';
import '../models/task.dart';
import '../models/paginated_response.dart';
import 'base_service.dart';
import 'api_client.dart';
import '../config/api_config.dart';

/// Service for managing Task entities
///
/// This service provides methods for CRUD operations on Task entities,
/// along with specialized query methods for filtering tasks.
class TaskService implements BaseService<Task> {
  final ApiClient _apiClient;

  /// Creates a new TaskService instance
  ///
  /// Optionally accepts a custom [apiClient], otherwise creates a default one
  TaskService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches all tasks
  ///
  /// Returns a list of all tasks the user has access to
  @override
  Future<List<Task>> getAll() async {
    try {
      final response = await _apiClient.get(ApiConfig.tasks);

      // Handle paginated response format
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<Task>.fromJson(
          response,
          (json) => Task.fromJson(json),
        );
        return paginatedResponse.results;
      } else if (response is List) {
        // Handle direct list response (for backward compatibility)
        return response.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get all tasks', e);
      return []; // This line won't be reached if _handleApiException rethrows
    } catch (e) {
      throw Exception('Failed to get all tasks: $e');
    }
  }

  /// Get a task by its ID
  ///
  /// Returns the task with the specified [id]
  /// Throws an exception if the task doesn't exist
  @override
  Future<Task> getById(int id) async {
    if (id <= 0) {
      throw ArgumentError('Task ID must be a positive integer');
    }

    try {
      final response = await _apiClient.get('${ApiConfig.tasks}$id/');
      return Task.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Task with ID $id not found');
      }
      _handleApiException('Failed to get task with ID $id', e);
      throw Exception('This line should not be reached');
    } catch (e) {
      throw Exception('Failed to get task with ID $id: $e');
    }
  }

  /// Create a new task
  ///
  /// Takes a [task] object and creates it in the backend
  /// Returns the created task with its assigned ID
  @override
  Future<Task> create(Task task) async {
    try {
      // Validate the task before sending
      _validateTask(task);

      final response = await _apiClient.post(ApiConfig.tasks, task.toJson());
      return Task.fromJson(response);
    } on ApiException catch (e) {
      _handleApiException('Failed to create task', e);
      throw Exception('This line should not be reached');
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  /// Update an existing task
  ///
  /// Takes a [task] object with an ID and updates it in the backend
  /// Returns the updated task
  @override
  Future<Task> update(Task task) async {
    if (task.id == null) {
      throw ArgumentError('Cannot update a task without an ID');
    }

    try {
      // Validate the task before sending
      _validateTask(task);

      final response = await _apiClient.put(
        '${ApiConfig.tasks}${task.id}/',
        task.toJson(),
      );
      return Task.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Task with ID ${task.id} not found');
      }
      _handleApiException('Failed to update task', e);
      throw Exception('This line should not be reached');
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  /// Delete a task by its ID
  ///
  /// Returns true if the deletion was successful
  @override
  Future<bool> delete(int id) async {
    if (id <= 0) {
      throw ArgumentError('Task ID must be a positive integer');
    }

    try {
      await _apiClient.delete('${ApiConfig.tasks}$id/');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Task with ID $id not found');
      }
      _handleApiException('Failed to delete task with ID $id', e);
      return false; // This line won't be reached if _handleApiException rethrows
    } catch (e) {
      throw Exception('Failed to delete task with ID $id: $e');
    }
  }

  /// Get tasks for a specific project
  ///
  /// Returns a list of tasks belonging to the project with [projectId]
  Future<List<Task>> getByProjectId(int projectId) async {
    if (projectId <= 0) {
      throw ArgumentError('Project ID must be a positive integer');
    }

    try {
      final response = await _apiClient.get(
        '${ApiConfig.tasks}?project=$projectId',
      );

      // Handle paginated response format
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<Task>.fromJson(
          response,
          (json) => Task.fromJson(json),
        );
        return paginatedResponse.results;
      } else if (response is List) {
        // Handle direct list response (for backward compatibility)
        return response.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get tasks for project $projectId', e);
      return [];
    } catch (e) {
      throw Exception('Failed to get tasks for project $projectId: $e');
    }
  }

  /// Get tasks assigned to a specific user
  ///
  /// Returns a list of tasks assigned to the user with [userId]
  Future<List<Task>> getByUserId(int userId) async {
    if (userId <= 0) {
      throw ArgumentError('User ID must be a positive integer');
    }

    try {
      final response = await _apiClient.get('${ApiConfig.tasks}?user=$userId');

      // Handle paginated response
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<Task>.fromJson(
          response,
          (json) => Task.fromJson(json),
        );
        return paginatedResponse.results;
      } else if (response is List) {
        return response.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get tasks for user $userId', e);
      return [];
    } catch (e) {
      throw Exception('Failed to get tasks for user $userId: $e');
    }
  }

  /// Get tasks with a specific status
  ///
  /// Returns a list of tasks with the status ID [statusId]
  Future<List<Task>> getByStatusId(int statusId) async {
    if (statusId <= 0) {
      throw ArgumentError('Status ID must be a positive integer');
    }

    try {
      final response = await _apiClient.get(
        '${ApiConfig.tasks}?status=$statusId',
      );

      // Handle paginated response
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<Task>.fromJson(
          response,
          (json) => Task.fromJson(json),
        );
        return paginatedResponse.results;
      } else if (response is List) {
        return response.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get tasks with status $statusId', e);
      return [];
    } catch (e) {
      throw Exception('Failed to get tasks with status $statusId: $e');
    }
  }

  /// Get tasks with deadlines before a specific date
  ///
  /// Returns a list of tasks with deadlines before [date]
  Future<List<Task>> getByDeadlineBefore(DateTime date) async {
    try {
      final formattedDate = date.toIso8601String();
      final response = await _apiClient.get(
        '${ApiConfig.tasks}?deadline_before=$formattedDate',
      );

      // Handle paginated response
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<Task>.fromJson(
          response,
          (json) => Task.fromJson(json),
        );
        return paginatedResponse.results;
      } else if (response is List) {
        return response.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get tasks with deadline before $date', e);
      return [];
    } catch (e) {
      throw Exception('Failed to get tasks with deadline before $date: $e');
    }
  }

  /// Get tasks dependent on a specific task
  ///
  /// Returns a list of tasks that depend on the task with [dependentTaskId]
  Future<List<Task>> getByDependentTaskId(int dependentTaskId) async {
    if (dependentTaskId <= 0) {
      throw ArgumentError('Dependent task ID must be a positive integer');
    }

    try {
      final response = await _apiClient.get(
        '${ApiConfig.tasks}?dependent_on_task=$dependentTaskId',
      );

      // Handle paginated response
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<Task>.fromJson(
          response,
          (json) => Task.fromJson(json),
        );
        return paginatedResponse.results;
      } else if (response is List) {
        return response.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException(
        'Failed to get tasks dependent on task $dependentTaskId',
        e,
      );
      return [];
    } catch (e) {
      throw Exception(
        'Failed to get tasks dependent on task $dependentTaskId: $e',
      );
    }
  }

  /// Get tasks for a specific event
  ///
  /// Returns a list of tasks associated with the event with [eventId]
  Future<List<Task>> getByEventId(int eventId) async {
    if (eventId <= 0) {
      throw ArgumentError('Event ID must be a positive integer');
    }

    try {
      final response = await _apiClient.get(
        '${ApiConfig.tasks}?event=$eventId',
      );

      // Handle paginated response
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<Task>.fromJson(
          response,
          (json) => Task.fromJson(json),
        );
        return paginatedResponse.results;
      } else if (response is List) {
        return response.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get tasks for event $eventId', e);
      return [];
    } catch (e) {
      throw Exception('Failed to get tasks for event $eventId: $e');
    }
  }

  /// Search tasks by title or content
  ///
  /// Returns a list of tasks matching the search [query]
  Future<List<Task>> search(String query) async {
    if (query.isEmpty) {
      throw ArgumentError('Search query cannot be empty');
    }

    try {
      final response = await _apiClient.get('${ApiConfig.tasks}?search=$query');

      // Handle paginated response
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<Task>.fromJson(
          response,
          (json) => Task.fromJson(json),
        );
        return paginatedResponse.results;
      } else if (response is List) {
        return response.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to search tasks with query "$query"', e);
      return [];
    } catch (e) {
      throw Exception('Failed to search tasks with query "$query": $e');
    }
  }

  /// Validate task data before sending to API
  void _validateTask(Task task) {
    if (task.title.isEmpty) {
      throw ArgumentError('Task title cannot be empty');
    }

    // Add more validation as needed based on your Task model
  }

  /// Handle API exceptions with appropriate logging and error propagation
  Never _handleApiException(String message, ApiException e) {
    final errorMessage = '$message: [${e.statusCode}] ${e.message}';
    // Here you could add logging to a service like Sentry or Firebase Crashlytics
    throw Exception(errorMessage);
  }

  /// Dispose of resources if needed
  void dispose() {
    // No resources to dispose at this time
  }
}
