// lib/services/calendar_service.dart

import '../models/calendar.dart';
import '../services/api_client.dart';

class CalendarService {
  final ApiClient _apiClient;

  CalendarService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches all calendars from the backend
  Future<List<Calendar>> getAll() async {
    final response = await _apiClient.get('/calendars/');

    // Check response type and extract the list of calendars
    if (response is Map<String, dynamic>) {
      // Try to find the list of calendars in common fields
      if (response.containsKey('results')) {
        final List<dynamic> calendarsJson = response['results'];
        return calendarsJson.map((json) => Calendar.fromJson(json)).toList();
      } else if (response.containsKey('data')) {
        final List<dynamic> calendarsJson = response['data'];
        return calendarsJson.map((json) => Calendar.fromJson(json)).toList();
      } else if (response.containsKey('calendars')) {
        final List<dynamic> calendarsJson = response['calendars'];
        return calendarsJson.map((json) => Calendar.fromJson(json)).toList();
      } else {
        // Log the structure for debugging
        print('Unexpected response structure: $response');
        throw Exception(
          'Unexpected API response structure. Could not find calendars list.',
        );
      }
    } else if (response is List) {
      // If it's already a list, use it directly
      return response.map((json) => Calendar.fromJson(json)).toList();
    } else {
      // Fallback error
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }
  }

  /// Fetches calendars for a specific organisation
  Future<List<Calendar>> getByOrganisationId(int organisationId) async {
    final response = await _apiClient.get(
      '/calendars/?organisation=$organisationId',
    );

    // Handle different response formats
    if (response is Map<String, dynamic>) {
      if (response.containsKey('results')) {
        final List<dynamic> calendarsJson = response['results'];
        return calendarsJson.map((json) => Calendar.fromJson(json)).toList();
      } else if (response.containsKey('data')) {
        final List<dynamic> calendarsJson = response['data'];
        return calendarsJson.map((json) => Calendar.fromJson(json)).toList();
      } else {
        print('Unexpected response structure: $response');
        throw Exception(
          'Unexpected API response structure. Could not find calendars list.',
        );
      }
    } else if (response is List) {
      return response.map((json) => Calendar.fromJson(json)).toList();
    } else {
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }
  }

  /// Fetches calendars for a specific user
  Future<List<Calendar>> getByUserId(int userId) async {
    final response = await _apiClient.get('/calendars/?user=$userId');

    // Handle different response formats
    if (response is Map<String, dynamic>) {
      if (response.containsKey('results')) {
        final List<dynamic> calendarsJson = response['results'];
        return calendarsJson.map((json) => Calendar.fromJson(json)).toList();
      } else if (response.containsKey('data')) {
        final List<dynamic> calendarsJson = response['data'];
        return calendarsJson.map((json) => Calendar.fromJson(json)).toList();
      } else {
        print('Unexpected response structure: $response');
        throw Exception(
          'Unexpected API response structure. Could not find calendars list.',
        );
      }
    } else if (response is List) {
      return response.map((json) => Calendar.fromJson(json)).toList();
    } else {
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }
  }

  /// Fetches a single calendar by ID
  Future<Calendar> getById(int id) async {
    final response = await _apiClient.get('/calendars/$id/');
    return Calendar.fromJson(response);
  }

  /// Creates a new calendar
  Future<Calendar> create(Calendar calendar) async {
    final response = await _apiClient.post('/calendars/', calendar.toJson());
    return Calendar.fromJson(response);
  }

  /// Updates an existing calendar
  Future<Calendar> update(Calendar calendar) async {
    if (calendar.id == null) {
      throw ArgumentError('Cannot update calendar without an ID');
    }

    final response = await _apiClient.put(
      '/calendars/${calendar.id}/',
      calendar.toJson(),
    );
    return Calendar.fromJson(response);
  }

  /// Deletes a calendar
  Future<bool> delete(int id) async {
    await _apiClient.delete('/calendars/$id/');
    return true;
  }

  /// Gets the iCal URL for a calendar
  Future<String> getICalUrl(int id) async {
    final response = await _apiClient.get('/calendars/$id/ical-url/');
    final Map<String, dynamic> data = response;
    return data['url'] ?? '';
  }
}
