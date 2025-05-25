// lib/models/user.dart

class User {
  final int? id;
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final bool isPremium;
  final DateTime? created;
  final UserRole? role;
  final DateTime? joinedProject;
  final String? accessType;

  User({
    this.id,
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.isPremium = false,
    this.created,
    this.role,
    this.joinedProject,
    this.accessType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      isPremium: json['is_premium'] ?? false,
      created: json['created'] != null ? DateTime.parse(json['created']) : null,
      role: json['role'] != null ? UserRole.fromJson(json['role']) : null,
      joinedProject: json['joined_project'] != null
          ? DateTime.parse(json['joined_project'])
          : null,
      accessType: json['access_type'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    data['username'] = username;
    if (email != null) data['email'] = email;
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    data['is_premium'] = isPremium;
    if (accessType != null) data['access_type'] = accessType;
    return data;
  }

  String get displayName {
    if (firstName != null &&
        lastName != null &&
        firstName!.isNotEmpty &&
        lastName!.isNotEmpty) {
      return '$firstName $lastName';
    }
    return username;
  }
}

class UserRole {
  final int id;
  final String name;
  final int level;

  UserRole({
    required this.id,
    required this.name,
    required this.level,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'],
      name: json['name'],
      level: json['level'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level,
    };
  }
}
