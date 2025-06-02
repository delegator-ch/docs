// lib/services/service_registry.dart (Updated with auto token refresh)

import 'package:delegator/services/chat_service.dart';
import 'package:delegator/services/message_service.dart';
import 'package:delegator/services/organisation_service.dart';
import 'package:delegator/services/external_service.dart';

import '../models/api_client.dart';
import 'auth_service.dart';
import 'project_service.dart';
import 'event_service.dart';
import 'task_service.dart';
import 'user_service.dart';

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
  late final MessageService _messageService;
  late final ChatService _chatService;
  late final OrganisationService _organisationService;
  late final UserService _userService;
  late final ExternalService _externalService;

  // Initialization flag
  bool _isInitialized = false;

  /// Initialize the service registry with all services
  Future<void> initialize() async {
    if (_isInitialized) return;

    print("🚀 Initializing ServiceRegistry...");

    // Create API client first
    _apiClient = ApiClient();

    // Create auth service
    _authService = AuthService(apiClient: _apiClient);

    // Set up automatic token refresh callback
    _apiClient.setTokenRefreshCallback(() async {
      final success = await _authService.refreshToken();
      if (!success) {
        print("❌ Auto token refresh failed, logging out user");
        await _authService.logout();
        throw Exception('Token refresh failed - user logged out');
      }
    });

    // Create other services with the shared API client
    _projectService = ProjectService(apiClient: _apiClient);
    _eventService = EventService(apiClient: _apiClient);
    _taskService = TaskService(apiClient: _apiClient);
    _messageService = MessageService(apiClient: _apiClient);
    _chatService = ChatService(apiClient: _apiClient);
    _organisationService = OrganisationService(apiClient: _apiClient);
    _userService = UserService(apiClient: _apiClient);
    _externalService = ExternalService(apiClient: _apiClient);

    _isInitialized = true;
    print("✅ ServiceRegistry initialized with auto token refresh");
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

  /// Get the chat service
  ChatService get chatService {
    _checkInitialization();
    return _chatService;
  }

  /// Get the message service
  MessageService get messageService {
    _checkInitialization();
    return _messageService;
  }

  /// Get the organisation service
  OrganisationService get organisationService {
    _checkInitialization();
    return _organisationService;
  }

  /// Get the user service
  UserService get userService {
    _checkInitialization();
    return _userService;
  }

  /// Get the external service
  ExternalService get externalService {
    _checkInitialization();
    return _externalService;
  }

  /// Check if user is currently logged in
  Future<bool> isLoggedIn() async {
    _checkInitialization();
    return await _authService.isLoggedIn();
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

    print("🧹 Disposing ServiceRegistry...");
    _authService.dispose();
    _apiClient.dispose();

    _isInitialized = false;
    print("✅ ServiceRegistry disposed");
  }
}
