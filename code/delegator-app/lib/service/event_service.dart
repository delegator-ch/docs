// lib/service/event_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';

class Event {
  final int id;
  final int calendarId;
  final String start;
  final String end;
  final bool isGig;
  final String organisationName;

  Event({
    required this.id,
    required this.calendarId,
    required this.start,
    required this.end,
    required this.isGig,
    required this.organisationName,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      calendarId: json['calendar'],
      start: json['start'],
      end: json['end'],
      isGig: json['is_gig'],
      organisationName:
          json['calendar_details']['organisation_details']['name'],
    );
  }
}

class Project {
  final int id;
  final int? eventId;
  final String? deadline;
  final int priority;
  final int organisationId;
  final String? organisationName;

  Project({
    required this.id,
    this.eventId,
    this.deadline,
    required this.priority,
    required this.organisationId,
    this.organisationName,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // Extract organisation name from event_details if available
    String? orgName;
    if (json['event_details'] != null) {
      orgName =
          json['event_details']['calendar_details']['organisation_details']['name'];
    }

    return Project(
      id: json['id'],
      eventId: json['event'],
      deadline: json['deadline'],
      priority: json['priority'],
      organisationId: json['organisation'],
      organisationName: orgName,
    );
  }
}

class EventService {
  static const String baseUrl = 'http://127.0.0.1';

  // Get headers with authentication token
  Map<String, String> _getAuthHeaders() {
    final token = TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Fetch events
  Future<List<Event>> fetchEvents() async {
    try {
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
        TokenManager.clearToken();
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching events: $e');
      // Return mock data if API call fails
      return _getMockEvents();
    }
  }

  // Fetch projects
  Future<List<Project>> fetchProjects() async {
    try {
      final headers = _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/projects/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> results = data['results'];
        return results.map((json) => Project.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        TokenManager.clearToken();
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching projects: $e');
      // Return mock data if API call fails
      return _getMockProjects();
    }
  }

  // Mock events for demo or when API fails
  List<Event> _getMockEvents() {
    return [
      Event(
        id: 1,
        calendarId: 2,
        start: '12:00:00',
        end: '13:00:00',
        isGig: false,
        organisationName: 'Test Organisation',
      ),
      Event(
        id: 2,
        calendarId: 2,
        start: '14:00:00',
        end: '15:30:00',
        isGig: true,
        organisationName: 'Test Organisation',
      ),
    ];
  }

  // Mock projects for demo or when API fails
  List<Project> _getMockProjects() {
    return [
      Project(
        id: 17,
        eventId: 1,
        deadline: '2025-06-15',
        priority: 2,
        organisationId: 5,
        organisationName: 'Test Organisation',
      ),
      Project(
        id: 15,
        eventId: null,
        deadline: '2025-05-20',
        priority: 1,
        organisationId: 5,
        organisationName: 'Test Organisation',
      ),
      Project(
        id: 14,
        eventId: null,
        deadline: null,
        priority: 0,
        organisationId: 5,
        organisationName: 'Test Organisation',
      ),
      Project(
        id: 16,
        eventId: 2,
        deadline: '2025-07-10',
        priority: 3,
        organisationId: 5,
        organisationName: 'Test Organisation',
      ),
      Project(
        id: 13,
        eventId: null,
        deadline: null,
        priority: 0,
        organisationId: 5,
        organisationName: 'Test Organisation',
      ),
    ];
  }
}
