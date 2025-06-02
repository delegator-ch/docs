// lib/services/organisation_service.dart

import 'dart:async';
import '../models/organisation.dart';
import '../models/project.dart';
import '../models/user.dart';
import '../models/invitation.dart';
import '../models/user_organisation.dart';
import '../models/paginated_response.dart';
import 'base_service.dart';
import '../models/api_client.dart';
import '../config/api_config.dart';

/// Service for managing Organisation entities
class OrganisationService implements BaseService<Organisation> {
  final ApiClient _apiClient;

  OrganisationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<Organisation>> getAll() async {
    final fullResponse = await _apiClient.get(ApiConfig.organisations);
    final response = fullResponse.data;
    // Handle paginated response
    final paginatedResponse = PaginatedResponse<Organisation>.fromJson(
      response,
      (json) => Organisation.fromJson(json),
    );

    return paginatedResponse.results;
  }

  @override
  Future<Organisation> getById(int id) async {
    final response = await _apiClient.get('${ApiConfig.organisations}$id/');
    return Organisation.fromJson(response.data);
  }

// Method to add to OrganisationService class:

  /// Get current user's pending invitations
  Future<List<Invitation>> getMyInvitations() async {
    try {
      final fullResponse = await _apiClient.get('my-invitations/');
      final response = fullResponse.data;
      if (response is Map<String, dynamic> &&
          response.containsKey('pending_invitations')) {
        final List<dynamic> invitationsJson = response['pending_invitations'];
        return invitationsJson
            .map((invitationJson) => Invitation.fromJson(invitationJson))
            .toList();
      } else {
        throw Exception('Unexpected response format: ${response.runtimeType}');
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get my invitations', e);
    } catch (e) {
      throw Exception('Failed to get my invitations: $e');
    }
  }

  @override
  Future<Organisation> create(Organisation organisation) async {
    final fullResponse = await _apiClient.post(
      ApiConfig.organisations,
      organisation.toJson(),
    );
    final response = fullResponse.data;
    return Organisation.fromJson(response);
  }

  @override
  Future<Organisation> update(Organisation organisation) async {
    final fullResponse = await _apiClient.put(
      '${ApiConfig.organisations}${organisation.id}/',
      organisation.toJson(),
    );
    final response = fullResponse.data;
    return Organisation.fromJson(response);
  }

  @override
  Future<bool> delete(int id) async {
    await _apiClient.delete('${ApiConfig.organisations}$id/');
    return true;
  }

  /// Enhance projects with full organisation details
  Future<List<Project>> enhanceProjectsWithOrganisations(
    List<Project> projects,
  ) async {
    // Get unique organisation IDs
    final organisationIds =
        projects.map((p) => p.organisationId).toSet().toList();

    // Fetch each organisation (this could be optimized with batch requests if API supports it)
    final Map<int, Organisation> organisationsMap = {};
    for (final id in organisationIds) {
      try {
        final org = await getById(id);
        organisationsMap[id] = org;
      } catch (e) {
        print('⚠️ Failed to fetch organisation $id: $e');
        // Continue with other organisations
      }
    }

    // Enhance projects with full organisation details
    return projects.map((project) {
      if (organisationsMap.containsKey(project.organisationId)) {
        return project.withOrganisation(
          organisationsMap[project.organisationId]!,
        );
      }
      return project;
    }).toList();
  }

  /// Get all users from an organisation
  Future<List<User>> getUsersByOrganisationId(int organisationId) async {
    if (organisationId <= 0) {
      throw ArgumentError('Organisation ID must be a positive integer');
    }

    try {
      final fullResponse =
          await _apiClient.get('/organisations/$organisationId/users/');
      final response = fullResponse.data;
      final List<dynamic> usersJson = response['users'];
      return usersJson
          .map((userJson) => User.fromJson(userJson['user_details']))
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Organisation with ID $organisationId not found');
      }
      throw Exception(
          'Failed to get users for organisation $organisationId: [${e.statusCode}] ${e.message}');
    } catch (e) {
      throw Exception(
          'Failed to get users for organisation $organisationId: $e');
    }
  }

  // UserOrganisation methods

  /// Get all user-organisation relationships
  Future<List<UserOrganisation>> getAllUserOrganisations() async {
    try {
      final fullResponse = await _apiClient.get('user-organisations/');
      final response = fullResponse.data;
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<UserOrganisation>.fromJson(
          response,
          (json) => UserOrganisation.fromJson(json),
        );
        return paginatedResponse.results;
      } else {
        throw Exception('Unexpected response format: ${response.runtimeType}');
      }
    } on ApiException catch (e) {
      _handleApiException('Failed to get all user-organisations', e);
    } catch (e) {
      throw Exception('Failed to get all user-organisations: $e');
    }
  }

  /// Get user-organisation relationships for a specific user
  Future<List<UserOrganisation>> getUserOrganisationsByUserId(
      int userId) async {
    if (userId <= 0) {
      throw ArgumentError('User ID must be a positive integer');
    }

    try {
      final fullResponse =
          await _apiClient.get('user-organisations/?user=$userId');
      final response = fullResponse.data;
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<UserOrganisation>.fromJson(
          response,
          (json) => UserOrganisation.fromJson(json),
        );
        return paginatedResponse.results;
      } else {
        throw Exception('Unexpected response format: ${response.runtimeType}');
      }
    } on ApiException catch (e) {
      _handleApiException(
          'Failed to get user-organisations for user $userId', e);
    } catch (e) {
      throw Exception('Failed to get user-organisations for user $userId: $e');
    }
  }

  /// Get user-organisation relationships for a specific organisation
  Future<List<UserOrganisation>> getUserOrganisationsByOrganisationId(
      int organisationId) async {
    if (organisationId <= 0) {
      throw ArgumentError('Organisation ID must be a positive integer');
    }

    try {
      final fullResponse = await _apiClient
          .get('user-organisations/?organisation=$organisationId');
      final response = fullResponse.data;
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        final paginatedResponse = PaginatedResponse<UserOrganisation>.fromJson(
          response,
          (json) => UserOrganisation.fromJson(json),
        );
        return paginatedResponse.results;
      } else {
        throw Exception('Unexpected response format: ${response.runtimeType}');
      }
    } on ApiException catch (e) {
      _handleApiException(
          'Failed to get user-organisations for organisation $organisationId',
          e);
    } catch (e) {
      throw Exception(
          'Failed to get user-organisations for organisation $organisationId: $e');
    }
  }

  /// Get a specific user-organisation relationship by ID
  Future<UserOrganisation> getUserOrganisationById(int id) async {
    if (id <= 0) {
      throw ArgumentError('UserOrganisation ID must be a positive integer');
    }

    try {
      final fullResponse = await _apiClient.get('user-organisations/$id/');
      final response = fullResponse.data;
      return UserOrganisation.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('UserOrganisation with ID $id not found');
      }
      _handleApiException('Failed to get user-organisation with ID $id', e);
    } catch (e) {
      throw Exception('Failed to get user-organisation with ID $id: $e');
    }
  }

  /// Create a new user-organisation relationship
  Future<UserOrganisation> createUserOrganisation(
      UserOrganisation userOrganisation) async {
    try {
      final fullResponse = await _apiClient.post(
        'user-organisations/',
        userOrganisation.toJson(),
      );
      final response = fullResponse.data;
      return UserOrganisation.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        throw Exception('User is already in this organisation');
      }
      _handleApiException('Failed to create user-organisation', e);
    } catch (e) {
      throw Exception('Failed to create user-organisation: $e');
    }
  }

  /// Update an existing user-organisation relationship
  Future<UserOrganisation> updateUserOrganisation(
      UserOrganisation userOrganisation) async {
    if (userOrganisation.id == null) {
      throw ArgumentError('Cannot update a user-organisation without an ID');
    }

    try {
      final response = await _apiClient.put(
        'user-organisations/${userOrganisation.id}/',
        userOrganisation.toJson(),
      );
      return UserOrganisation.fromJson(response.data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception(
            'UserOrganisation with ID ${userOrganisation.id} not found');
      }
      _handleApiException('Failed to update user-organisation', e);
    } catch (e) {
      throw Exception('Failed to update user-organisation: $e');
    }
  }

  /// Delete a user-organisation relationship
  Future<bool> deleteUserOrganisation(int id) async {
    if (id <= 0) {
      throw ArgumentError('UserOrganisation ID must be a positive integer');
    }

    try {
      await _apiClient.delete('user-organisations/$id/');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        //todo
        throw Exception('UserOrganisation with ID $id not found');
      }
      _handleApiException('Failed to delete user-organisation with ID $id', e);
    } catch (e) {
      throw Exception('Failed to delete user-organisation with ID $id: $e');
    }
  }

  /// Add a user to an organisation with a specific role
  Future<UserOrganisation> addUserToOrganisation(int userId, int organisationId,
      {int roleId = 6}) async {
    if (userId <= 0) {
      throw ArgumentError('User ID must be a positive integer');
    }
    if (organisationId <= 0) {
      throw ArgumentError('Organisation ID must be a positive integer');
    }
    if (roleId <= 0) {
      throw ArgumentError('Role ID must be a positive integer');
    }

    final userOrganisation = UserOrganisation(
      user: userId,
      organisation: organisationId,
      role: roleId,
    );

    return createUserOrganisation(userOrganisation);
  }

  /// Remove a user from an organisation
  Future<bool> removeUserFromOrganisation(
      int userId, int organisationId) async {
    if (userId <= 0) {
      throw ArgumentError('User ID must be a positive integer');
    }
    if (organisationId <= 0) {
      throw ArgumentError('Organisation ID must be a positive integer');
    }

    try {
      // First, find the user-organisation relationship
      final userOrganisations = await getUserOrganisationsByUserId(userId);
      final userOrg = userOrganisations.firstWhere(
        (uo) => uo.organisation == organisationId,
        orElse: () => throw Exception('User not found in organisation'),
      );

      // Delete the relationship
      return await deleteUserOrganisation(userOrg.id!);
    } catch (e) {
      throw Exception('Failed to remove user from organisation: $e');
    }
  }

  // Invitation methods

  /// Create an invitation to join an organisation
  Future<Map<String, dynamic>> createInvitation(
      int organisationId, String inviteCode, int roleId) async {
    if (organisationId <= 0) {
      throw ArgumentError('Organisation ID must be a positive integer');
    }
    if (inviteCode.isEmpty) {
      throw ArgumentError('Invite code cannot be empty');
    }
    if (roleId <= 0) {
      throw ArgumentError('Role ID must be a positive integer');
    }

    try {
      final fullResponse = await _apiClient.post(
        'invitations/',
        {
          'organisation': organisationId,
          'invite_code': inviteCode,
          'role': roleId,
        },
      );
      final response = fullResponse.data;
      return response;
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        //todo
        throw Exception('Invitation code already exists');
      }
      _handleApiException('Failed to create invitation', e);
    } catch (e) {
      throw Exception('Failed to create invitation: $e');
    }
  }

  /// Accept an invitation using the invite code
  Future<UserOrganisation> acceptInvitation(String inviteCode) async {
    if (inviteCode.isEmpty) {
      throw ArgumentError('Invite code cannot be empty');
    }

    try {
      final fullResponse = await _apiClient.post(
        'invitations/accept/',
        {'invite_code': inviteCode},
      );
      final response = fullResponse.data;
      return UserOrganisation.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        //todo
        throw Exception('Invalid or expired invitation code');
      }
      if (e.statusCode == 409) {
        throw Exception('User is already in this organisation');
      }
      _handleApiException('Failed to accept invitation', e);
    } catch (e) {
      throw Exception('Failed to accept invitation: $e');
    }
  }

  /// Get invitation details by code (without accepting)
  Future<Map<String, dynamic>> getInvitationDetails(String inviteCode) async {
    if (inviteCode.isEmpty) {
      throw ArgumentError('Invite code cannot be empty');
    }

    try {
      final fullResponse = await _apiClient.get('invitations/$inviteCode/');
      final response = fullResponse.data;
      return response;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        //todo
        throw Exception('Invalid or expired invitation code');
      }
      _handleApiException('Failed to get invitation details', e);
    } catch (e) {
      throw Exception('Failed to get invitation details: $e');
    }
  }

  /// Delete/revoke an invitation
  Future<bool> deleteInvitation(int invitationId) async {
    if (invitationId <= 0) {
      throw ArgumentError('Invitation ID must be a positive integer');
    }

    try {
      await _apiClient.delete('invitations/$invitationId/');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Invitation with ID $invitationId not found');
      }
      _handleApiException(
          'Failed to delete invitation with ID $invitationId', e);
    } catch (e) {
      throw Exception('Failed to delete invitation with ID $invitationId: $e');
    }
  }

  /// Handle API exceptions with appropriate logging and error propagation
  Never _handleApiException(String message, ApiException e) {
    final errorMessage = '$message: [${e.statusCode}] ${e.message}';
    throw Exception(errorMessage);
  }
}
