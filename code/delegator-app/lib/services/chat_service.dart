// lib/services/chat_service.dart

import 'dart:async';
import '../models/chat.dart';
import '../models/paginated_response.dart';
import 'base_service.dart';
import 'api_client.dart';

/// Service for managing Chat entities
///
/// This service provides methods for CRUD operations on Chat entities,
/// along with specialized query methods for filtering chats.
class ChatService implements BaseService<Chat> {
  final ApiClient _apiClient;

  /// Creates a new ChatService instance
  ///
  /// Optionally accepts a custom [apiClient], otherwise creates a default one
  ChatService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches all chats
  ///
  /// Returns a list of all chats the user has access to
  @override
  Future<List<Chat>> getAll() async {
    try {
      final response = await _apiClient.get('chats/');

      // Handle paginated response format
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<Chat>.fromJson(
          response,
          (json) => Chat.fromJson(json),
        );
        return paginatedResponse.results;
      } else if (response is List) {
        // Handle direct list response (for backward compatibility)
        return response.map((json) => Chat.fromJson(json)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get all chats', e);
    } catch (e) {
      throw Exception('Failed to get all chats: $e');
    }
  }

  /// Get a chat by its ID
  ///
  /// Returns the chat with the specified [id]
  /// Throws an exception if the chat doesn't exist
  @override
  Future<Chat> getById(int id) async {
    if (id <= 0) {
      throw ArgumentError('Chat ID must be a positive integer');
    }

    try {
      final response = await _apiClient.get('chats/$id/');
      return Chat.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Chat with ID $id not found');
      }
      _handleApiException('Failed to get chat with ID $id', e);
    } catch (e) {
      throw Exception('Failed to get chat with ID $id: $e');
    }
  }

  /// Create a new chat
  ///
  /// Takes a [chat] object and creates it in the backend
  /// Returns the created chat with its assigned ID
  @override
  Future<Chat> create(Chat chat) async {
    try {
      // Validate the chat before sending
      _validateChat(chat);

      final response = await _apiClient.post('chats/', chat.toJson());
      return Chat.fromJson(response);
    } on ApiException catch (e) {
      _handleApiException('Failed to create chat', e);
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  /// Update an existing chat
  ///
  /// Takes a [chat] object with an ID and updates it in the backend
  /// Returns the updated chat
  @override
  Future<Chat> update(Chat chat) async {
    if (chat.id == null) {
      throw ArgumentError('Cannot update a chat without an ID');
    }

    try {
      // Validate the chat before sending
      _validateChat(chat);

      final response = await _apiClient.put('chats/${chat.id}/', chat.toJson());
      return Chat.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Chat with ID ${chat.id} not found');
      }
      _handleApiException('Failed to update chat', e);
    } catch (e) {
      throw Exception('Failed to update chat: $e');
    }
  }

  /// Delete a chat by its ID
  ///
  /// Returns true if the deletion was successful
  @override
  Future<bool> delete(int id) async {
    if (id <= 0) {
      throw ArgumentError('Chat ID must be a positive integer');
    }

    try {
      await _apiClient.delete('chats/$id/');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Chat with ID $id not found');
      }
      _handleApiException('Failed to delete chat with ID $id', e);
    } catch (e) {
      throw Exception('Failed to delete chat with ID $id: $e');
    }
  }

  /// Get chats for a specific organization
  ///
  /// Returns a list of chats belonging to the organization with [organisationId]
  Future<List<Chat>> getByOrganisationId(int organisationId) async {
    if (organisationId <= 0) {
      throw ArgumentError('Organisation ID must be a positive integer');
    }

    try {
      final response = await _apiClient.get(
        'chats/?organisation=$organisationId',
      );

      // Handle paginated response format
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<Chat>.fromJson(
          response,
          (json) => Chat.fromJson(json),
        );
        return paginatedResponse.results;
      } else if (response is List) {
        // Handle direct list response (for backward compatibility)
        return response.map((json) => Chat.fromJson(json)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException(
        'Failed to get chats for organisation $organisationId',
        e,
      );
    } catch (e) {
      throw Exception(
        'Failed to get chats for organisation $organisationId: $e',
      );
    }
  }

  /// Get chats for a specific project
  ///
  /// Returns a list of chats belonging to the project with [projectId]
  Future<List<Chat>> getByProjectId(int projectId) async {
    if (projectId <= 0) {
      throw ArgumentError('Project ID must be a positive integer');
    }

    try {
      final response = await _apiClient.get('chats/?project=$projectId');

      // Handle paginated response format
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<Chat>.fromJson(
          response,
          (json) => Chat.fromJson(json),
        );
        return paginatedResponse.results;
      } else if (response is List) {
        // Handle direct list response (for backward compatibility)
        return response.map((json) => Chat.fromJson(json)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get chats for project $projectId', e);
    } catch (e) {
      throw Exception('Failed to get chats for project $projectId: $e');
    }
  }

  /// Get chats by type
  ///
  /// Returns a list of chats with the specified [chatType]
  Future<List<Chat>> getByChatType(String chatType) async {
    if (chatType.isEmpty) {
      throw ArgumentError('Chat type cannot be empty');
    }

    try {
      final response = await _apiClient.get('chats/?chat_type=$chatType');

      // Handle paginated response format
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<Chat>.fromJson(
          response,
          (json) => Chat.fromJson(json),
        );
        return paginatedResponse.results;
      } else if (response is List) {
        // Handle direct list response (for backward compatibility)
        return response.map((json) => Chat.fromJson(json)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get chats of type $chatType', e);
    } catch (e) {
      throw Exception('Failed to get chats of type $chatType: $e');
    }
  }

  /// Validate chat data before sending to API
  void _validateChat(Chat chat) {
    if (chat.name.isEmpty) {
      throw ArgumentError('Chat name cannot be empty');
    }

    if (chat.chatType.isEmpty) {
      throw ArgumentError('Chat type cannot be empty');
    }

    // Add more validation as needed
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
