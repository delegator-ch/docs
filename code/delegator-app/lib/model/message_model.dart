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
}
