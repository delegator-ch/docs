// lib/views/chats_page.dart

import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import '../models/chat.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({Key? key}) : super(key: key);

  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  List<Chat> _chats = [];
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadChats),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ServiceRegistry().authService.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create chat screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create chat functionality coming soon'),
            ),
          );
        },
        child: const Icon(Icons.add),
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
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadChats, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No chats yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation by creating a new chat',
              style: Theme.of(context).textTheme.bodyMedium,
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
          return _buildChatTile(chat);
        },
      ),
    );
  }

  Widget _buildChatTile(Chat chat) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getChatTypeColor(chat.chatType),
          child: Icon(_getChatTypeIcon(chat.chatType), color: Colors.white),
        ),
        title: Text(
          chat.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${chat.chatType}'),
            if (chat.organisationDetails != null)
              Text(
                'Organisation: ${chat.organisationDetails!.name ?? 'Unknown'}',
              ),
            Text('Created: ${_formatDate(chat.created)}'),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () {
          // TODO: Navigate to chat detail screen
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Open chat: ${chat.name}')));
        },
      ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
