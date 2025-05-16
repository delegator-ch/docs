// lib/model/task_model.dart
class Task {
  final int id;
  final String title;
  final String? description;
  final bool completed;
  final String? dueDate;
  final int? assignedTo;
  final int? project;
  final String created;

  // Additional fields for UI display
  String? assignedToName;
  String? projectName;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.completed,
    this.dueDate,
    this.assignedTo,
    this.project,
    required this.created,
    this.assignedToName,
    this.projectName,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? 'Untitled Task',
      description: json['description'],
      completed: json['completed'] ?? false,
      dueDate: json['due_date'],
      assignedTo:
          json['assigned_to'] != null
              ? (json['assigned_to'] is int
                  ? json['assigned_to']
                  : int.parse(json['assigned_to'].toString()))
              : null,
      project:
          json['project'] != null
              ? (json['project'] is int
                  ? json['project']
                  : int.parse(json['project'].toString()))
              : null,
      created: json['created'] ?? DateTime.now().toIso8601String(),
      // Names will be filled in by the service
      assignedToName: json['user_details']?['username'] ?? 'Unknown User',
      projectName: json['project_details']?['name'] ?? 'No Project',
    );
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    bool? completed,
    String? dueDate,
    int? assignedTo,
    int? project,
    String? created,
    String? assignedToName,
    String? projectName,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      dueDate: dueDate ?? this.dueDate,
      assignedTo: assignedTo ?? this.assignedTo,
      project: project ?? this.project,
      created: created ?? this.created,
      assignedToName: assignedToName ?? this.assignedToName,
      projectName: projectName ?? this.projectName,
    );
  }
}
