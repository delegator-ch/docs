// lib/services/task_service.dart

import 'dart:async';
import '../models/task.dart';
import 'base_service.dart';
import 'api_client.dart';
import '../config/api_config.dart';

/// Service for managing Task entities
class TaskService implements BaseService<Task> {
  final ApiClient _apiClient;

  TaskService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<Task>> getAll() async {
    final response = await _apiClient.get(ApiConfig.tasks);
    return (response as List).map((json) => Task.fromJson(json)).toList();
  }

  @override
  Future<Task> getById(int id) async {
    final response = await _apiClient.get('${ApiConfig.tasks}/$id');
    return Task.fromJson(response);
  }

  @override
  Future<Task> create(Task task) async {
    final response = await _apiClient.post(ApiConfig.tasks, task.toJson());
    return Task.fromJson(response);
  }

  @override
  Future<Task> update(Task task) async {
    if (task.id == null) {
      throw Exception('Cannot update a task without an ID');
    }

    final response = await _apiClient.put(
      '${ApiConfig.tasks}/${task.id}',
      task.toJson(),
    );
    return Task.fromJson(response);
  }

  @override
  Future<bool> delete(int id) async {
    await _apiClient.delete('${ApiConfig.tasks}/$id');
    return true;
  }

  /// Get tasks for a specific project
  Future<List<Task>> getByProjectId(int projectId) async {
    final response = await _apiClient.get(
      '${ApiConfig.tasks}?project=$projectId',
    );
    return (response as List).map((json) => Task.fromJson(json)).toList();
  }

  /// Get tasks assigned to a specific user
  Future<List<Task>> getByUserId(int userId) async {
    final response = await _apiClient.get('${ApiConfig.tasks}?user=$userId');
    return (response as List).map((json) => Task.fromJson(json)).toList();
  }

  /// Get tasks by status
  Future<List<Task>> getByStatusId(int statusId) async {
    final response = await _apiClient.get(
      '${ApiConfig.tasks}?status=$statusId',
    );
    return (response as List).map((json) => Task.fromJson(json)).toList();
  }

  /// Get tasks with deadlines before a specific date
  Future<List<Task>> getByDeadlineBefore(DateTime date) async {
    final formattedDate = date.toIso8601String();
    final response = await _apiClient.get(
      '${ApiConfig.tasks}?deadline_before=$formattedDate',
    );
    return (response as List).map((json) => Task.fromJson(json)).toList();
  }
}
