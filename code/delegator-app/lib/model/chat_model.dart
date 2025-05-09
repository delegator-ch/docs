class Chat {
  final int id;
  final String name;
  final String created;
  final String organisationName;

  Chat({
    required this.id,
    required this.name,
    required this.created,
    required this.organisationName,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      name: json['name'],
      created: json['created'],
      organisationName: json['organisation_details']['name'],
    );
  }
}
