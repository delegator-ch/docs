// lib/models/user.dart

class User {
  final int? id;
  final String username;
  final String? email;
  final bool isPremium;
  final DateTime? created;

  User({
    this.id,
    required this.username,
    this.email,
    this.isPremium = false,
    this.created,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      isPremium: json['is_premium'] ?? false,
      created: json['created'] != null ? DateTime.parse(json['created']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    data['username'] = username;
    if (email != null) data['email'] = email;
    data['is_premium'] = isPremium;
    return data;
  }
}
