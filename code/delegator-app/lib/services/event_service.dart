// lib/services/event_service.dart

import 'dart:async';
import '../models/event.dart';
import 'base_service.dart';
import 'api_client.dart';
import '../config/api_config.dart';

/// Service for managing Event entities
class EventService implements BaseService<Event> {
  final ApiClient _apiClient;

  EventService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<Event>> getAll() async {
    final response = await _apiClient.get(ApiConfig.events);
    return (response as List).map((json) => Event.fromJson(json)).toList();
  }

  @override
  Future<Event> getById(int id) async {
    final response = await _apiClient.get('${ApiConfig.events}/$id');
    return Event.fromJson(response);
  }

  @override
  Future<Event> create(Event event) async {
    final response = await _apiClient.post(ApiConfig.events, event.toJson());
    return Event.fromJson(response);
  }

  @override
  Future<Event> update(Event event) async {
    if (event.id == null) {
      throw Exception('Cannot update an event without an ID');
    }

    final response = await _apiClient.put(
      '${ApiConfig.events}/${event.id}',
      event.toJson(),
    );
    return Event.fromJson(response);
  }

  @override
  Future<bool> delete(int id) async {
    await _apiClient.delete('${ApiConfig.events}/$id');
    return true;
  }

  /// Get events for a specific calendar
  Future<List<Event>> getByCalendarId(int calendarId) async {
    final response = await _apiClient.get(
      '${ApiConfig.events}?calendar=$calendarId',
    );
    return (response as List).map((json) => Event.fromJson(json)).toList();
  }

  /// Get events between two dates
  Future<List<Event>> getByDateRange(DateTime start, DateTime end) async {
    final formattedStart = start.toIso8601String();
    final formattedEnd = end.toIso8601String();
    final response = await _apiClient.get(
      '${ApiConfig.events}?start_after=$formattedStart&end_before=$formattedEnd',
    );
    return (response as List).map((json) => Event.fromJson(json)).toList();
  }

  /// Get gig events only
  Future<List<Event>> getGigsOnly() async {
    final response = await _apiClient.get('${ApiConfig.events}?is_gig=true');
    return (response as List).map((json) => Event.fromJson(json)).toList();
  }
}
