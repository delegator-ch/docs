// views/chats_page.dart

import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'chat_detail_page.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({Key? key}) : super(key: key);

  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  List<Chat> _chats = [];
  Map<int, Message?> _lastMessages = {};
  Map<int, int> _unreadCounts = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final chats = await ServiceRegistry().chatService.getAll();
      setState(() {
        _chats = chats;
      });

      // Load last messages for each chat
      await _loadLastMessages();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLastMessages() async {
    for (final chat in _chats) {
      if (chat.id != null) {
        try {
          final messages = await ServiceRegistry().messageService.getByChatId(
            chat.id!,
          );
          if (messages.isNotEmpty) {
            _lastMessages[chat.id!] = messages.last;
            // For demo purposes, set random unread counts
            _unreadCounts[chat.id!] = (chat.id! % 3 == 0) ? chat.id! % 5 : 0;
          }
        } catch (e) {
          print('Error loading messages for chat ${chat.id}: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadChats),
          PopupMenuButton<String>(
            onSelected: (value) {
              // TODO: Handle menu actions
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'new_group',
                    child: Text('New Group'),
                  ),
                  const PopupMenuItem(
                    value: 'new_broadcast',
                    child: Text('New Broadcast'),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Text('Settings'),
                  ),
                ],
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement new chat functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New chat functionality coming soon!'),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading chats',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_errorMessage!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadChats, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_chats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No chats yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Start a conversation with someone!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      child: ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return ChatListTile(
            chat: chat,
            lastMessage: _lastMessages[chat.id],
            unreadCount: _unreadCounts[chat.id] ?? 0,
            onTap: () => _openChat(chat),
          );
        },
      ),
    );
  }

  void _openChat(Chat chat) {
    if (chat.id != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => ChatDetailPage(
                chatId: chat.id!,
                chatName: chat.name,
                avatarUrl: null, // You can add avatar support later
              ),
        ),
      );
    }
  }
}

class ChatListTile extends StatelessWidget {
  final Chat chat;
  final Message? lastMessage;
  final int unreadCount;
  final VoidCallback onTap;

  const ChatListTile({
    Key? key,
    required this.chat,
    this.lastMessage,
    required this.unreadCount,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: _getChatTypeColor(chat.chatType),
        child: Icon(_getChatTypeIcon(chat.chatType), color: Colors.white),
      ),
      title: Text(
        chat.name,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        lastMessage?.content ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTimestamp(lastMessage?.sent ?? chat.created),
            style: TextStyle(
              fontSize: 12,
              color: unreadCount > 0 ? Colors.blue : Colors.grey[600],
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  Color _getChatTypeColor(String chatType) {
    switch (chatType.toLowerCase()) {
      case 'organisation':
        return Colors.blue;
      case 'project':
        return Colors.green;
      case 'direct':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getChatTypeIcon(String chatType) {
    switch (chatType.toLowerCase()) {
      case 'organisation':
        return Icons.business;
      case 'project':
        return Icons.work;
      case 'direct':
        return Icons.person;
      default:
        return Icons.chat;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${timestamp.day}/${timestamp.month}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }
}
