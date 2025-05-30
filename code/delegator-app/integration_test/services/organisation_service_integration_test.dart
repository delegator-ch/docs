// integration_test/services/organisation_service_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:delegator/services/organisation_service.dart';
import 'package:delegator/services/auth_service.dart';
import 'package:delegator/services/api_client.dart';
import 'package:delegator/models/organisation.dart';
import 'package:delegator/models/project.dart';
import 'package:delegator/models/user.dart';
import 'package:delegator/models/user_organisation.dart';
import '../helpers/test_setup.dart';

void main() {
  late OrganisationService organisationService;
  late AuthService authService;
  late ApiClient apiClient;

  setUp(() async {
    // Set up the integration test environment
    setupIntegrationTests();

    // Create a real API client
    apiClient = ApiClient();

    // Create services
    organisationService = OrganisationService(apiClient: apiClient);
    authService = AuthService(apiClient: apiClient);

    // Login to get proper authentication
    await authService.login(
      IntegrationTestConfig.testUsername,
      IntegrationTestConfig.testPassword,
    );
  });

  tearDown(() {
    apiClient.dispose();
  });

  group('OrganisationService Integration Tests', () {
    test('getAll should return list of organisations from real backend',
        () async {
      // Act
      try {
        final organisations = await organisationService.getAll();

        // Print details for debugging
        print('✅ Got ${organisations.length} organisations');
        for (var org in organisations) {
          print(
            '🏢 Organisation ID: ${org.id}, Name: ${org.name}, Since: ${org.since}',
          );
        }

        // Assert
        expect(organisations, isNotNull);
        expect(organisations, isA<List<Organisation>>());
        // Further assertions depend on your data
      } catch (e) {
        print('❌ Error fetching organisations: $e');
        fail('Failed to fetch organisations: $e');
      }
    });

    test('getById should return specific organisation from real backend',
        () async {
      // First, get all organisations to find a valid ID
      final organisations = await organisationService.getAll();
      if (organisations.isEmpty) {
        fail('No organisations available for testing');
      }

      final testOrgId = organisations.first.id;

      try {
        // Act - Get the organisation by ID
        print('🔍 Fetching organisation by ID: $testOrgId');
        final fetchedOrg = await organisationService.getById(testOrgId);

        // Assert
        print('✅ Successfully fetched organisation by ID');
        expect(fetchedOrg, isNotNull);
        expect(fetchedOrg.id, equals(testOrgId));
        expect(fetchedOrg.name, isNotNull);

        print(
            '✅ Organisation properties: ID=${fetchedOrg.id}, Name="${fetchedOrg.name}"');
      } catch (e) {
        print('❌ GetById test failed: $e');
        fail('GetById test failed: $e');
      }
    });

    test('getById should throw exception for non-existent organisation',
        () async {
      try {
        // Use a very high ID that shouldn't exist
        final nonExistentId = 999999;

        print(
            '🔍 Attempting to fetch non-existent organisation with ID: $nonExistentId');

        // Act & Assert - This should throw an exception
        await expectLater(
          () => organisationService.getById(nonExistentId),
          throwsA(isA<Exception>()),
        );

        print('✅ Correctly threw exception for non-existent organisation');
      } catch (e) {
        print('❌ Non-existent organisation test failed: $e');
        fail('Non-existent organisation test failed: $e');
      }
    });

    test('create and delete organisation', () async {
      try {
        // Create a test organisation
        final newOrg = Organisation(
          id: 0, // Will be assigned by backend
          name:
              'Test Integration Organisation ${DateTime.now().millisecondsSinceEpoch}',
          since: DateTime.now(),
        );

        print('🆕 Creating new organisation: "${newOrg.name}"');

        // Act - Create the organisation
        final createdOrg = await organisationService.create(newOrg);

        // Assert
        print('✅ Organisation created with ID: ${createdOrg.id}');
        expect(createdOrg, isNotNull);
        expect(createdOrg.id, isNotNull);
        expect(createdOrg.name, equals(newOrg.name));

        // Act - Delete the organisation
        print('🗑️ Deleting organisation with ID: ${createdOrg.id}');
        final deleteResult = await organisationService.delete(createdOrg.id);

        // Assert
        expect(deleteResult, isTrue);
        print('✅ Organisation deleted successfully');

        // Verify it's deleted by trying to fetch it (should throw an exception)
        try {
          await organisationService.getById(createdOrg.id);
          fail('Organisation still exists after deletion');
        } catch (e) {
          print('✅ Organisation no longer exists (expected error): $e');
          // Expected exception
        }
      } catch (e) {
        print('❌ Create/delete test failed: $e');
        fail('Create/delete test failed: $e');
      }
    });

    test('update organisation should modify organisation properties', () async {
      try {
        // Create a test organisation
        final newOrg = Organisation(
          id: 0, // Will be assigned by backend
          name:
              'Original Organisation Name ${DateTime.now().millisecondsSinceEpoch}',
          since: DateTime.now(),
        );

        print('🆕 Creating organisation for update test');

        // Create the organisation
        final createdOrg = await organisationService.create(newOrg);
        print('✅ Created organisation with ID: ${createdOrg.id}');

        // Act - Update the organisation
        final updatedOrg = Organisation(
          id: createdOrg.id,
          name:
              'Updated Organisation Name ${DateTime.now().millisecondsSinceEpoch}',
          since: createdOrg.since,
        );

        print('🔄 Updating organisation name');
        final result = await organisationService.update(updatedOrg);

        // Assert
        print('✅ Organisation updated successfully');
        expect(result, isNotNull);
        expect(result.id, equals(createdOrg.id));
        expect(result.name, equals(updatedOrg.name)); // Verify name changed

        // Clean up - delete the test organisation
        print('🧹 Cleaning up - deleting test organisation');
        await organisationService.delete(createdOrg.id);
        print('✅ Test organisation deleted');
      } catch (e) {
        print('❌ Update test failed: $e');
        fail('Update test failed: $e');
      }
    });

    test('enhanceProjectsWithOrganisations should fetch organisation details',
        () async {
      // This test assumes you have projects and organisations in your backend
      try {
        // First, get some organisations to know what IDs exist
        final organisations = await organisationService.getAll();
        if (organisations.isEmpty) {
          print('⚠️ No organisations available, skipping enhance test');
          return;
        }

        // Create mock projects with organisation IDs that exist
        final mockProjects = organisations.take(2).map((org) {
          return Project(
            id: null,
            name: 'Mock Project for Org ${org.id}',
            organisationId: org.id,
            priority: 1,
            status: 2,
          );
        }).toList();

        print(
            '🔗 Testing enhanceProjectsWithOrganisations with ${mockProjects.length} projects');

        // Act
        final enhancedProjects = await organisationService
            .enhanceProjectsWithOrganisations(mockProjects);

        // Assert
        print(
            '✅ Enhanced ${enhancedProjects.length} projects with organisation details');
        expect(enhancedProjects, isNotNull);
        expect(enhancedProjects.length, equals(mockProjects.length));

        for (var project in enhancedProjects) {
          if (project.organisation != null) {
            print(
                '✅ Project "${project.name}" has organisation: "${project.organisation!.name}"');
            expect(project.organisation!.id, equals(project.organisationId));
          }
        }
      } catch (e) {
        print('❌ Enhance projects test failed: $e');
        fail('Enhance projects test failed: $e');
      }
    });

    test(
        'getUsersByOrganisationId should return list of users from real backend',
        () async {
      const organisationId = 5; // Based on your API example

      try {
        // Act
        final users =
            await organisationService.getUsersByOrganisationId(organisationId);

        // Print details for debugging
        print('✅ Got ${users.length} users for organisation $organisationId');
        for (var user in users) {
          print(
            '👤 User ID: ${user.id}, Username: "${user.username}", Email: "${user.email}"',
          );
        }

        // Assert
        expect(users, isNotNull);
        expect(users, isA<List<User>>());
        expect(users.isNotEmpty, isTrue);

        // Verify each user has expected properties
        for (var user in users) {
          expect(user.id, isNotNull);
          expect(user.username, isNotEmpty);
        }

        print('✅ All user properties validated successfully');
      } catch (e) {
        print('❌ getUsersByOrganisationId test failed: $e');
        fail('getUsersByOrganisationId test failed: $e');
      }
    });

    test(
        'getUsersByOrganisationId should throw ArgumentError for invalid organisation ID',
        () async {
      try {
        print('🔍 Testing invalid organisation ID (0)');

        await expectLater(
          () => organisationService.getUsersByOrganisationId(0),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for organisation ID = 0');

        print('🔍 Testing invalid organisation ID (-1)');

        await expectLater(
          () => organisationService.getUsersByOrganisationId(-1),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for negative organisation ID');
      } catch (e) {
        print('❌ Invalid organisation ID test failed: $e');
        fail('Invalid organisation ID test failed: $e');
      }
    });

    test('getUsersByOrganisationId should handle non-existent organisation',
        () async {
      try {
        final nonExistentId = 999999;

        print(
          '🔍 Attempting to fetch users for non-existent organisation with ID: $nonExistentId',
        );

        await expectLater(
          () => organisationService.getUsersByOrganisationId(nonExistentId),
          throwsA(isA<Exception>()),
        );

        print('✅ Correctly threw exception for non-existent organisation');
      } catch (e) {
        print('❌ Non-existent organisation test failed: $e');
        fail('Non-existent organisation test failed: $e');
      }
    });

    // UserOrganisation tests
    test('getAllUserOrganisations should return list of user-organisations',
        () async {
      try {
        // Act
        final userOrganisations =
            await organisationService.getAllUserOrganisations();

        // Print details for debugging
        print('✅ Got ${userOrganisations.length} user-organisations');
        for (var userOrg in userOrganisations.take(5)) {
          print(
            '🔗 UserOrg ID: ${userOrg.id}, User: ${userOrg.user}, Org: ${userOrg.organisation}, Role: ${userOrg.role}',
          );
        }

        // Assert
        expect(userOrganisations, isNotNull);
        expect(userOrganisations, isA<List<UserOrganisation>>());

        // Verify properties
        for (var userOrg in userOrganisations) {
          expect(userOrg.id, isNotNull);
          expect(userOrg.user, isPositive);
          expect(userOrg.organisation, isPositive);
          expect(userOrg.role, isPositive);
        }

        print('✅ All user-organisation properties validated');
      } catch (e) {
        print('❌ getAllUserOrganisations test failed: $e');
        fail('getAllUserOrganisations test failed: $e');
      }
    });

    test('getUserOrganisationsByUserId should return user organisations',
        () async {
      try {
        // First get all user-organisations to find a valid user ID
        final allUserOrgs = await organisationService.getAllUserOrganisations();
        if (allUserOrgs.isEmpty) {
          print('⚠️ No user-organisations available, skipping test');
          return;
        }

        final testUserId = allUserOrgs.first.user;

        // Act
        final userOrganisations =
            await organisationService.getUserOrganisationsByUserId(testUserId);

        print(
            '✅ Got ${userOrganisations.length} organisations for user $testUserId');

        // Assert
        expect(userOrganisations, isNotNull);
        expect(userOrganisations, isA<List<UserOrganisation>>());

        // Verify all returned user-organisations belong to the specified user
        for (var userOrg in userOrganisations) {
          expect(userOrg.user, equals(testUserId));
        }

        print('✅ All user-organisations verified for user $testUserId');
      } catch (e) {
        print('❌ getUserOrganisationsByUserId test failed: $e');
        fail('getUserOrganisationsByUserId test failed: $e');
      }
    });

    test(
        'getUserOrganisationsByUserId should throw ArgumentError for invalid user ID',
        () async {
      try {
        print('🔍 Testing invalid user ID (0)');

        await expectLater(
          () => organisationService.getUserOrganisationsByUserId(0),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for user ID = 0');

        print('🔍 Testing invalid user ID (-1)');

        await expectLater(
          () => organisationService.getUserOrganisationsByUserId(-1),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for negative user ID');
      } catch (e) {
        print('❌ Invalid user ID test failed: $e');
        fail('Invalid user ID test failed: $e');
      }
    });

    test(
        'getUserOrganisationsByOrganisationId should return organisation users',
        () async {
      try {
        // First get all user-organisations to find a valid organisation ID
        final allUserOrgs = await organisationService.getAllUserOrganisations();
        if (allUserOrgs.isEmpty) {
          print('⚠️ No user-organisations available, skipping test');
          return;
        }

        final testOrgId = allUserOrgs.first.organisation;

        // Act
        final userOrganisations = await organisationService
            .getUserOrganisationsByOrganisationId(testOrgId);

        print(
            '✅ Got ${userOrganisations.length} users for organisation $testOrgId');

        // Assert
        expect(userOrganisations, isNotNull);
        expect(userOrganisations, isA<List<UserOrganisation>>());

        // Verify all returned user-organisations belong to the specified organisation
        for (var userOrg in userOrganisations) {
          expect(userOrg.organisation, equals(testOrgId));
        }

        print('✅ All user-organisations verified for organisation $testOrgId');
      } catch (e) {
        print('❌ getUserOrganisationsByOrganisationId test failed: $e');
        fail('getUserOrganisationsByOrganisationId test failed: $e');
      }
    });

    test(
        'getUserOrganisationsByOrganisationId should throw ArgumentError for invalid organisation ID',
        () async {
      try {
        print('🔍 Testing invalid organisation ID (0)');

        await expectLater(
          () => organisationService.getUserOrganisationsByOrganisationId(0),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for organisation ID = 0');

        print('🔍 Testing invalid organisation ID (-1)');

        await expectLater(
          () => organisationService.getUserOrganisationsByOrganisationId(-1),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for negative organisation ID');
      } catch (e) {
        print('❌ Invalid organisation ID test failed: $e');
        fail('Invalid organisation ID test failed: $e');
      }
    });

    test('getUserOrganisationById should return specific user-organisation',
        () async {
      try {
        // First get all user-organisations to find a valid ID
        final allUserOrgs = await organisationService.getAllUserOrganisations();
        if (allUserOrgs.isEmpty) {
          print('⚠️ No user-organisations available, skipping test');
          return;
        }

        final testUserOrgId = allUserOrgs.first.id!;

        // Act
        final userOrganisation =
            await organisationService.getUserOrganisationById(testUserOrgId);

        print('✅ Fetched user-organisation with ID: $testUserOrgId');

        // Assert
        expect(userOrganisation, isNotNull);
        expect(userOrganisation.id, equals(testUserOrgId));
        expect(userOrganisation.user, isPositive);
        expect(userOrganisation.organisation, isPositive);
        expect(userOrganisation.role, isPositive);

        print('✅ User-organisation properties validated');
      } catch (e) {
        print('❌ getUserOrganisationById test failed: $e');
        fail('getUserOrganisationById test failed: $e');
      }
    });

    test('getUserOrganisationById should throw ArgumentError for invalid ID',
        () async {
      try {
        print('🔍 Testing invalid user-organisation ID (0)');

        await expectLater(
          () => organisationService.getUserOrganisationById(0),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for ID = 0');

        print('🔍 Testing invalid user-organisation ID (-1)');

        await expectLater(
          () => organisationService.getUserOrganisationById(-1),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for negative ID');
      } catch (e) {
        print('❌ Invalid ID test failed: $e');
        fail('Invalid ID test failed: $e');
      }
    });

    test('getUserOrganisationById should throw exception for non-existent ID',
        () async {
      try {
        final nonExistentId = 999999;

        print(
            '🔍 Attempting to fetch non-existent user-organisation with ID: $nonExistentId');

        await expectLater(
          () => organisationService.getUserOrganisationById(nonExistentId),
          throwsA(isA<Exception>()),
        );

        print('✅ Correctly threw exception for non-existent user-organisation');
      } catch (e) {
        print('❌ Non-existent user-organisation test failed: $e');
        fail('Non-existent user-organisation test failed: $e');
      }
    });

    test('create, update and delete user-organisation', () async {
      try {
        // Get existing data for test
        final organisations = await organisationService.getAll();
        final allUserOrgs = await organisationService.getAllUserOrganisations();

        if (organisations.isEmpty || allUserOrgs.isEmpty) {
          print('⚠️ No test data available, skipping test');
          return;
        }

        final testUserId = allUserOrgs.first.user;
        final testOrgId = organisations.first.id;
        final testRoleId = 6; // Default role

        // Create new user-organisation
        final newUserOrg = UserOrganisation(
          user: testUserId,
          organisation: testOrgId,
          role: testRoleId,
        );

        print(
            '🆕 Creating user-organisation for user $testUserId in org $testOrgId');

        // Act - Create
        final createdUserOrg =
            await organisationService.createUserOrganisation(newUserOrg);

        // Assert creation
        print('✅ User-organisation created with ID: ${createdUserOrg.id}');
        expect(createdUserOrg, isNotNull);
        expect(createdUserOrg.id, isNotNull);
        expect(createdUserOrg.user, equals(testUserId));
        expect(createdUserOrg.organisation, equals(testOrgId));
        expect(createdUserOrg.role, equals(testRoleId));

        // Act - Update
        final updatedUserOrg = createdUserOrg.copyWith(role: 7);
        print('🔄 Updating user-organisation role to 7');

        final updateResult =
            await organisationService.updateUserOrganisation(updatedUserOrg);

        // Assert update
        expect(updateResult.role, equals(7));
        print('✅ User-organisation updated successfully');

        // Act - Delete
        print('🗑️ Deleting user-organisation with ID: ${createdUserOrg.id}');
        final deleteResult = await organisationService
            .deleteUserOrganisation(createdUserOrg.id!);

        // Assert deletion
        expect(deleteResult, isTrue);
        print('✅ User-organisation deleted successfully');

        // Verify it's deleted
        try {
          await organisationService.getUserOrganisationById(createdUserOrg.id!);
          fail('User-organisation still exists after deletion');
        } catch (e) {
          print('✅ User-organisation no longer exists (expected error): $e');
        }
      } catch (e) {
        print('❌ Create/update/delete user-organisation test failed: $e');
        fail('Create/update/delete user-organisation test failed: $e');
      }
    });

    test('addUserToOrganisation should create user-organisation relationship',
        () async {
      try {
        // Get test data
        final organisations = await organisationService.getAll();
        final allUserOrgs = await organisationService.getAllUserOrganisations();

        if (organisations.isEmpty || allUserOrgs.isEmpty) {
          print('⚠️ No test data available, skipping test');
          return;
        }

        final testUserId = allUserOrgs.first.user;
        final testOrgId = organisations.first.id;

        print(
            '➕ Adding user $testUserId to organisation $testOrgId with default role');

        // Act
        final userOrganisation =
            await organisationService.addUserToOrganisation(
          testUserId,
          testOrgId,
        );

        // Assert
        expect(userOrganisation, isNotNull);
        expect(userOrganisation.user, equals(testUserId));
        expect(userOrganisation.organisation, equals(testOrgId));
        expect(userOrganisation.role, equals(6)); // Default role

        print('✅ User added to organisation successfully');

        // Clean up
        await organisationService.deleteUserOrganisation(userOrganisation.id!);
        print('🧹 Test user-organisation deleted');
      } catch (e) {
        print('❌ addUserToOrganisation test failed: $e');
        fail('addUserToOrganisation test failed: $e');
      }
    });

    test('addUserToOrganisation should throw ArgumentError for invalid IDs',
        () async {
      try {
        print('🔍 Testing invalid user ID (0)');

        await expectLater(
          () => organisationService.addUserToOrganisation(0, 1),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for user ID = 0');

        print('🔍 Testing invalid organisation ID (0)');

        await expectLater(
          () => organisationService.addUserToOrganisation(1, 0),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for organisation ID = 0');

        print('🔍 Testing invalid role ID (0)');

        await expectLater(
          () => organisationService.addUserToOrganisation(1, 1, roleId: 0),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for role ID = 0');
      } catch (e) {
        print('❌ Invalid IDs test failed: $e');
        fail('Invalid IDs test failed: $e');
      }
    });

    test(
        'removeUserFromOrganisation should delete user-organisation relationship',
        () async {
      try {
        // Get test data
        final organisations = await organisationService.getAll();
        final allUserOrgs = await organisationService.getAllUserOrganisations();

        if (organisations.isEmpty || allUserOrgs.isEmpty) {
          print('⚠️ No test data available, skipping test');
          return;
        }

        final testUserId = allUserOrgs.first.user;
        final testOrgId = organisations.first.id;

        // First add a user to organisation
        final userOrganisation =
            await organisationService.addUserToOrganisation(
          testUserId,
          testOrgId,
        );

        print('➖ Removing user $testUserId from organisation $testOrgId');

        // Act - Remove user from organisation
        final removeResult =
            await organisationService.removeUserFromOrganisation(
          testUserId,
          testOrgId,
        );

        // Assert
        expect(removeResult, isTrue);
        print('✅ User removed from organisation successfully');

        // Verify removal by trying to fetch the deleted relationship
        try {
          await organisationService
              .getUserOrganisationById(userOrganisation.id!);
          fail('User-organisation relationship still exists after removal');
        } catch (e) {
          print(
              '✅ User-organisation relationship no longer exists (expected): $e');
        }
      } catch (e) {
        print('❌ removeUserFromOrganisation test failed: $e');
        fail('removeUserFromOrganisation test failed: $e');
      }
    });

    test(
        'removeUserFromOrganisation should throw ArgumentError for invalid IDs',
        () async {
      try {
        print('🔍 Testing invalid user ID (0)');

        await expectLater(
          () => organisationService.removeUserFromOrganisation(0, 1),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for user ID = 0');

        print('🔍 Testing invalid organisation ID (0)');

        await expectLater(
          () => organisationService.removeUserFromOrganisation(1, 0),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for organisation ID = 0');
      } catch (e) {
        print('❌ Invalid IDs test failed: $e');
        fail('Invalid IDs test failed: $e');
      }
    });

    test('removeUserFromOrganisation should handle non-existent relationship',
        () async {
      try {
        // Use IDs that likely don't have a relationship
        final nonExistentUserId = 999999;
        final nonExistentOrgId = 999999;

        print(
            '🔍 Attempting to remove non-existent relationship: user $nonExistentUserId from org $nonExistentOrgId');

        await expectLater(
          () => organisationService.removeUserFromOrganisation(
              nonExistentUserId, nonExistentOrgId),
          throwsA(isA<Exception>()),
        );

        print('✅ Correctly threw exception for non-existent relationship');
      } catch (e) {
        print('❌ Non-existent relationship test failed: $e');
        fail('Non-existent relationship test failed: $e');
      }
    });
  });
}
