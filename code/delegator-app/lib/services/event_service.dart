// lib/services/event_service.dart

import 'dart:async';
import '../models/event.dart';
import '../services/base_service.dart';
import '../models/api_client.dart';
import '../config/api_config.dart';

/// Service for managing Event entities
///
/// This service provides methods for CRUD operations on Event entities,
/// along with filtering and specialized queries.
class EventService implements BaseService<Event> {
  final ApiClient _apiClient;

  /// Creates a new EventService instance
  EventService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches all events
  @override
  Future<List<Event>> getAll() async {
    try {
      final fullResponse = await _apiClient.get(ApiConfig.events);
      final response = fullResponse.data;
      // Handle paginated response format
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final List<dynamic> results = response['results'];
        return results.map((e) => Event.fromJson(e)).toList();
      } else if (response is List) {
        // Handle direct list response (for backward compatibility)
        return response.map((e) => Event.fromJson(e)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get all events', e);
    } catch (e) {
      throw Exception('Failed to get all events: $e');
    }
  }

  /// Fetches an event by ID
  @override
  Future<Event> getById(int id) async {
    if (id <= 0) {
      throw ArgumentError('Event ID must be a positive integer');
    }

    try {
      final fullResponse = await _apiClient.get('${ApiConfig.events}$id/');
      final response = fullResponse.data;
      return Event.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Event with ID $id not found');
      }
      _handleApiException('Failed to get event with ID $id', e);
    } catch (e) {
      throw Exception('Failed to get event with ID $id: $e');
    }
  }

  /// Creates a new event
  @override
  Future<Event> create(Event event) async {
    _validateEvent(event);

    try {
      final response = await _apiClient.post(ApiConfig.events, event.toJson());
      return Event.fromJson(response.data);
    } on ApiException catch (e) {
      _handleApiException('Failed to create event', e);
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  /// Updates an existing event
  @override
  Future<Event> update(Event event) async {
    if (event.id == null) {
      throw ArgumentError('Cannot update an event without an ID');
    }

    _validateEvent(event);

    try {
      final response = await _apiClient.put(
        '${ApiConfig.events}${event.id}/',
        event.toJson(),
      );
      return Event.fromJson(response.data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Event with ID ${event.id} not found');
      }
      _handleApiException('Failed to update event', e);
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  /// Deletes an event by ID
  @override
  Future<bool> delete(int id) async {
    if (id <= 0) {
      throw ArgumentError('Event ID must be a positive integer');
    }

    try {
      await _apiClient.delete('${ApiConfig.events}$id/');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Event with ID $id not found');
      }
      _handleApiException('Failed to delete event with ID $id', e);
    } catch (e) {
      throw Exception('Failed to delete event with ID $id: $e');
    }
  }

  /// Get events by calendar ID
  Future<List<Event>> getByCalendarId(int calendarId) async {
    if (calendarId <= 0) {
      throw ArgumentError('Calendar ID must be a positive integer');
    }

    try {
      final fullResponse = await _apiClient.get(
        '${ApiConfig.events}?calendar=$calendarId',
      );
      final response = fullResponse.data;
      // Handle paginated response format
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final List<dynamic> results = response['results'];
        return results.map((e) => Event.fromJson(e)).toList();
      } else if (response is List) {
        // Handle direct list response (for backward compatibility)
        return response.map((e) => Event.fromJson(e)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get events for calendar $calendarId', e);
    } catch (e) {
      throw Exception('Failed to get events for calendar $calendarId: $e');
    }
  }

  /// Get events by project ID
  Future<List<Event>> getByProjectId(int projectId) async {
    if (projectId <= 0) {
      throw ArgumentError('Project ID must be a positive integer');
    }

    try {
      final fullResponse = await _apiClient.get(
        '${ApiConfig.events}?project=$projectId',
      );
      final response = fullResponse.data;
      // Handle paginated response format
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final List<dynamic> results = response['results'];
        return results.map((e) => Event.fromJson(e)).toList();
      } else if (response is List) {
        // Handle direct list response (for backward compatibility)
        return response.map((e) => Event.fromJson(e)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get events for project $projectId', e);
    } catch (e) {
      throw Exception('Failed to get events for project $projectId: $e');
    }
  }

  /// Get all events where is_gig is true
  Future<List<Event>> getGigs() async {
    try {
      final fullResponse =
          await _apiClient.get('${ApiConfig.events}?is_gig=true');
      final response = fullResponse.data;
      // Handle paginated response format
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final List<dynamic> results = response['results'];
        return results.map((e) => Event.fromJson(e)).toList();
      } else if (response is List) {
        // Handle direct list response (for backward compatibility)
        return response.map((e) => Event.fromJson(e)).toList();
      } else {
        throw Exception(
          'Unexpected response format: ${response.runtimeType}. Expected paginated results.',
        );
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get gigs', e);
    } catch (e) {
      throw Exception('Failed to get gigs: $e');
    }
  }

  /// Validate event before sending to backend
  void _validateEvent(Event event) {
    if (event.title == null || event.title!.isEmpty) {
      throw ArgumentError('Event title cannot be empty');
    }
    // Add more validation if needed
  }

  /// Handle API exceptions centrally
  Never _handleApiException(String message, ApiException e) {
    final errorMessage = '$message: [${e.statusCode}] ${e.message}';
    throw Exception(errorMessage);
  }

  /// Dispose resources if necessary
  void dispose() {
    // If needed, clean up resources
  }
}
