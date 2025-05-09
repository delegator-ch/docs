import 'package:flutter/material.dart';
import '../model/chat_model.dart';
import '../service/chat_service.dart';
import '../service/token_manager.dart';

class PageChat extends StatefulWidget {
  const PageChat({super.key});

  @override
  State<PageChat> createState() => _PageChatState();
}

class _PageChatState extends State<PageChat> {
  final ChatService _chatService = ChatService();
  List<Chat> _chats = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _tokenController = TextEditingController();
  bool _showTokenInput = false;

  @override
  void initState() {
    super.initState();
    _checkTokenAndFetchChats();
  }

  void _checkTokenAndFetchChats() {
    if (TokenManager.hasToken()) {
      _fetchChats();
    } else {
      setState(() {
        _showTokenInput = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchChats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final chats = await _chatService.fetchChats();

      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;

        // If authentication failed, show token input
        if (e.toString().contains('Authentication failed')) {
          _showTokenInput = true;
        }
      });
    }
  }

  void _setTokenAndFetch() {
    if (_tokenController.text.isNotEmpty) {
      _chatService.setToken(_tokenController.text);
      setState(() {
        _showTokenInput = false;
      });
      _fetchChats();
    }
  }

  String _formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  @override
  Widget build(BuildContext context) {
    if (_showTokenInput) {
      return _buildTokenInput();
    }

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchChats,
                child: const Text('Try Again'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showTokenInput = true;
                  });
                },
                child: const Text('Enter New Token'),
              ),
            ],
          ),
        )
        : _chats.isEmpty
        ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('No chats available', style: TextStyle(fontSize: 18)),
            ],
          ),
        )
        : RefreshIndicator(
          onRefresh: _fetchChats,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _chats.length,
            itemBuilder: (context, index) {
              final chat = _chats[index];
              return _buildChatCard(chat);
            },
          ),
        );
  }

  Widget _buildTokenInput() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter JWT Token',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'JWT Token',
                hintText: 'Paste your JWT token here',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _setTokenAndFetch,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCard(Chat chat) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          print('Selected chat: ${chat.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      chat.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ID: ${chat.id}',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    chat.organisationName,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(chat.created),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }
}
