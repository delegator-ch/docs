// lib/models/chat.dart

import 'organisation.dart';
import 'project.dart';

class Chat {
  final int? id;
  final int? project;
  final int organisation;
  final String name;
  final DateTime created;
  final int minRoleLevel;
  final Project? projectDetails;
  final Organisation? organisationDetails;

  /// Automatically determines chat type based on project_details
  bool get isOrgChat => project == null ? true : false;
  String get chatType => isOrgChat ? 'Organisation' : 'Project';

  Chat({
    this.id,
    this.project,
    required this.organisation,
    required this.name,
    DateTime? created,
    required this.minRoleLevel,
    this.projectDetails,
    this.organisationDetails,
  }) : created = created ?? DateTime.now();

  /// Create a Chat from JSON map
  factory Chat.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing Chat - raw json: $json');

      final id = json['id'];
      print('Parsed id: $id');

      final project = json['project'];
      print('Parsed project: $project');

      final organisation = json['organisation'];
      print('Parsed organisation: $organisation');

      final name = json['name'];
      print('Parsed name: $name');

      final created =
          json['created'] != null ? DateTime.parse(json['created']) : null;
      print('Parsed created: $created');

      final minRoleLevel = json['min_role_level'];
      print('Parsed minRoleLevel: $minRoleLevel');

      final projectDetails = json['project_details'] != null
          ? Project.fromJson(json['project_details'])
          : null;
      print('Parsed projectDetails: $projectDetails');

      final organisationDetails = json['organisation_details'] != null
          ? Organisation.fromJson(json['organisation_details'])
          : null;
      print('Parsed organisationDetails: $organisationDetails');

      return Chat(
        id: id,
        project: project,
        organisation: organisation,
        name: name,
        created: created,
        minRoleLevel: minRoleLevel,
        projectDetails: projectDetails,
        organisationDetails: organisationDetails,
      );
    } catch (e, stackTrace) {
      print('Chat.fromJson error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Convert Chat to JSON map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (project != null) data['project'] = project;
    data['organisation'] = organisation;
    data['name'] = name;
    data['min_role_level'] = minRoleLevel;
    return data;
  }

  /// Create a copy of this Chat with given fields replaced with new values
  Chat copyWith({
    int? id,
    int? project,
    int? organisation,
    String? name,
    DateTime? created,
    int? minRoleLevel,
    Project? projectDetails,
    Organisation? organisationDetails,
  }) {
    return Chat(
      id: id ?? this.id,
      project: project ?? this.project,
      organisation: organisation ?? this.organisation,
      name: name ?? this.name,
      created: created ?? this.created,
      minRoleLevel: minRoleLevel ?? this.minRoleLevel,
      projectDetails: projectDetails ?? this.projectDetails,
      organisationDetails: organisationDetails ?? this.organisationDetails,
    );
  }

  @override
  String toString() {
    return 'Chat{id: $id, name: "$name", organisation: $organisation, '
        'created: ${created.toIso8601String()}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat &&
        other.id == id &&
        other.project == project &&
        other.organisation == organisation &&
        other.name == name &&
        other.minRoleLevel == minRoleLevel;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      project.hashCode ^
      organisation.hashCode ^
      name.hashCode ^
      minRoleLevel.hashCode;
}
