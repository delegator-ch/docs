// lib/views/widgets/services_status_widget.dart

import 'package:flutter/material.dart';

class ServicesStatusWidget extends StatelessWidget {
  const ServicesStatusWidget({Key? key}) : super(key: key);

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
}
