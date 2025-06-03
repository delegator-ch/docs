// lib/views/info_page.dart

import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import '../models/user.dart';
import '../models/user_organisation.dart';
import '../models/organisation.dart';
import '../models/invitation.dart';
import '../widget/invite_user_dialog.dart';
import 'package:provider/provider.dart';
import '../providers/organization_context_provider.dart';
import '../widget/organization_selector.dart';

// Separate widget files
import '../widget/user_card_widget.dart';
import '../widget/premiun_status_widget.dart';
import '../widget/invite_code_widget.dart';
import '../widget/pending_invitations_widget.dart';
import '../widget/organizations_widget.dart';
import '../widget/create_organization_widget.dart';
import '../widget/app_info_widget.dart';
import '../widget/services_status_widget.dart';
import '../widget/settings_widget.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({Key? key}) : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  User? _currentUser;
  String? _inviteCode;
  List<UserOrganisation> _userOrganisations = [];
  List<Invitation> _pendingInvitations = [];

  bool _isLoading = true;
  bool _isLoadingInvite = false;
  bool _isLoadingOrgs = false;
  bool _isLoadingInvitations = false;

  String? _errorMessage;
  String? _inviteError;
  String? _orgsError;
  String? _invitationsError;

  @override
  void initState() {
    super.initState();
    _loadUserInfo().then((_) {
      _loadInviteCode();
      _loadUserOrganisations();
      _loadPendingInvitations();
    });
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userinfo = await ServiceRegistry().authService.getCurrentUser();
      if (userinfo?.id == null) {
        throw Exception("Id is null");
      }
      final id = userinfo!.id ?? 0;
      final byId = await ServiceRegistry().userService.getById(id);
      setState(() {
        _currentUser = byId;
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
        _inviteCode = "#" + response.data['invite_code'];
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

  Future<void> _loadPendingInvitations() async {
    setState(() {
      _isLoadingInvitations = true;
      _invitationsError = null;
    });

    try {
      final invitations =
          await ServiceRegistry().organisationService.getMyInvitations();
      invitations.sort((a, b) {
        if (a.canAccept && !a.isExpired && (!b.canAccept || b.isExpired))
          return -1;
        if (b.canAccept && !b.isExpired && (!a.canAccept || a.isExpired))
          return 1;
        return b.id.compareTo(a.id);
      });

      setState(() {
        _pendingInvitations = invitations;
        _isLoadingInvitations = false;
      });
    } catch (e) {
      setState(() {
        _invitationsError = e.toString();
        _isLoadingInvitations = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await _loadUserInfo();
    _loadInviteCode();
    _loadUserOrganisations();
    _loadPendingInvitations();
  }

  void _showSnackBar(String message,
      {bool isError = false, Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? (isError ? Colors.red : null),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ServiceRegistry().authService.logout();
              _showSnackBar('Logged out successfully');
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
      return _buildErrorState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserCardWidget(user: _currentUser),
          const SizedBox(height: 20),
          PremiumStatusWidget(
            isPremium: _currentUser?.isPremium == true,
            onUpgrade: _upgradeToPremium,
          ),
          const SizedBox(height: 20),
          InviteCodeWidget(
            inviteCode: _inviteCode,
            isLoading: _isLoadingInvite,
            error: _inviteError,
            onRefresh: _loadInviteCode,
          ),
          const SizedBox(height: 20),
          PendingInvitationsWidget(
            invitations: _pendingInvitations,
            isLoading: _isLoadingInvitations,
            error: _invitationsError,
            onRefresh: _loadPendingInvitations,
            onAccept: _acceptInvitation,
            onDecline: _declineInvitation,
          ),
          const SizedBox(height: 20),
          OrganizationsWidget(
            organizations: _userOrganisations,
            isLoading: _isLoadingOrgs,
            error: _orgsError,
            onRefresh: _loadUserOrganisations,
            onLeave: _leaveOrganisation,
            onInviteUser: _showInviteUserDialog,
          ),
          const SizedBox(height: 20),
          CreateOrganizationWidget(
            onCreateOrganization: _createOrganisation,
          ),
          const SizedBox(height: 20),
          const AppInfoWidget(),
          const SizedBox(height: 20),
          const ServicesStatusWidget(),
          const SizedBox(height: 20),
          SettingsWidget(
            onTestService: _testService,
            onClearCache: _clearCache,
            onLogout: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
            onPressed: _refreshAll,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Business logic methods remain here
  void _showInviteUserDialog(UserOrganisation userOrg) {
    showDialog(
      context: context,
      builder: (context) => InviteUserDialog(
        organisation: userOrg,
        onInvite: () => _loadUserOrganisations(),
      ),
    );
  }

  Future<void> _acceptInvitation(Invitation invitation) async {
    _showSnackBar('Accepting invitation...', backgroundColor: Colors.blue);

    try {
      await ServiceRegistry()
          .organisationService
          .acceptInvitation(invitation.inviteCode);

      _showSnackBar('🎉 Successfully joined organization!',
          backgroundColor: Colors.green);

      await Future.wait([
        _loadPendingInvitations(),
        _loadUserOrganisations(),
      ]);
    } catch (e) {
      _showSnackBar('Failed to accept invitation: $e', isError: true);
    }
  }

  Future<void> _declineInvitation(Invitation invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Invitation'),
        content:
            const Text('Are you sure you want to decline this invitation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ServiceRegistry()
            .organisationService
            .deleteInvitation(invitation.id);
        _showSnackBar('Invitation declined');
        _loadPendingInvitations();
      } catch (e) {
        _showSnackBar('Failed to decline invitation: $e', isError: true);
      }
    }
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
        _loadUserOrganisations();
      } catch (e) {
        _showSnackBar('Failed to leave organization: $e', isError: true);
      }
    }
  }

  Future<void> _upgradeToPremium() async {
    try {
      await ServiceRegistry().userService.upgradeToPremium();
      _showSnackBar('Successfully upgraded to premium!',
          backgroundColor: Colors.green);
      await _loadUserInfo();
    } catch (e) {
      _showSnackBar('Failed to upgrade to premium: $e', isError: true);
    }
  }

  Future<void> _testService(String serviceName) async {
    try {
      int count = 0;
      switch (serviceName) {
        case 'projects':
          final projects = await ServiceRegistry().projectService.getAll();
          count = projects.length;
          break;
        case 'events':
          final events = await ServiceRegistry().eventService.getAll();
          count = events.length;
          break;
        case 'tasks':
          final tasks = await ServiceRegistry().taskService.getAll();
          count = tasks.length;
          break;
        case 'chats':
          final chats = await ServiceRegistry().chatService.getAll();
          count = chats.length;
          break;
      }
      _showSnackBar('✅ $serviceName service working. Loaded $count items');
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
}
