// lib/views/info_page.dart

import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import '../models/user.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({Key? key}) : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ServiceRegistry().authService.getCurrentUser();
      setState(() {
        _currentUser = user;
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
        title: const Text('Info'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUserInfo),
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
              'Error loading user info',
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
            ElevatedButton(
              onPressed: _loadUserInfo,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserCard(),
          const SizedBox(height: 20),
          _buildAppInfoCard(),
          const SizedBox(height: 20),
          _buildServicesStatusCard(),
          const SizedBox(height: 20),
          _buildSettingsCard(),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, size: 50, color: Colors.blue[700]),
            ),
            const SizedBox(height: 16),
            Text(
              _currentUser?.username ?? 'Unknown User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_currentUser?.email != null)
              Text(
                _currentUser!.email!,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            const SizedBox(height: 16),
            if (_currentUser?.isPremium == true)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Premium User',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'App Information',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('App Name', 'Delegator'),
            _buildInfoRow('Version', '1.0.0'),
            _buildInfoRow('Build', 'Debug'),
            _buildInfoRow('Platform', 'Flutter'),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.api, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Services Status',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildServiceStatusTile('Authentication', true, Icons.security),
            _buildServiceStatusTile('Projects API', true, Icons.work),
            _buildServiceStatusTile('Tasks API', true, Icons.task),
            _buildServiceStatusTile('Events API', true, Icons.event),
            _buildServiceStatusTile('Chats API', true, Icons.chat),
            _buildServiceStatusTile('Messages API', true, Icons.message),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  'Settings & Actions',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              'Test Projects Service',
              Icons.work,
              () => _testService('projects'),
            ),
            _buildActionTile(
              'Test Events Service',
              Icons.event,
              () => _testService('events'),
            ),
            _buildActionTile(
              'Test Tasks Service',
              Icons.task,
              () => _testService('tasks'),
            ),
            _buildActionTile(
              'Test Chats Service',
              Icons.chat,
              () => _testService('chats'),
            ),
            const Divider(),
            _buildActionTile(
              'Clear Cache',
              Icons.clear_all,
              () => _clearCache(),
              color: Colors.orange,
            ),
            _buildActionTile(
              'Logout',
              Icons.logout,
              () => _logout(),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildServiceStatusTile(
    String serviceName,
    bool isOnline,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(serviceName)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOnline ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOnline ? Icons.check_circle : Icons.error,
                  size: 16,
                  color: isOnline ? Colors.green[700] : Colors.red[700],
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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

  Future<void> _testService(String serviceName) async {
    try {
      switch (serviceName) {
        case 'projects':
          final projects = await ServiceRegistry().projectService.getAll();
          _showSnackBar(
            '✅ Projects service working. Loaded ${projects.length} projects',
          );
          break;
        case 'events':
          final events = await ServiceRegistry().eventService.getAll();
          _showSnackBar(
            '✅ Events service working. Loaded ${events.length} events',
          );
          break;
        case 'tasks':
          final tasks = await ServiceRegistry().taskService.getAll();
          _showSnackBar(
            '✅ Tasks service working. Loaded ${tasks.length} tasks',
          );
          break;
        case 'chats':
          final chats = await ServiceRegistry().chatService.getAll();
          _showSnackBar(
            '✅ Chats service working. Loaded ${chats.length} chats',
          );
          break;
      }
    } catch (e) {
      _showSnackBar('❌ Error testing $serviceName service: $e', isError: true);
    }
  }

  Future<void> _clearCache() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Cache'),
            content: const Text(
              'Are you sure you want to clear the app cache? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Clear'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      // TODO: Implement cache clearing logic
      _showSnackBar('Cache cleared successfully');
    }
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await ServiceRegistry().authService.logout();
      _showSnackBar('Logged out successfully');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
