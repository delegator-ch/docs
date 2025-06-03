// lib/views/widgets/settings_widget.dart

import 'package:flutter/material.dart';

class SettingsWidget extends StatelessWidget {
  final Function(String) onTestService;
  final VoidCallback onClearCache;
  final VoidCallback onLogout;

  const SettingsWidget({
    Key? key,
    required this.onTestService,
    required this.onClearCache,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              () => onTestService('projects'),
            ),
            _buildActionTile(
              'Test Events Service',
              Icons.event,
              () => onTestService('events'),
            ),
            _buildActionTile(
              'Test Tasks Service',
              Icons.task,
              () => onTestService('tasks'),
            ),
            _buildActionTile(
              'Test Chats Service',
              Icons.chat,
              () => onTestService('chats'),
            ),
            const Divider(),
            _buildActionTile(
              'Clear Cache',
              Icons.clear_all,
              onClearCache,
              color: Colors.orange,
            ),
            _buildActionTile(
              'Logout',
              Icons.logout,
              onLogout,
              color: Colors.red,
            ),
          ],
        ),
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
}
