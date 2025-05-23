// lib/models/project.dart

import '../models/organisation.dart';

class Project {
  final int? id;
  final String? name;
  final int? event;
  final DateTime? deadline;
  final int priority;
  final dynamic eventDetails;
  final int organisationId;
  final int status;
  final Organisation?
      organisation; // Changed from Map<String, dynamic>? to Organisation

  Project({
    this.id,
    required this.name,
    this.event,
    this.deadline,
    this.priority = 0,
    this.eventDetails,
    required this.organisationId,
    this.organisation,
    this.status = 1,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
        id: json['id'],
        name: json['name'],
        event: json['event'],
        deadline:
            json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
        priority: json['priority'] ?? 0,
        eventDetails: json['event_details'],
        organisationId: json['organisation'],
        organisation: null, // Will be set later via withOrganisation
        status: json['status']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (name != null) data['name'] = name;
    if (event != null) data['event'] = event;
    if (deadline != null) data['deadline'] = deadline!.toIso8601String();
    data['priority'] = priority;
    data['event_details'] = eventDetails;
    data['organisation'] = organisationId;
    data['status'] = status;
    return data;
  }

  // Updated to accept an Organisation object directly
  Project withOrganisation(Organisation organisationData) {
    return Project(
      id: id,
      name: name,
      event: event,
      deadline: deadline,
      priority: priority,
      eventDetails: eventDetails,
      organisationId: organisationId,
      organisation: organisationData,
    );
  }
}
