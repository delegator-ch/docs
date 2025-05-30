// lib/views/info_page.dart

import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import '../models/user.dart';
import '../models/user_organisation.dart';
import '../models/organisation.dart';
import '../widget/invite_user_dialog.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({Key? key}) : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  User? _currentUser;
  String? _inviteCode;
  List<UserOrganisation> _userOrganisations = [];
  bool _isLoading = true;
  bool _isLoadingInvite = false;
  bool _isLoadingOrgs = false;
  String? _errorMessage;
  String? _inviteError;
  String? _orgsError;

  @override
  void initState() {
    super.initState();
    _loadUserInfo().then((_) {
      _loadInviteCode();
      _loadUserOrganisations();
    });
  }

  void _showInviteUserDialog(UserOrganisation userOrg) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => InviteUserDialog(
        organisation: userOrg,
        onInvite: () => _loadUserOrganisations(),
      ),
    );
  }

  Future<void> _inviteUserToOrg(int orgId, String inviteCode) async {
    try {
      // You'll need an API endpoint that accepts invite codes
      // This is a placeholder - implement based on your API
      await ServiceRegistry().apiClient.post('invite-user/', {
        'organisation': orgId,
        'invite_code': inviteCode,
      });

      _showSnackBar('User invited successfully');
    } catch (e) {
      _showSnackBar('Failed to invite user: $e', isError: true);
    }
  }

  Widget _buildCreateOrganisationCard() {
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
              onPressed: _showCreateOrganisationDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create New Organization'),
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

  void _showCreateOrganisationDialog() {
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
                await _createOrganisation(nameController.text.trim());
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createOrganisation(String name) async {
    try {
      await ServiceRegistry().organisationService.create(
            Organisation(id: 0, name: name),
          );
      _showSnackBar('Organization "$name" created successfully');
      _loadUserOrganisations();
    } catch (e) {
      _showSnackBar('Failed to create organization: $e', isError: true);
    }
  }

  Future<void> _leaveOrganisation(UserOrganisation userOrg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Organization'),
        content: Text(
          'Are you sure you want to leave "${userOrg.organisationDetails?.name ?? 'Organization #${userOrg.organisation}'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ServiceRegistry().organisationService.removeUserFromOrganisation(
              _currentUser!.id!,
              userOrg.organisation,
            );

        _showSnackBar('Left organization successfully');
        _loadUserOrganisations(); // Refresh the list
      } catch (e) {
        _showSnackBar('Failed to leave organization: $e', isError: true);
      }
    }
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

  Future<void> _loadInviteCode() async {
    setState(() {
      _isLoadingInvite = true;
      _inviteError = null;
    });

    try {
      final response = await ServiceRegistry().apiClient.get('my-profile/');
      setState(() {
        _inviteCode = "#" + response['invite_code'];
        _isLoadingInvite = false;
      });
    } catch (e) {
      setState(() {
        _inviteError = e.toString();
        _isLoadingInvite = false;
      });
    }
  }

  Future<void> _loadUserOrganisations() async {
    if (_currentUser?.id == null) return;

    setState(() {
      _isLoadingOrgs = true;
      _orgsError = null;
    });

    try {
      final userOrgs = await ServiceRegistry()
          .organisationService
          .getUserOrganisationsByUserId(_currentUser!.id!);
      setState(() {
        _userOrganisations = userOrgs;
        _isLoadingOrgs = false;
      });
    } catch (e) {
      setState(() {
        _orgsError = e.toString();
        _isLoadingOrgs = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Info'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await _loadUserInfo();
                _loadInviteCode();
                _loadUserOrganisations();
              }),
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
              onPressed: () async {
                await _loadUserInfo();
                _loadInviteCode();
                _loadUserOrganisations();
              },
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
          _buildInviteCodeCard(),
          const SizedBox(height: 20),
          _buildOrganisationsCard(),
          const SizedBox(height: 20),
          _buildAppInfoCard(),
          const SizedBox(height: 20),
          _buildServicesStatusCard(),
          const SizedBox(height: 20),
          _buildSettingsCard(),
          const SizedBox(height: 20),
          _buildCreateOrganisationCard(),
        ],
      ),
    );
  }

  Widget _buildOrganisationsCard() {
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
                  'My Organizations (${_userOrganisations.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoadingOrgs)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadUserOrganisations,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_orgsError != null)
              Container(
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
                        _orgsError!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              )
            else if (_userOrganisations.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.business_outlined,
                        color: Colors.grey[400], size: 32),
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
              )
            else
              Column(
                children: _userOrganisations
                    .map((userOrg) => _buildOrganisationTile(userOrg))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganisationTile(UserOrganisation userOrg) {
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
              onPressed: () => _leaveOrganisation(userOrg),
              tooltip: 'Leave Organization',
            ),
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.blue, size: 20),
              onPressed: () => _showInviteUserDialog(userOrg),
              tooltip: 'Invite User',
            ),
          ],
        ),
        onTap: () => _showOrganisationDetails(userOrg),
      ),
    );
  }

  void _showOrganisationDetails(UserOrganisation userOrg) {
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

  Widget _buildInviteCodeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Invite Code',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoadingInvite)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadInviteCode,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_inviteError != null)
              Container(
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
                        _inviteError!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              )
            else if (_inviteCode != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      _inviteCode!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            // Copy to clipboard
                            // TODO: Add clipboard package and implement
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Copy feature coming soon!')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                        ),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          onPressed: () {
                            // Share functionality
                            // TODO: Add share package and implement
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Share feature coming soon!')),
                            );
                          },
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('Share'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Text(
                  'No invite code available',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
      _showSnackBar('Cache cleared successfully');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
