// lib/models/task.dart

import 'user.dart';
import 'project.dart';
import 'status.dart';
import 'event.dart';

class Task {
  final int? id;
  final int? user;
  final int project;
  final String title;
  final String? content;
  final int duration;
  final int status;
  final DateTime? created;
  final DateTime? updated;
  final DateTime? deadline;
  final int? dependentOnTaskId;
  final int? event;

  Task({
    this.id,
    this.user,
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
      project: json['project'],
      title: json['title'],
      content: json['content'],
      duration: json['duration'] ?? 0,
      status: json['status'],
      created: json['created'] != null ? DateTime.parse(json['created']) : null,
      updated: json['updated'] != null ? DateTime.parse(json['updated']) : null,
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      dependentOnTaskId: json['dependent_on_task'],
      event: json['event'] != null ? json['event'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (user != null) data['user'] = user;
    data['project'] = project;
    data['title'] = title;
    if (content != null) data['content'] = content;
    data['duration'] = duration;
    data['status'] = status;
    if (deadline != null) data['deadline'] = deadline!.toIso8601String();
    if (dependentOnTaskId != null)
      data['dependent_on_task'] = dependentOnTaskId;
    if (event != null) data['event'] = event!;
    return data;
  }
}
