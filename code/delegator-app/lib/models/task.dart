// lib/models/task.dart

import 'user.dart';
import 'project.dart';
import 'status.dart';
import 'event.dart';

class Task {
  final int? id;
  final User user;
  final Project project;
  final String title;
  final String? content;
  final int duration;
  final Status status;
  final DateTime? created;
  final DateTime? updated;
  final DateTime? deadline;
  final int? dependentOnTaskId;
  final Event? event;

  Task({
    this.id,
    required this.user,
    required this.project,
    required this.title,
    this.content,
    this.duration = 0,
    required this.status,
    this.created,
    this.updated,
    this.deadline,
    this.dependentOnTaskId,
    this.event,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      user: User.fromJson(json['user']),
      project: Project.fromJson(json['project']),
      title: json['title'],
      content: json['content'],
      duration: json['duration'] ?? 0,
      status: Status.fromJson(json['status']),
      created: json['created'] != null ? DateTime.parse(json['created']) : null,
      updated: json['updated'] != null ? DateTime.parse(json['updated']) : null,
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      dependentOnTaskId: json['dependent_on_task'],
      event: json['event'] != null ? Event.fromJson(json['event']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    data['user'] = user.toJson();
    data['project'] = project.toJson();
    data['title'] = title;
    if (content != null) data['content'] = content;
    data['duration'] = duration;
    data['status'] = status.toJson();
    if (deadline != null) data['deadline'] = deadline!.toIso8601String();
    if (dependentOnTaskId != null)
      data['dependent_on_task'] = dependentOnTaskId;
    if (event != null) data['event'] = event!.toJson();
    return data;
  }
}
