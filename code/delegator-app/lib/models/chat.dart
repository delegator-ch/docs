// lib/models/chat.dart

import 'organisation.dart';
import 'project.dart';

class Chat {
  final int? id;
  final int organisation;
  final String name;
  final DateTime created;
  final int minRoleLevel;
  final Organisation? organisationDetails;
  final String chatType;

  Chat({
    this.id,
    required this.organisation,
    required this.name,
    DateTime? created,
    required this.minRoleLevel,
    this.organisationDetails,
    required this.chatType,
  }) : created = created ?? DateTime.now();

  /// Create a Chat from JSON map
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      organisation: json['organisation'],
      name: json['name'],
      created: json['created'] != null ? DateTime.parse(json['created']) : null,
      minRoleLevel: json['min_role_level'],
      organisationDetails: json['organisation_details'] != null
          ? Organisation.fromJson(json['organisation_details'])
          : null,
      chatType: json['chat_type'],
    );
  }

  /// Convert Chat to JSON map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    data['organisation'] = organisation;
    data['name'] = name;
    data['min_role_level'] = minRoleLevel;
    data['chat_type'] = chatType;
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
    String? chatType,
  }) {
    return Chat(
      id: id ?? this.id,
      organisation: organisation ?? this.organisation,
      name: name ?? this.name,
      created: created ?? this.created,
      minRoleLevel: minRoleLevel ?? this.minRoleLevel,
      organisationDetails: organisationDetails ?? this.organisationDetails,
      chatType: chatType ?? this.chatType,
    );
  }

  @override
  String toString() {
    return 'Chat{id: $id, name: "$name", organisation: $organisation, '
        'type: $chatType, created: ${created.toIso8601String()}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat &&
        other.id == id &&
        other.organisation == organisation &&
        other.name == name &&
        other.minRoleLevel == minRoleLevel &&
        other.chatType == chatType;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      organisation.hashCode ^
      name.hashCode ^
      minRoleLevel.hashCode ^
      chatType.hashCode;
}
