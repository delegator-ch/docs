// lib/pages/page-project-detail.dart
import 'package:flutter/material.dart';
import '../model/project_model.dart';

class PageProjectDetail extends StatelessWidget {
  final Project project;

  const PageProjectDetail({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(project.name ?? 'Project Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailItem('ID', project.id.toString()),
            _buildDetailItem(
              'Organisation',
              project.organisationName ??
                  'Organisation #${project.organisation}',
            ),
            if (project.deadline != null)
              _buildDetailItem('Deadline', _formatDate(project.deadline!)),
            _buildDetailItem('Priority', _getPriorityLabel(project.priority)),
            if (project.event != null)
              _buildDetailItem('Event ID', project.event.toString()),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Status section for future implementation
            const Text(
              'Project Status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Status details will be implemented in future updates',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    final DateTime dateTime = DateTime.parse(date);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 0:
        return 'Low';
      case 1:
        return 'Medium';
      case 2:
        return 'High';
      case 3:
        return 'Urgent';
      default:
        return 'Unknown ($priority)';
    }
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
