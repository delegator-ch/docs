// lib/views/manage_project_users_dialog.dart

import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import '../models/user.dart';

class ManageProjectUsersDialog extends StatefulWidget {
  final int projectId;
  final List<User> currentMembers;

  const ManageProjectUsersDialog({
    Key? key,
    required this.projectId,
    required this.currentMembers,
  }) : super(key: key);

  @override
  _ManageProjectUsersDialogState createState() =>
      _ManageProjectUsersDialogState();
}

class _ManageProjectUsersDialogState extends State<ManageProjectUsersDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<User> _availableExternals = [];
  List<User> _searchResults = [];
  List<User> _orgMembers = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProjectUsers();
    _loadAvailableExternals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectUsers() async {
    try {
      final projectUsers =
          await ServiceRegistry().userService.getByProjectId(widget.projectId);

      final orgMembers = projectUsers
          .where((user) =>
              user.accessType == 'organization' || user.accessType == null)
          .toList();

      setState(() {
        _orgMembers = orgMembers;
        widget.currentMembers.removeWhere(
            (member) => orgMembers.any((org) => org.id == member.id));
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadAvailableExternals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get project to find organisation ID
      final project =
          await ServiceRegistry().projectService.getById(widget.projectId);

      // Get organisation externals
      final orgExternals = await ServiceRegistry()
          .externalService
          .getByOrganisationId(project.organisationId);

      // Get current project externals
      final projectExternals = await ServiceRegistry()
          .externalService
          .getByProjectId(widget.projectId);

      // Remove externals already in project
      final projectExternalIds = projectExternals.map((u) => u.id).toSet();
      final available = orgExternals
          .where((user) =>
              user.id != null && !projectExternalIds.contains(user.id))
          .toList();

      setState(() {
        _availableExternals = available;
        _searchResults = available;
        // Update current members with project externals
        widget.currentMembers.clear();
        widget.currentMembers.addAll(projectExternals);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _searchUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _searchResults = _availableExternals;
      } else {
        _searchResults = _availableExternals.where((user) {
          final username = user.username.toLowerCase();
          final email = user.email?.toLowerCase() ?? '';
          final firstName = user.firstName?.toLowerCase() ?? '';
          final lastName = user.lastName?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();

          return username.contains(searchLower) ||
              email.contains(searchLower) ||
              firstName.contains(searchLower) ||
              lastName.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _addExternalToProject(User external) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ServiceRegistry().externalService.addToProject(
            external.id!,
            widget.projectId,
          );

      setState(() {
        _availableExternals.removeWhere((u) => u.id == external.id);
        _searchResults.removeWhere((u) => u.id == external.id);
        widget.currentMembers.add(external);
        _hasChanges = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${external.displayName} added to project'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add external: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeExternalFromProject(User external) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove External Member'),
        content: Text(
            'Are you sure you want to remove ${external.displayName} from this project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ServiceRegistry().externalService.removeFromProject(
            external.id!,
            widget.projectId,
          );

      setState(() {
        widget.currentMembers.removeWhere((u) => u.id == external.id);
        _availableExternals.add(external);
        _searchResults = _availableExternals;
        _hasChanges = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${external.displayName} removed from project'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove external: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Manage Project Members',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(_hasChanges),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue[700],
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Colors.blue[700],
                tabs: [
                  Tab(
                    text:
                        'All Members (${_orgMembers.length + widget.currentMembers.length})',
                  ),
                  Tab(
                    text: 'Add Externals (${_availableExternals.length})',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllMembersTab(),
                  _buildAddExternalsTab(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  if (_hasChanges)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 16, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Changes saved',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_hasChanges),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllMembersTab() {
    if (_orgMembers.isEmpty && widget.currentMembers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No members in this project',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Organization members are auto-assigned, externals can be added',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_orgMembers.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.business, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Organization Members (${_orgMembers.length}) - Auto-assigned',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ..._orgMembers.map((member) => _buildMemberCard(
                member,
                isCurrentMember: true,
                isOrgMember: true,
              )),
          const SizedBox(height: 16),
        ],
        if (widget.currentMembers.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.person_add, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'External Members (${widget.currentMembers.length}) - Manually added',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...widget.currentMembers.map((member) => _buildMemberCard(
                member,
                isCurrentMember: true,
                isOrgMember: false,
              )),
        ],
      ],
    );
  }

  Widget _buildAddExternalsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search external users by name or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchUsers('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _searchUsers,
          ),
        ),
        Expanded(
          child: _buildExternalsList(),
        ),
      ],
    );
  }

  Widget _buildExternalsList() {
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
            const Text(
              'Error loading externals',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAvailableExternals,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.person_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No externals found matching "$_searchQuery"'
                  : 'No available externals to add',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'All externals are already added to this project',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final external = _searchResults[index];
        return _buildMemberCard(external,
            isCurrentMember: false, isOrgMember: false);
      },
    );
  }

  Widget _buildMemberCard(User user,
      {required bool isCurrentMember, required bool isOrgMember}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOrgMember ? Colors.blue[100] : Colors.orange[100],
          child: Text(
            user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isOrgMember ? Colors.blue[700] : Colors.orange[700],
            ),
          ),
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isOrgMember ? Colors.blue[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isOrgMember ? 'ORG' : 'EXT',
                style: TextStyle(
                  fontSize: 10,
                  color: isOrgMember ? Colors.blue[700] : Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isCurrentMember)
              if (isOrgMember)
                Icon(Icons.lock, color: Colors.grey[400], size: 20)
              else
                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () => _removeExternalFromProject(user),
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  tooltip: 'Remove external from project',
                )
            else
              IconButton(
                onPressed:
                    _isLoading ? null : () => _addExternalToProject(user),
                icon: const Icon(Icons.add_circle, color: Colors.green),
                tooltip: 'Add external to project',
              ),
          ],
        ),
      ),
    );
  }
}
