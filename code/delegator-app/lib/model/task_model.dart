// lib/model/task_model.dart
class Task {
  final int id;
  final String title;
  final String? content; // Renamed from description to match API
  final int status; // 1 = Backlog, 2 = In Progress, 3 = Done
  final int project;
  final String? deadline; // Renamed from dueDate to match API
  final int? user; // Renamed from assignedTo to match API
  final String created;
  final int? duration;
  final int? dependentOnTask;
  final int? event;

  // Additional fields for UI display
  String? userName; // Renamed from assignedToName
  String? projectName;
  String? statusName;

  Task({
    required this.id,
    required this.title,
    this.content,
    required this.status,
    this.deadline,
    this.user,
    required this.project,
    required this.created,
    this.duration,
    this.dependentOnTask,
    this.event,
    this.userName,
    this.projectName,
    this.statusName,
  });

  // Factory constructor for creating a new task with temporary id
  // This is used when creating a task before it's saved to the backend
  factory Task.forCreation({
    required String title,
    String? content,
    int status = 1,
    String? deadline,
    int? user,
    required int project,
    int? duration,
    int? dependentOnTask,
    int? event,
  }) {
    return Task(
      id: -1, // Temporary ID that will be replaced by the server
      title: title,
      content: content,
      status: status,
      deadline: deadline,
      user: user,
      project: project,
      created: DateTime.now().toIso8601String(),
      duration: duration,
      dependentOnTask: dependentOnTask,
      event: event,
    );
  }

  // Computed property to determine if task is completed
  bool get completed => status == 3;

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? 'Untitled Task',
      content: json['content'], // API uses 'content'
      status: json['status'] ?? 1, // Default to Backlog (1) if not provided
      deadline: json['deadline'], // API uses 'deadline'
      user:
          json['user'] !=
                  null // API uses 'user'
              ? (json['user'] is int
                  ? json['user']
                  : int.parse(json['user'].toString()))
              : null,
      project:
          json['project'] != null
              ? (json['project'] is int
                  ? json['project']
                  : int.parse(json['project'].toString()))
              : -1, // Default to -1 if no project is provided
      created: json['created'] ?? DateTime.now().toIso8601String(),
      duration: json['duration'],
      dependentOnTask: json['dependent_on_task'],
      event: json['event'],
      // Names will be filled in by the service
      userName: json['user_details']?['username'] ?? 'Unknown User',
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
    String? content,
    int? status,
    bool? completed,
    String? deadline,
    int? user,
    int? project,
    String? created,
    int? duration,
    int? dependentOnTask,
    int? event,
    String? userName,
    String? projectName,
    String? statusName,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      status: status ?? (completed != null ? (completed ? 3 : 1) : this.status),
      deadline: deadline ?? this.deadline,
      user: user ?? this.user,
      project: project ?? this.project,
      created: created ?? this.created,
      duration: duration ?? this.duration,
      dependentOnTask: dependentOnTask ?? this.dependentOnTask,
      event: event ?? this.event,
      userName: userName ?? this.userName,
      projectName: projectName ?? this.projectName,
      statusName: statusName ?? this.statusName,
    );
  }
}
