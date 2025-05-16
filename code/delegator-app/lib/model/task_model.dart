// lib/model/task_model.dart
class Task {
  final int id;
  final String title;
  final String? description;
  final int status; // 1 = Backlog, 2 = In Progress, 3 = Done
  final String? dueDate;
  final int? assignedTo;
  final int? project;
  final String created;
  final int? duration;
  final int? dependentOnTask;
  final int? event;

  // Additional fields for UI display
  String? assignedToName;
  String? projectName;
  String? statusName;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.dueDate,
    this.assignedTo,
    this.project,
    required this.created,
    this.duration,
    this.dependentOnTask,
    this.event,
    this.assignedToName,
    this.projectName,
    this.statusName,
  });

  // Computed property to determine if task is completed
  bool get completed => status == 3;

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? 'Untitled Task',
      description: json['content'], // API uses 'content' for description
      status: json['status'] ?? 1, // Default to Backlog (1) if not provided
      dueDate: json['deadline'], // API uses 'deadline' for dueDate
      assignedTo:
          json['user'] !=
                  null // API uses 'user' for assignedTo
              ? (json['user'] is int
                  ? json['user']
                  : int.parse(json['user'].toString()))
              : null,
      project:
          json['project'] != null
              ? (json['project'] is int
                  ? json['project']
                  : int.parse(json['project'].toString()))
              : null,
      created: json['created'] ?? DateTime.now().toIso8601String(),
      duration: json['duration'],
      dependentOnTask: json['dependent_on_task'],
      event: json['event'],
      // Names will be filled in by the service
      assignedToName: json['user_details']?['username'] ?? 'Unknown User',
      projectName: _extractProjectName(json),
      statusName: json['status_details']?['name'],
    );
  }

  // Helper method to extract project name from API response
  static String _extractProjectName(Map<String, dynamic> json) {
    if (json.containsKey('project_details')) {
      final projectDetails = json['project_details'];
      // Return default name based on project ID since the API doesn't provide a name
      return 'Project #${projectDetails['id']}';
    }
    return 'No Project';
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    int? status,
    bool? completed,
    String? dueDate,
    int? assignedTo,
    int? project,
    String? created,
    int? duration,
    int? dependentOnTask,
    int? event,
    String? assignedToName,
    String? projectName,
    String? statusName,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? (completed != null ? (completed ? 3 : 1) : this.status),
      dueDate: dueDate ?? this.dueDate,
      assignedTo: assignedTo ?? this.assignedTo,
      project: project ?? this.project,
      created: created ?? this.created,
      duration: duration ?? this.duration,
      dependentOnTask: dependentOnTask ?? this.dependentOnTask,
      event: event ?? this.event,
      assignedToName: assignedToName ?? this.assignedToName,
      projectName: projectName ?? this.projectName,
      statusName: statusName ?? this.statusName,
    );
  }
}
