// Updated project_model.dart with better error handling
class Project {
  final int id;
  final int? event;
  final String? deadline;
  final int priority;
  final dynamic
  eventDetails; // Using dynamic as the type isn't clear from the response
  final int organisation;

  // Optional fields for UI display
  String? name; // We'll need to fetch this separately or set a default
  String? organisationName; // We'll need to fetch this separately

  Project({
    required this.id,
    this.event,
    this.deadline,
    required this.priority,
    this.eventDetails,
    required this.organisation,
    this.name,
    this.organisationName,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // Add safety checks for each field
    int id;
    try {
      id = json['id'] is int ? json['id'] : int.parse(json['id'].toString());
    } catch (e) {
      print('Error parsing project ID: $e');
      id = -1; // Fallback value
    }

    int? event;
    if (json['event'] != null) {
      try {
        event =
            json['event'] is int
                ? json['event']
                : int.parse(json['event'].toString());
      } catch (e) {
        print('Error parsing event ID: $e');
        event = null;
      }
    }

    int priority;
    try {
      priority =
          json['priority'] is int
              ? json['priority']
              : (json['priority'] != null
                  ? int.parse(json['priority'].toString())
                  : 0);
    } catch (e) {
      print('Error parsing priority: $e');
      priority = 0; // Default priority
    }

    int organisation;
    try {
      organisation =
          json['organisation'] is int
              ? json['organisation']
              : int.parse(json['organisation'].toString());
    } catch (e) {
      print('Error parsing organisation: $e');
      organisation = 5; // Default organisation
    }

    return Project(
      id: id,
      event: event,
      deadline: json['deadline'] as String?,
      priority: priority,
      eventDetails: json['event_details'],
      organisation: organisation,
      // Set default name since it's not in the API
      name: "Project #$id",
      // Organisation name will need to be set separately
      organisationName: "Organisation #$organisation",
    );
  }

  // Add a clone method to create a copy with possibly modified fields
  Project copyWith({
    int? id,
    int? event,
    String? deadline,
    int? priority,
    dynamic eventDetails,
    int? organisation,
    String? name,
    String? organisationName,
  }) {
    return Project(
      id: id ?? this.id,
      event: event ?? this.event,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      eventDetails: eventDetails ?? this.eventDetails,
      organisation: organisation ?? this.organisation,
      name: name ?? this.name,
      organisationName: organisationName ?? this.organisationName,
    );
  }
}
