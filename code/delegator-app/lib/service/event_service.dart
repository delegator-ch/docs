// lib/service/event_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';
import '../model/event_model.dart';

class EventService {
  static const String baseUrl = 'http://10.0.2.2'; // For Android emulator
  // If testing on real device or iOS simulator, you might need to adjust this URL
  // For iOS simulator: http://127.0.0.1
  // For real device: your actual server IP

  // Get headers with authentication token
  Map<String, String> _getAuthHeaders() {
    final token = TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Fetch events with authentication
  Future<List<Event>> fetchEvents() async {
    final headers = _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/events/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> results = data['results'];
      return results.map((json) => Event.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      // Token might be expired
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to load events: ${response.statusCode}');
    }
  }

  // Create a new event
  Future<Event> createEvent({
    required int calendarId,
    required String start,
    required String end,
    required bool isGig,
  }) async {
    final headers = _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/events/'),
      headers: headers,
      body: json.encode({
        'calendar': calendarId,
        'start': start,
        'end': end,
        'is_gig': isGig,
      }),
    );

    if (response.statusCode == 201) {
      return Event.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to create event: ${response.statusCode}');
    }
  }

  // Update an existing event
  Future<Event> updateEvent({
    required int eventId,
    required int calendarId,
    required String start,
    required String end,
    required bool isGig,
  }) async {
    final headers = _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/events/$eventId/'),
      headers: headers,
      body: json.encode({
        'calendar': calendarId,
        'start': start,
        'end': end,
        'is_gig': isGig,
      }),
    );

    if (response.statusCode == 200) {
      return Event.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to update event: ${response.statusCode}');
    }
  }

  // Delete an event
  Future<bool> deleteEvent(int eventId) async {
    final headers = _getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/events/$eventId/'),
      headers: headers,
    );

    if (response.statusCode == 204) {
      return true;
    } else if (response.statusCode == 401) {
      TokenManager.clearToken();
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to delete event: ${response.statusCode}');
    }
  }
}
