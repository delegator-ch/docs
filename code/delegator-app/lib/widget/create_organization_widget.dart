// lib/views/widgets/create_organization_widget.dart

import 'package:flutter/material.dart';

class CreateOrganizationWidget extends StatelessWidget {
  final Function(String) onCreateOrganization;

  const CreateOrganizationWidget({
    Key? key,
    required this.onCreateOrganization,
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
                Icon(Icons.add_business, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Create Organization',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Start a new organization and invite members',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showCreateOrganizationDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Organization'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateOrganizationDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Organization'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Organization Name',
            hintText: 'Enter organization name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                onCreateOrganization(nameController.text.trim());
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
