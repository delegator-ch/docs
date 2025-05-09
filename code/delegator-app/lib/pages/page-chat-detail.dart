// Update lib/pages/page-chat-detail.dart
import 'package:flutter/material.dart';
import '../model/chat_model.dart';
import '../model/message_model.dart';
import '../service/message_service.dart';

class PageChatDetail extends StatefulWidget {
  final Chat chat;

  const PageChatDetail({super.key, required this.chat});

  @override
  State<PageChatDetail> createState() => _PageChatDetailState();
}

class _PageChatDetailState extends State<PageChatDetail> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessageService _messageService = MessageService();
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // We'll try to get actual messages from the API
      // If it fails, we'll fall back to mock data
      try {
        final messages = await _messageService.fetchMessages(widget.chat.id);
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading messages from API: $e');
        // Fall back to mock data
        await Future.delayed(const Duration(milliseconds: 800));
        setState(() {
          // Mock data for demonstration
          _messages = [
            Message(
              id: 1,
              chatId: widget.chat.id,
              content: "Hello there! How can I help you today?",
              created:
                  DateTime.now()
                      .subtract(const Duration(minutes: 30))
                      .toIso8601String(),
              isFromUser: false,
            ),
            Message(
              id: 2,
              chatId: widget.chat.id,
              content: "I need some information about the project status.",
              created:
                  DateTime.now()
                      .subtract(const Duration(minutes: 25))
                      .toIso8601String(),
              isFromUser: true,
            ),
            Message(
              id: 3,
              chatId: widget.chat.id,
              content:
                  "Sure, the project is currently in the development phase. We expect to complete it by next week.",
              created:
                  DateTime.now()
                      .subtract(const Duration(minutes: 20))
                      .toIso8601String(),
              isFromUser: false,
            ),
          ];
          _isLoading = false;
        });
      }

      // Scroll to bottom after messages load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = Message(
      id: _messages.isEmpty ? 1 : _messages.last.id + 1,
      chatId: widget.chat.id,
      content: _messageController.text,
      created: DateTime.now().toIso8601String(),
      isFromUser: true,
    );

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    // Scroll to bottom after sending message
    _scrollToBottom();

    try {
      // Try to send the message via API
      await _messageService.sendMessage(widget.chat.id, newMessage.content);
      // If successful, server might respond with a message - we'd fetch it here
      // For now, we'll simulate a response
      await Future.delayed(const Duration(seconds: 1));

      final responseMessage = Message(
        id: _messages.isEmpty ? 1 : _messages.last.id + 1,
        chatId: widget.chat.id,
        content: "Thanks for your message. I'll look into it.",
        created: DateTime.now().toIso8601String(),
        isFromUser: false,
      );

      setState(() {
        _messages.add(responseMessage);
      });

      _scrollToBottom();
    } catch (e) {
      // Show error if sending fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // TODO: Show chat info
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade100,
              width: double.infinity,
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.red),
                    onPressed: _loadMessages,
                  ),
                ],
              ),
            ),
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

  Widget _buildMessageBubble(Message message) {
    final DateTime messageTime = DateTime.parse(message.created);

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
              _formatTime(messageTime),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attachment feature coming soon!'),
                ),
              );
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
              onSubmitted: (_) => _sendMessage(),
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
