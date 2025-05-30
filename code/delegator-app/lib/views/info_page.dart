// lib/views/info_page.dart

import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import '../models/user.dart';
import '../models/user_organisation.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({Key? key}) : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  User? _currentUser;
  List<UserOrganisation> _userOrganisations = [];
  UserOrganisation? _selectedOrganisation;
  List<User> _orgUsers = [];
  String? _inviteCode;
  bool _isLoading = true;
  bool _isLoadingInvite = false;
  bool _isLoadingOrgs = false;
  bool _isLoadingOrgUsers = false;
  String? _errorMessage;
  String? _inviteError;
  String? _orgUsersError;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadInviteCode();
    _loadUserOrganisations();
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
    setState(() {
      _isLoadingOrgs = true;
      _orgUsersError = null;
    });

    try {
      final response =
          await ServiceRegistry().organisationService.getAllUserOrganisations();
      final _test =
          new UserOrganisation(user: 3, organisation: 5, role: 1); //debug
      final _user = new List<UserOrganisation>.empty();
      setState(() {
        _userOrganisations = _user;
        _selectedOrganisation = _test;
        _isLoadingOrgs = false;
      });

      if (_selectedOrganisation != null) {
        _loadOrgUsers();
      }
    } catch (e) {
      setState(() {
        _orgUsersError = e.toString();
        _isLoadingOrgs = false;
      });
    }
  }

  Future<void> _loadOrgUsers() async {
    if (_selectedOrganisation == null) return;

    setState(() {
      _isLoadingOrgUsers = true;
      _orgUsersError = null;
    });

    try {
      final users = await ServiceRegistry()
          .organisationService
          .getUsersByOrganisationId(_selectedOrganisation!.organisation);
      setState(() {
        _orgUsers = users;
        _isLoadingOrgUsers = false;
      });
    } catch (e) {
      setState(() {
        _orgUsersError = e.toString();
        _isLoadingOrgUsers = false;
      });
    }
  }

  void _onOrganisationChanged(UserOrganisation? org) {
    setState(() {
      _selectedOrganisation = org;
    });
    if (org != null) {
      _loadOrgUsers();
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
              onPressed: () {
                _loadUserInfo();
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
              onPressed: () {
                _loadUserInfo();
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
          _buildOrgUsersCard(),
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

  Widget _buildOrgUsersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Organization Members (${_orgUsers.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isLoadingOrgs || _isLoadingOrgUsers)
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

            // Organization Selector
            if (_userOrganisations.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Organization:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<UserOrganisation>(
                      value: _selectedOrganisation,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _userOrganisations.map((org) {
                        return DropdownMenuItem<UserOrganisation>(
                          value: org,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'L${org.roleDetails}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    '${org.organisationDetails} (${org.roleDetails})'),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: _onOrganisationChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_orgUsersError != null)
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
                        _orgUsersError!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              )
            else if (_orgUsers.isEmpty && _selectedOrganisation != null)
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
                    Icon(Icons.person_off, color: Colors.grey[400], size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'No members found in ${_selectedOrganisation!.organisationDetails}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else if (_selectedOrganisation == null)
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
                    Icon(Icons.business_center,
                        color: Colors.grey[400], size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'No organizations found',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children:
                    _orgUsers.map((user) => _buildOrgUserTile(user)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgUserTile(User user) {
    final isCurrentUser = _currentUser?.id == user.id;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue[50] : null,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentUser ? Border.all(color: Colors.blue[200]!) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isCurrentUser ? Colors.blue[100] : Colors.grey[200],
          child: Text(
            user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCurrentUser ? Colors.blue[700] : Colors.grey[700],
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.displayName,
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'YOU',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.email != null)
              Text(
                user.email!,
                style: const TextStyle(fontSize: 12),
              ),
            if (user.role != null)
              Text(
                '${user.role!.name} (Level ${user.role!.level})',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: user.role != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'L${user.role!.level}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () => _showUserDetails(user),
      ),
    );
  }

  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Username', user.username),
            if (user.email != null) _buildDetailRow('Email', user.email!),
            if (user.firstName != null)
              _buildDetailRow('First Name', user.firstName!),
            if (user.lastName != null)
              _buildDetailRow('Last Name', user.lastName!),
            if (user.role != null) ...[
              _buildDetailRow('Role', user.role!.name),
              _buildDetailRow('Level', user.role!.level.toString()),
            ],
            if (user.accessType != null)
              _buildDetailRow('Access Type', user.accessType!),
            if (user.joinedProject != null)
              _buildDetailRow(
                  'Joined Project', _formatDate(user.joinedProject!)),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
}
