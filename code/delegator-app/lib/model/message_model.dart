class Message {
  final int id;
  final int userId;
  final int chatId;
  final String content;
  final String sent;
  final String? edited;
  final Map<String, dynamic> userDetails;
  final Map<String, dynamic> chatDetails;

  Message({
    required this.id,
    required this.userId,
    required this.chatId,
    required this.content,
    required this.sent,
    this.edited,
    required this.userDetails,
    required this.chatDetails,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      userId: json['user'],
      chatId: json['chat'],
      content: json['content'],
      sent: json['sent'],
      edited: json['edited'],
      userDetails: json['user_details'],
      chatDetails: json['chat_details'],
    );
  }

  String get username => userDetails['username'] as String;
  String get userCreated => userDetails['created'] as String;

  // Get profile image URL if available, otherwise return null
  String? get profileImageUrl {
    if (userDetails.containsKey('profile_image') &&
        userDetails['profile_image'] != null &&
        userDetails['profile_image'].toString().isNotEmpty) {
      return userDetails['profile_image'] as String;
    }
    return null;
  }

  // Get display name (first name + last name if available, otherwise username)
  String get displayName {
    final firstName = userDetails['first_name'] as String? ?? '';
    final lastName = userDetails['last_name'] as String? ?? '';

    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '${firstName.trim()} ${lastName.trim()}'.trim();
    }

    return username;
  }
}
