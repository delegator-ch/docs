// First, let's create a new file: lib/pages/page-chat-detail.dart
import 'package:flutter/material.dart';
import '../model/chat_model.dart';

class PageChatDetail extends StatefulWidget {
  final Chat chat;

  const PageChatDetail({super.key, required this.chat});

  @override
  State<PageChatDetail> createState() => _PageChatDetailState();
}

class _PageChatDetailState extends State<PageChatDetail> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Implement actual API call to fetch messages
    // For now, we'll add some dummy messages
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _messages.addAll([
        ChatMessage(
          id: 1,
          content: "Hello there! How can I help you today?",
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          isFromUser: false,
        ),
        ChatMessage(
          id: 2,
          content: "I need some information about the project status.",
          timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
          isFromUser: true,
        ),
        ChatMessage(
          id: 3,
          content:
              "Sure, the project is currently in the development phase. We expect to complete it by next week.",
          timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
          isFromUser: false,
        ),
      ]);
      _isLoading = false;
    });

    // Scroll to bottom after messages load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = ChatMessage(
      id: _messages.length + 1,
      content: _messageController.text,
      timestamp: DateTime.now(),
      isFromUser: true,
    );

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    // Scroll to bottom after sending message
    _scrollToBottom();

    // TODO: Implement actual API call to send message
    // Simulate response after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      final responseMessage = ChatMessage(
        id: _messages.length + 1,
        content: "Thanks for your message. I'll look into it.",
        timestamp: DateTime.now(),
        isFromUser: false,
      );

      setState(() {
        _messages.add(responseMessage);
      });

      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chat.name, style: const TextStyle(fontSize: 18)),
            Text(
              widget.chat.organisationName,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? const Center(child: Text("No messages yet"))
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment:
          message.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isFromUser ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: message.isFromUser ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: message.isFromUser ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // TODO: Implement attachment functionality
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// Add this class to represent a chat message
class ChatMessage {
  final int id;
  final String content;
  final DateTime timestamp;
  final bool isFromUser;

  ChatMessage({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.isFromUser,
  });
}
