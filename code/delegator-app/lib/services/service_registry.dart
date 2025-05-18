// lib/services/service_registry.dart

import 'api_client.dart';
import 'auth_service.dart';
import 'project_service.dart';
import 'event_service.dart';
import 'task_service.dart';

/// Centralized registry for all services
/// Follows the service locator pattern
class ServiceRegistry {
  // Singleton instance
  static final ServiceRegistry _instance = ServiceRegistry._internal();

  // Factory constructor to return the singleton instance
  factory ServiceRegistry() => _instance;

  // Private constructor
  ServiceRegistry._internal();

  // Services
  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final ProjectService _projectService;
  late final EventService _eventService;
  late final TaskService _taskService;

  // Initialization flag
  bool _isInitialized = false;

  /// Initialize the service registry with all services
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Create API client first
    _apiClient = ApiClient();

    // Create services with the shared API client
    _authService = AuthService(apiClient: _apiClient);
    _projectService = ProjectService(apiClient: _apiClient);
    _eventService = EventService(apiClient: _apiClient);
    _taskService = TaskService(apiClient: _apiClient);

    // Initialize authentication
    await _authService.init();

    _isInitialized = true;
  }

  /// Get the API client
  ApiClient get apiClient {
    _checkInitialization();
    return _apiClient;
  }

  /// Get the authentication service
  AuthService get authService {
    _checkInitialization();
    return _authService;
  }

  /// Get the project service
  ProjectService get projectService {
    _checkInitialization();
    return _projectService;
  }

  /// Get the event service
  EventService get eventService {
    _checkInitialization();
    return _eventService;
  }

  /// Get the task service
  TaskService get taskService {
    _checkInitialization();
    return _taskService;
  }

  /// Check if the registry is initialized
  void _checkInitialization() {
    if (!_isInitialized) {
      throw Exception(
        'ServiceRegistry is not initialized. Call initialize() first.',
      );
    }
  }

  /// Dispose all services
  void dispose() {
    if (!_isInitialized) return;

    _authService.dispose();
    _apiClient.dispose();

    _isInitialized = false;
  }
}
