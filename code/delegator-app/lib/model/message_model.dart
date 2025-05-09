// Create a new file: lib/model/message_model.dart
class Message {
  final int id;
  final int chatId;
  final String content;
  final String created;
  final bool isFromUser;

  Message({
    required this.id,
    required this.chatId,
    required this.content,
    required this.created,
    required this.isFromUser,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      chatId: json['chat_id'],
      content: json['content'],
      created: json['created'],
      isFromUser: json['is_from_user'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'content': content,
      'created': created,
      'is_from_user': isFromUser,
    };
  }
}
