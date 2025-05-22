// lib/services/message_service.dart

import 'dart:async';
import '../models/message.dart';
import '../models/paginated_response.dart';
import 'api_client.dart';
import '../config/api_config.dart';

/// Service for managing Message entities
///
/// This service provides methods for CRUD operations on Message entities,
/// along with specialized query methods for filtering messages.
class MessageService {
  final ApiClient _apiClient;

  /// Creates a new MessageService instance
  ///
  /// Optionally accepts a custom [apiClient], otherwise creates a default one
  MessageService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Fetches all messages
  ///
  /// Returns a list of all messages the user has access to
  Future<List<Message>> getAll() async {
    try {
      final response = await _apiClient.get('messages/');

      // Handle paginated response format
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<Message>.fromJson(
          response,
          (json) => Message.fromJson(json),
        );
        return paginatedResponse.results;
      } else if (response is List) {
        // Handle direct list response (for backward compatibility)
        return response.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get all messages', e);
      return []; // This line won't be reached if _handleApiException rethrows
    } catch (e) {
      throw Exception('Failed to get all messages: $e');
    }
  }

  /// Get a message by its ID
  ///
  /// Returns the message with the specified [id]
  /// Throws an exception if the message doesn't exist
  Future<Message> getById(int id) async {
    if (id <= 0) {
      throw ArgumentError('Message ID must be a positive integer');
    }

    try {
      final response = await _apiClient.get('messages/$id/');
      return Message.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Message with ID $id not found');
      }
      _handleApiException('Failed to get message with ID $id', e);
      throw Exception('This line should not be reached');
    } catch (e) {
      throw Exception('Failed to get message with ID $id: $e');
    }
  }

  /// Create a new message
  ///
  /// Takes a [message] object and creates it in the backend
  /// Returns the created message with its assigned ID
  Future<Message> create(Message message) async {
    try {
      // Validate the message before sending
      _validateMessage(message);

      final response = await _apiClient.post('messages/', message.toJson());
      return Message.fromJson(response);
    } on ApiException catch (e) {
      _handleApiException('Failed to create message', e);
      throw Exception('This line should not be reached');
    } catch (e) {
      throw Exception('Failed to create message: $e');
    }
  }

  /// Update an existing message
  ///
  /// Takes a [message] object with an ID and updates it in the backend
  /// Returns the updated message
  Future<Message> update(Message message) async {
    if (message.id == null) {
      throw ArgumentError('Cannot update a message without an ID');
    }

    try {
      // Validate the message before sending
      _validateMessage(message);

      final response = await _apiClient.put(
        'messages/${message.id}/',
        message.toJson(),
      );
      return Message.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Message with ID ${message.id} not found');
      }
      _handleApiException('Failed to update message', e);
      throw Exception('This line should not be reached');
    } catch (e) {
      throw Exception('Failed to update message: $e');
    }
  }

  /// Delete a message by its ID
  ///
  /// Returns true if the deletion was successful
  Future<bool> delete(int id) async {
    if (id <= 0) {
      throw ArgumentError('Message ID must be a positive integer');
    }

    try {
      await _apiClient.delete('messages/$id/');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Message with ID $id not found');
      }
      _handleApiException('Failed to delete message with ID $id', e);
      return false; // This line won't be reached if _handleApiException rethrows
    } catch (e) {
      throw Exception('Failed to delete message with ID $id: $e');
    }
  }

  /// Get messages for a specific chat
  ///
  /// Returns a list of messages belonging to the chat with [chatId]
  Future<List<Message>> getByChatId(int chatId) async {
    if (chatId <= 0) {
      throw ArgumentError('Chat ID must be a positive integer');
    }

    try {
      final response = await _apiClient.get('messages/?chat=$chatId');

      // Handle paginated response format
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<Message>.fromJson(
          response,
          (json) => Message.fromJson(json),
        );
        return paginatedResponse.results;
      } else if (response is List) {
        // Handle direct list response (for backward compatibility)
        return response.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get messages for chat $chatId', e);
      return [];
    } catch (e) {
      throw Exception('Failed to get messages for chat $chatId: $e');
    }
  }

  /// Get messages sent by a specific user
  ///
  /// Returns a list of messages sent by the user with [userId]
  Future<List<Message>> getByUserId(int userId) async {
    if (userId <= 0) {
      throw ArgumentError('User ID must be a positive integer');
    }

    try {
      final response = await _apiClient.get('messages/?user=$userId');

      // Handle paginated response format
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<Message>.fromJson(
          response,
          (json) => Message.fromJson(json),
        );
        return paginatedResponse.results;
      } else if (response is List) {
        // Handle direct list response (for backward compatibility)
        return response.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get messages for user $userId', e);
      return [];
    } catch (e) {
      throw Exception('Failed to get messages for user $userId: $e');
    }
  }

  /// Search messages by content
  ///
  /// Returns a list of messages matching the search [query]
  Future<List<Message>> search(String query) async {
    if (query.isEmpty) {
      throw ArgumentError('Search query cannot be empty');
    }

    try {
      final response = await _apiClient.get('messages/?search=$query');

      // Handle paginated response
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<Message>.fromJson(
          response,
          (json) => Message.fromJson(json),
        );
        return paginatedResponse.results;
      } else if (response is List) {
        return response.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to search messages with query "$query"', e);
      return [];
    } catch (e) {
      throw Exception('Failed to search messages with query "$query": $e');
    }
  }

  /// Send a message to a chat
  ///
  /// This is a convenience method that creates a new message in a chat
  Future<Message> sendMessage(int chatId, String content) async {
    // Get current user ID - typically would be stored in a user service
    // For this implementation, we'll assume it's available from the AuthService
    // You may need to adjust this to get the current user ID in your app
    final currentUserId = await _getCurrentUserId();

    final message = Message(
      user: currentUserId,
      chat: chatId,
      content: content,
    );

    return create(message);
  }

  /// Get current user ID - placeholder implementation
  ///
  /// In a real app, this would likely be a method from your AuthService
  Future<int> _getCurrentUserId() async {
    // This is a placeholder. In a real implementation, you would:
    // 1. Get the current user from your AuthService
    // 2. Return the user's ID
    // Example:
    // final user = await ServiceRegistry().authService.getCurrentUser();
    // return user.id;

    // For testing purposes, we'll return user ID 3 based on your API response data
    return 3;
  }

  /// Validate message data before sending to API
  void _validateMessage(Message message) {
    if (message.content.isEmpty) {
      throw ArgumentError('Message content cannot be empty');
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
