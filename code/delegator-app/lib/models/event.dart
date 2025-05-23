// lib/models/event.dart

class Event {
  final int? id;
  final String? title; // Made optional to match current test usage
  final int calender; // Changed to int to match Calendar ID type
  final DateTime start;
  final DateTime end;
  final bool isGig;

  // Constructor that matches how you're using it in tests
  Event({
    this.id,
    this.title, // Made optional
    required this.calender,
    required this.start,
    required this.end,
    this.isGig = false,
  }) {
    validate(); // Validate on construction
  }

  /// Create an Event from JSON map
  factory Event.fromJson(Map<String, dynamic> json) {
    try {
      // Only validate required fields that we actually need
      if (!json.containsKey('start') || json['start'] == null) {
        throw const FormatException('Missing required field: start');
      }
      if (!json.containsKey('end') || json['end'] == null) {
        throw const FormatException('Missing required field: end');
      }

      // Handle calendar ID correctly - may be in 'calendar' or 'calendar_id'
      int eventCalendarId;
      if (json.containsKey('calendar_id')) {
        eventCalendarId = int.parse(json['calendar_id'].toString());
      } else if (json.containsKey('calendar') &&
          json['calendar'] is Map &&
          json['calendar'].containsKey('id')) {
        eventCalendarId = int.parse(json['calendar']['id'].toString());
      } else if (json.containsKey('calendar')) {
        eventCalendarId = int.parse(json['calendar'].toString());
      } else {
        throw const FormatException(
          'Missing required field: calendar/calendar_id',
        );
      }

      return Event(
        id: json['id'] != null ? int.parse(json['id'].toString()) : null,
        title: json['title'] as String?,
        calender: eventCalendarId,
        start: DateTime.parse(json['start'] as String),
        end: DateTime.parse(json['end'] as String),
        isGig: json['is_gig'] as bool? ?? false,
      );
    } catch (e) {
      if (e is FormatException) {
        rethrow; // Let specific format exceptions bubble up
      }
      throw FormatException('Failed to parse Event: ${e.toString()}');
    }
  }

  /// Convert Event to JSON map
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      'calendar': calender,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'is_gig': isGig,
    };
  }

  /// Create a copy of this Event with given fields replaced with new values
  Event copyWith({
    int? id,
    String? title,
    int? calendarId,
    DateTime? start,
    DateTime? end,
    bool? isGig,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      calender: calendarId ?? this.calender,
      start: start ?? this.start,
      end: end ?? this.end,
      isGig: isGig ?? this.isGig,
    );
  }

  @override
  String toString() {
    return 'Event{id: $id, title: "$title", calendarId: $calender, '
        'start: ${start.toIso8601String()}, end: ${end.toIso8601String()}, '
        'isGig: $isGig}';
  }

  /// Validate that the event data is correct
  void validate() {
    // Title can be null or empty in this version

    if (end.isBefore(start)) {
      throw ArgumentError('Event end time cannot be before start time');
    }

    // Duration validation - optional
    final duration = end.difference(start);
    if (duration.inMinutes < 1) {
      throw ArgumentError('Event must be at least 1 minute long');
    }
  }

  /// Duration of the event
  Duration get duration => end.difference(start);

  /// Determine if this event overlaps with another event
  bool overlaps(Event other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }

  /// Check if event is currently ongoing
  bool isOngoing() {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event &&
        other.id == id &&
        other.title == title &&
        other.calender == calender &&
        other.start == start &&
        other.end == end &&
        other.isGig == isGig;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      calender.hashCode ^
      start.hashCode ^
      end.hashCode ^
      isGig.hashCode;
}
