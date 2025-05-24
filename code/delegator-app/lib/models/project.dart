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
  final int? chat;

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
    this.chat,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing Project - raw json: $json');

      final id = json['id'];
      print('Parsed id: $id');

      final name = json['name'];
      print('Parsed name: $name');

      final event = json['event'];
      print('Parsed event: $event');

      final deadline =
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null;
      print('Parsed deadline: $deadline');

      final priority = json['priority'] ?? 0;
      print('Parsed priority: $priority');

      final eventDetails = json['event_details'];
      print('Parsed eventDetails: $eventDetails');

      final organisationId = json['organisation'];
      print('Parsed organisationId: $organisationId');

      final status = json['status'];
      print('Parsed status: $status');

      final chat = json['chat'];
      print('Parsed chat: $chat');

      return Project(
          id: id,
          name: name,
          event: event,
          deadline: deadline,
          priority: priority,
          eventDetails: eventDetails,
          organisationId: organisationId,
          organisation: null,
          status: status,
          chat: chat);
    } catch (e, stackTrace) {
      print('Project.fromJson error2: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
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
    data['chat'] = chat;
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
