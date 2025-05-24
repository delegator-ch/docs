// lib/views/chat_info_page.dart

import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';

class ChatInfoPage extends StatefulWidget {
  final int chatId;
  final String chatName;

  const ChatInfoPage({
    Key? key,
    required this.chatId,
    required this.chatName,
  }) : super(key: key);

  @override
  _ChatInfoPageState createState() => _ChatInfoPageState();
}

class _ChatInfoPageState extends State<ChatInfoPage> {
  Chat? _chat;
  List<Message> _messages = [];
  List<User> _participants = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChatInfo();
  }

  Future<void> _loadChatInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load chat details
      final chat = await ServiceRegistry().chatService.getById(widget.chatId);

      // Load messages to get participant information
      final messages =
          await ServiceRegistry().messageService.getByChatId(widget.chatId);

      // Get unique participants from messages
      final participantIds = messages.map((m) => m.user).toSet().toList();

      // For this demo, we'll create mock participants since we don't have a user service
      // In a real app, you'd fetch user details for each participant ID
      final participants = participantIds
          .map((id) => User(
                id: id,
                username: 'User $id',
                email: 'user$id@example.com',
              ))
          .toList();

      setState(() {
        _chat = chat;
        _messages = messages;
        _participants = participants;
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
        title: Text('Chat Info'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit chat functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit chat coming soon!')),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
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
              'Error loading chat info',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChatInfo,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildChatHeader(),
          _buildContextSection(),
          _buildChatDetails(),
          _buildParticipantsSection(),
          _buildMediaSection(),
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: _getChatTypeColor(_chat?.chatType ?? ''),
            child: Icon(
              _getChatTypeIcon(_chat?.chatType ?? ''),
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.chatName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _chat?.chatType.toUpperCase() ?? 'UNKNOWN',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextSection() {
    if (_chat == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _chat!.project != null ? Icons.work : Icons.business,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Context',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Organization context
          if (_chat!.organisationDetails != null)
            _buildContextTile(
              'This chat is part of your organisation',
              _chat!.organisationDetails!.name ?? 'Unknown Organisation',
              Icons.business,
              Colors.blue,
              () => _navigateToOrganisation(_chat!.organisation),
            ),

          // Project context (if this chat belongs to a project)
          if (_chat!.project != null && _chat!.projectDetails != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildContextTile(
                'This chat is part of project',
                _chat!.projectDetails!.name ?? 'Unknown Project',
                Icons.work,
                Colors.green,
                () => _navigateToProject(_chat!.project!),
              ),
            ),

          // Fallback if we don't have detailed organization info
          if (_chat!.organisationDetails == null && _chat!.project == null)
            _buildContextTile(
              'This chat is part of organisation',
              'Organisation #${_chat!.organisation}',
              Icons.business,
              Colors.blue,
              () => _navigateToOrganisation(_chat!.organisation),
            ),
        ],
      ),
    );
  }

  Widget _buildContextTile(
    String description,
    String name,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chat Details',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Chat ID', _chat?.id?.toString() ?? 'Unknown'),
          _buildDetailRow('Type', _chat?.chatType ?? 'Unknown'),
          _buildDetailRow(
              'Organisation', _chat?.organisation?.toString() ?? 'Unknown'),
          _buildDetailRow('Project', _chat?.project?.toString() ?? 'None'),
          _buildDetailRow(
              'Min Role Level', _chat?.minRoleLevel?.toString() ?? 'Unknown'),
          _buildDetailRow('Created', _formatDate(_chat?.created)),
          _buildDetailRow('Total Messages', _messages.length.toString()),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Participants (${_participants.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement add participant functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Add participant coming soon!')),
                  );
                },
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...(_participants
              .map((participant) => _buildParticipantTile(participant))),
        ],
      ),
    );
  }

  Widget _buildParticipantTile(User participant) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.blue[100],
        child: Text(
          participant.username.isNotEmpty
              ? participant.username[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
      ),
      title: Text(participant.username),
      subtitle: participant.email != null ? Text(participant.email!) : null,
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          // TODO: Handle participant actions
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$value for ${participant.username}')),
          );
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'view_profile',
            child: Text('View Profile'),
          ),
          const PopupMenuItem(
            value: 'remove',
            child: Text('Remove from Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Media & Files',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMediaCard('Photos', Icons.photo, 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMediaCard('Videos', Icons.videocam, 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMediaCard('Files', Icons.attach_file, 0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(String title, IconData icon, int count) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            'Mute Notifications',
            Icons.notifications_off,
            () {
              // TODO: Implement mute functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Mute functionality coming soon!')),
              );
            },
          ),
          _buildActionTile(
            'Clear Chat History',
            Icons.clear_all,
            () => _showClearHistoryDialog(),
            color: Colors.orange,
          ),
          _buildActionTile(
            'Leave Chat',
            Icons.exit_to_app,
            () => _showLeaveChatDialog(),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Future<void> _showClearHistoryDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
          'Are you sure you want to clear all messages in this chat? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implement clear history functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Clear history functionality coming soon!')),
      );
    }
  }

  Future<void> _showLeaveChatDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Chat'),
        content: const Text(
          'Are you sure you want to leave this chat? You will no longer receive messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implement leave chat functionality
      Navigator.of(context).pop(); // Go back to chat list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave chat functionality coming soon!')),
      );
    }
  }

  void _navigateToOrganisation(int organisationId) {
    // TODO: Navigate to organisation detail page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to organisation $organisationId'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _navigateToProject(int projectId) {
    // TODO: Navigate to project detail page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to project $projectId'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
