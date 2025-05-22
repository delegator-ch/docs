// lib/models/message.dart

import 'user.dart';
import 'chat.dart';

class Message {
  final int? id;
  final int user;
  final int chat;
  final String content;
  final DateTime sent;
  final DateTime? edited;
  final User? userDetails;
  final Chat? chatDetails;

  Message({
    this.id,
    required this.user,
    required this.chat,
    required this.content,
    DateTime? sent,
    this.edited,
    this.userDetails,
    this.chatDetails,
  }) : sent = sent ?? DateTime.now();

  /// Create a Message from JSON map
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      user: json['user'],
      chat: json['chat'],
      content: json['content'],
      sent: json['sent'] != null ? DateTime.parse(json['sent']) : null,
      edited: json['edited'] != null ? DateTime.parse(json['edited']) : null,
      userDetails:
          json['user_details'] != null
              ? User.fromJson(json['user_details'])
              : null,
      chatDetails:
          json['chat_details'] != null
              ? Chat.fromJson(json['chat_details'])
              : null,
    );
  }

  /// Convert Message to JSON map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    data['user'] = user;
    data['chat'] = chat;
    data['content'] = content;
    // We don't include 'sent' when creating/updating as it's handled by the backend
    if (edited != null) data['edited'] = edited!.toIso8601String();
    // Don't include user_details and chat_details in the JSON as they're read-only
    return data;
  }

  /// Create a copy of this Message with given fields replaced with new values
  Message copyWith({
    int? id,
    int? user,
    int? chat,
    String? content,
    DateTime? sent,
    DateTime? edited,
    User? userDetails,
    Chat? chatDetails,
  }) {
    return Message(
      id: id ?? this.id,
      user: user ?? this.user,
      chat: chat ?? this.chat,
      content: content ?? this.content,
      sent: sent ?? this.sent,
      edited: edited ?? this.edited,
      userDetails: userDetails ?? this.userDetails,
      chatDetails: chatDetails ?? this.chatDetails,
    );
  }

  @override
  String toString() {
    return 'Message{id: $id, user: $user, chat: $chat, '
        'content: "$content", sent: ${sent.toIso8601String()}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.user == user &&
        other.chat == chat &&
        other.content == content &&
        other.sent == sent &&
        other.edited == edited;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      user.hashCode ^
      chat.hashCode ^
      content.hashCode ^
      sent.hashCode ^
      edited.hashCode;
}
