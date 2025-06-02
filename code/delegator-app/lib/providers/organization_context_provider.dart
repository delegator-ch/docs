// lib/providers/organization_context_provider.dart

import 'package:flutter/material.dart';
import '../models/user_organisation.dart';
import '../services/service_registry.dart';
import 'package:provider/provider.dart';

/// Provider for managing the current organization context
class OrganizationContextProvider extends ChangeNotifier {
  UserOrganisation? _currentOrganization;
  List<UserOrganisation> _userOrganizations = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  UserOrganisation? get currentOrganization => _currentOrganization;
  List<UserOrganisation> get userOrganizations => _userOrganizations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasOrganizations => _userOrganizations.isNotEmpty;

  /// Initialize and load user's organizations
  Future<void> initialize() async {
    await loadUserOrganizations();
  }

  /// Load user's organizations from the API
  Future<void> loadUserOrganizations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentUser = await ServiceRegistry().authService.getCurrentUser();
      if (currentUser?.id == null) {
        throw Exception("User not logged in");
      }

      final userOrgs = await ServiceRegistry()
          .organisationService
          .getUserOrganisationsByUserId(currentUser!.id!);

      _userOrganizations = userOrgs;

      // Set the first organization as current if none is selected
      if (_currentOrganization == null && userOrgs.isNotEmpty) {
        _currentOrganization = userOrgs.first;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set the current organization
  void setCurrentOrganization(UserOrganisation organization) {
    _currentOrganization = organization;
    notifyListeners();
  }

  /// Clear the current organization context
  void clearContext() {
    _currentOrganization = null;
    _userOrganizations = [];
    _error = null;
    notifyListeners();
  }

  /// Refresh organizations (useful after joining/leaving orgs)
  Future<void> refresh() async {
    await loadUserOrganizations();
  }
}

/// Widget to provide organization context to the widget tree
class OrganizationContextWrapper extends StatefulWidget {
  final Widget child;

  const OrganizationContextWrapper({Key? key, required this.child})
      : super(key: key);

  @override
  _OrganizationContextWrapperState createState() =>
      _OrganizationContextWrapperState();
}

class _OrganizationContextWrapperState
    extends State<OrganizationContextWrapper> {
  late final OrganizationContextProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = OrganizationContextProvider();
    _provider.initialize();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OrganizationContextProvider>.value(
      value: _provider,
      child: widget.child,
    );
  }
}
