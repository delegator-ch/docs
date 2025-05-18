// lib/models/status.dart

class Status {
  final int? id;
  final String name;

  Status({this.id, required this.name});

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    data['name'] = name;
    return data;
  }
}
