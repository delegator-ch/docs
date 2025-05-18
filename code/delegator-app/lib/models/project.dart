// lib/models/project.dart

import 'organisation.dart';

class Project {
  final int? id;
  final int? event;
  final DateTime? deadline;
  final int priority;
  final dynamic eventDetails;
  final int organisationId; // ID for direct API use
  final Organisation? organisation; // Full object for UI display (optional)

  Project({
    this.id,
    this.event,
    this.deadline,
    this.priority = 0,
    this.eventDetails,
    required this.organisationId,
    this.organisation,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      event: json['event'],
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      priority: json['priority'] ?? 0,
      eventDetails: json['event_details'],
      organisationId: json['organisation'],
      // The full organisation object is not provided by the API
      organisation: null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (event != null) data['event'] = event;
    if (deadline != null) data['deadline'] = deadline!.toIso8601String();
    data['priority'] = priority;
    data['event_details'] = eventDetails;
    data['organisation'] = organisationId;
    return data;
  }

  /// Create a copy of this project with the full organisation details
  Project withOrganisation(Organisation organisation) {
    return Project(
      id: id,
      event: event,
      deadline: deadline,
      priority: priority,
      eventDetails: eventDetails,
      organisationId: organisationId,
      organisation: organisation,
    );
  }
}
