// lib/models/event.dart

import 'calendar.dart';

class Event {
  final int? id;
  final Calendar calendar;
  final DateTime start;
  final DateTime end;
  final bool isGig;

  Event({
    this.id,
    required this.calendar,
    required this.start,
    required this.end,
    this.isGig = false,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      calendar: Calendar.fromJson(json['calendar']),
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      isGig: json['is_gig'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    data['calendar'] = calendar.toJson();
    data['start'] = start.toIso8601String();
    data['end'] = end.toIso8601String();
    data['is_gig'] = isGig;
    return data;
  }
}
