// lib/views/widgets/organizations_widget.dart

import 'package:flutter/material.dart';
import '../../models/user_organisation.dart';

class OrganizationsWidget extends StatelessWidget {
  final List<UserOrganisation> organizations;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;
  final Function(UserOrganisation) onLeave;
  final Function(UserOrganisation) onInviteUser;

  const OrganizationsWidget({
    Key? key,
    required this.organizations,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.onLeave,
    required this.onInviteUser,
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
                Icon(Icons.business, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'My Organizations (${organizations.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (error != null)
              _buildErrorContainer(error!)
            else if (organizations.isEmpty)
              _buildEmptyState()
            else
              Column(
                children: organizations
                    .map((userOrg) => _buildOrganizationTile(context, userOrg))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContainer(String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.business_outlined, color: Colors.grey[400], size: 32),
          const SizedBox(height: 8),
          Text(
            'No organizations found',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You are not a member of any organizations',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationTile(
      BuildContext context, UserOrganisation userOrg) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.business, color: Colors.blue[700]),
        ),
        title: Text(
          userOrg.organisationDetails?.name ??
              'Organization #${userOrg.organisation}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userOrg.roleDetails != null)
              Text(
                '${userOrg.roleDetails!.name} (Level ${userOrg.roleDetails!.level})',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            if (userOrg.organisationDetails?.since != null)
              Text(
                'Since: ${_formatDate(userOrg.organisationDetails!.since!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ID: ${userOrg.organisation}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.red),
              onPressed: () => onLeave(userOrg),
              tooltip: 'Leave Organization',
            ),
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.blue, size: 20),
              onPressed: () => onInviteUser(userOrg),
              tooltip: 'Invite User',
            ),
          ],
        ),
        onTap: () => _showOrganizationDetails(context, userOrg),
      ),
    );
  }

  void _showOrganizationDetails(
      BuildContext context, UserOrganisation userOrg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(userOrg.organisationDetails?.name ?? 'Organization Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Organization ID: ${userOrg.organisation}'),
            const SizedBox(height: 8),
            if (userOrg.roleDetails != null) ...[
              Text('Your Role: ${userOrg.roleDetails!.name}'),
              Text('Role Level: ${userOrg.roleDetails!.level}'),
              const SizedBox(height: 8),
            ],
            if (userOrg.organisationDetails?.since != null)
              Text(
                  'Organization Since: ${_formatDate(userOrg.organisationDetails!.since!)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
