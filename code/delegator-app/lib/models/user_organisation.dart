// lib/models/user_organisation.dart

import 'user.dart';
import 'organisation.dart';

class UserOrganisation {
  final int? id;
  final int user;
  final int organisation;
  final int role;
  final User? userDetails;
  final Organisation? organisationDetails;
  final UserRole? roleDetails;

  UserOrganisation({
    this.id,
    required this.user,
    required this.organisation,
    required this.role,
    this.userDetails,
    this.organisationDetails,
    this.roleDetails,
  });

  factory UserOrganisation.fromJson(Map<String, dynamic> json) {
    return UserOrganisation(
      id: json['id'],
      user: json['user'],
      organisation: json['organisation'],
      role: json['role'],
      userDetails: json['user_details'] != null
          ? User.fromJson(json['user_details'])
          : null,
      organisationDetails: json['organisation_details'] != null
          ? Organisation.fromJson(json['organisation_details'])
          : null,
      roleDetails: json['role_details'] != null
          ? UserRole.fromJson(json['role_details'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    data['user'] = user;
    data['organisation'] = organisation;
    data['role'] = role;
    return data;
  }

  UserOrganisation copyWith({
    int? id,
    int? user,
    int? organisation,
    int? role,
    User? userDetails,
    Organisation? organisationDetails,
    UserRole? roleDetails,
  }) {
    return UserOrganisation(
      id: id ?? this.id,
      user: user ?? this.user,
      organisation: organisation ?? this.organisation,
      role: role ?? this.role,
      userDetails: userDetails ?? this.userDetails,
      organisationDetails: organisationDetails ?? this.organisationDetails,
      roleDetails: roleDetails ?? this.roleDetails,
    );
  }

  @override
  String toString() {
    return 'UserOrganisation{id: $id, user: $user, organisation: $organisation, role: $role}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserOrganisation &&
        other.id == id &&
        other.user == user &&
        other.organisation == organisation &&
        other.role == role;
  }

  @override
  int get hashCode =>
      id.hashCode ^ user.hashCode ^ organisation.hashCode ^ role.hashCode;
}
