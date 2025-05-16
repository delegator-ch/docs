import 'dart:async';
import 'package:flutter/material.dart';
import '../model/chat_model.dart';
import '../model/message_model.dart';
import '../service/message_service.dart';
import '../service/user_service.dart'; // Import the new user service

class PageMessageDetail extends StatefulWidget {
  final Chat chat;

  const PageMessageDetail({super.key, required this.chat});

  @override
  State<PageMessageDetail> createState() => _PageMessageDetailState();
}

class _PageMessageDetailState extends State<PageMessageDetail> {
  final MessageService _messageService = MessageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _isLoading = true;
  String? _error;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    try {
      // Initialize user information if not already done
      if (UserService.currentUser == null) {
        await UserService.initialize();
      }
    } catch (e) {
      print('Error initializing user: $e');
    } finally {
      _fetchMessages();
    }

    // Set up a timer to refresh messages every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _fetchMessages();
      }
    });
  }

  Future<void> _fetchMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final messages = await _messageService.fetchMessagesByChat(
        widget.chat.id,
      );

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // Scroll to bottom after messages are loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    // Create a temporary message ID that won't conflict with real ones
    final tempId = -DateTime.now().millisecondsSinceEpoch;

    // Get current user info for the optimistic message
    final currentUser = UserService.currentUser;
    final now = DateTime.now().toIso8601String();

    // Add a temporary optimistic message
    setState(() {
      _messages.add(
        Message(
          id: tempId, // Temporary ID
          userId: currentUser?.id ?? -1, // Use actual user ID if available
          chatId: widget.chat.id,
          content: content,
          sent: now,
          userDetails: {
            'username':
                currentUser?.username ??
                'me', // Use actual username if available
            'first_name': currentUser?.firstName ?? '',
            'last_name': currentUser?.lastName ?? '',
            'created': currentUser?.created ?? now,
            'profile_image': currentUser?.profileImage,
          },
          chatDetails: {
            'id': widget.chat.id,
            'name': widget.chat.name,
            'organisation_details': {'name': widget.chat.organisationName},
          },
        ),
      );
    });

    // Scroll to bottom to show the new message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      await _messageService.sendMessage(widget.chat.id, content);
      // Refresh messages to get the real message from the server
      _fetchMessages();
    } catch (e) {
      // Remove the optimistic message
      setState(() {
        _messages.removeWhere((msg) => msg.id == tempId);
      });

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: ${e.toString()}')),
        );
      }
    }
  }

  String _formatTime(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMessages,
          ),
        ],
      ),
      body: Column(
        children: [Expanded(child: _buildMessageList()), _buildMessageInput()],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchMessages,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No messages in this chat', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text(
              'Send a message to start the conversation',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group messages by date
    final Map<String, List<Message>> messagesByDate = {};

    for (final message in _messages) {
      final date = _formatDate(message.sent);
      if (!messagesByDate.containsKey(date)) {
        messagesByDate[date] = [];
      }
      messagesByDate[date]!.add(message);
    }

    // Create list with date headers
    final List<Widget> widgets = [];

    messagesByDate.forEach((date, messages) {
      // Add date header
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                date,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );

      // Add messages for this date
      for (final message in messages) {
        widgets.add(_buildMessageBubble(message));
      }
    });

    // Add a loading indicator at the top if refreshing
    if (_isLoading) {
      widgets.insert(
        0,
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    // Add some bottom padding to ensure the last message is visible above the input
    widgets.add(const SizedBox(height: 8));

    return RefreshIndicator(
      onRefresh: _fetchMessages,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: widgets,
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    // Use dynamic user identification instead of hardcoded username
    final isMe = UserService.isCurrentUserMessage(message.userId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile picture - only show for other users
          if (!isMe) _buildProfileImage(message),

          const SizedBox(width: 8),

          // Message content
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Display name - always show, but style differently
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                  child: Text(
                    message.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isMe ? Colors.blue[800] : Colors.grey[800],
                      fontSize: 13,
                    ),
                  ),
                ),

                // Message bubble
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message.content),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.sent),
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Profile picture - only show for current user
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildProfileImage(message),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(Message message) {
    // Check if there's a profile image URL
    final String? profileImageUrl = message.profileImageUrl;

    if (profileImageUrl != null) {
      // Use NetworkImage with error handling
      return ClipOval(
        child: SizedBox(
          width: 40,
          height: 40,
          child: Image.network(
            profileImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // If image loading fails, fall back to letter avatar
              return _buildLetterAvatar(message);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 40,
                height: 40,
                color: Colors.grey[300],
                child: Center(
                  child: CircularProgressIndicator(
                    value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      // Otherwise generate an avatar with the first letter
      return _buildLetterAvatar(message);
    }
  }

  Widget _buildLetterAvatar(Message message) {
    final String displayName = message.displayName;
    final String letter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    // Generate a consistent color based on the username
    final int colorValue = message.username.codeUnits.fold(
      0,
      (prev, element) => prev + element,
    );
    final color = Colors.primaries[colorValue % Colors.primaries.length];

    return CircleAvatar(
      backgroundColor: color,
      radius: 20,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
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
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.send, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
