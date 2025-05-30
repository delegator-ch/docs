// Add this as a new widget in info_page.dart or as a separate file

import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import '../models/user.dart';
import '../models/user_organisation.dart';

class InviteUserDialog extends StatefulWidget {
  final UserOrganisation organisation;
  final VoidCallback onInvite;

  const InviteUserDialog({
    Key? key,
    required this.organisation,
    required this.onInvite,
  }) : super(key: key);

  @override
  _InviteUserDialogState createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<InviteUserDialog> {
  final _codeController = TextEditingController();
  List<User> _orgMembers = [];
  bool _isLoading = true;
  int _selectedRole = 6; // Default role

  final List<Map<String, dynamic>> _roles = [
    {'id': 1, 'name': 'Admin', 'level': 1},
    {'id': 2, 'name': 'Long-Term Members', 'level': 2},
    {'id': 3, 'name': 'Member', 'level': 3},
    {'id': 4, 'name': 'Familiy & Friends', 'level': 4},
    {'id': 5, 'name': 'Fans', 'level': 5},
    {'id': 6, 'name': 'External', 'level': 6},
  ];

  @override
  void initState() {
    super.initState();
    _loadOrgMembers();
  }

  Future<void> _loadOrgMembers() async {
    try {
      final members = await ServiceRegistry()
          .organisationService
          .getUsersByOrganisationId(widget.organisation.organisation);
      setState(() {
        _orgMembers = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite to ${widget.organisation.organisationDetails?.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Current members section
            Text('Current Members (${_orgMembers.length})',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            Expanded(
              flex: 2,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _orgMembers.length,
                      itemBuilder: (context, index) {
                        final member = _orgMembers[index];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            child: Text(member.username[0].toUpperCase()),
                          ),
                          title: Text(member.displayName),
                          subtitle: Text(member.role?.name ?? 'Unknown role'),
                        );
                      },
                    ),
            ),

            const Divider(),

            // Invite section
            const Text('Invite New User',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'User Invite Code',
                hintText: 'Enter #CODE123',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<int>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              items: _roles.map((role) {
                return DropdownMenuItem<int>(
                  value: role['id'],
                  child: Text('${role['name']} (Level ${role['level']})'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedRole = value!),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _inviteUser(),
                  child: const Text('Invite'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _inviteUser() async {
    if (_codeController.text.trim().isEmpty) return;

    try {
      await ServiceRegistry().apiClient.post('invite-user/', {
        'organisation': widget.organisation.organisation,
        'invite_code': _codeController.text.trim(),
        'role': _selectedRole,
      });

      Navigator.of(context).pop();
      widget.onInvite();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User invited successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to invite user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
