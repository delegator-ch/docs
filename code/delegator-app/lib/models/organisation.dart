// lib/models/organisation.dart

class Organisation {
  final int id;
  final String? name;
  final DateTime? since;

  Organisation({required this.id, this.name, this.since});

  factory Organisation.fromJson(Map<String, dynamic> json) {
    return Organisation(
      id: json['id'],
      name: json['name'],
      since: json['since'] != null ? DateTime.parse(json['since']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    if (since != null) data['since'] = since!.toIso8601String();
    return data;
  }
}
