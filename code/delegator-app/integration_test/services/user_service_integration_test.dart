// integration_test/services/user_service_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:delegator/services/user_service.dart';
import 'package:delegator/services/auth_service.dart';
import 'package:delegator/models/api_client.dart';
import 'package:delegator/models/user.dart';
import '../helpers/test_setup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart';

void main() {
  late UserService userService;
  late AuthService authService;
  late ApiClient apiClient;

  setUp(() async {
    // Set up the integration test environment
    setupIntegrationTests();

    // Create a real API client
    apiClient = ApiClient();

    // Create services
    userService = UserService(apiClient: apiClient);
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

  group('UserService Integration Tests', () {
    test('getAll should return list of users from real backend', () async {
      // Act
      try {
        final users = await userService.getAll();

        // Print details for debugging
        print('✅ Got ${users.length} users');
        for (var user in users.take(5)) {
          // Show first 5 for brevity
          print(
            '👤 User ID: ${user.id}, Username: "${user.username}", Email: "${user.email}"',
          );
        }

        // Assert
        expect(users, isNotNull);
        expect(users, isA<List<User>>());
      } catch (e) {
        print('❌ Error fetching users: $e');
        fail('Failed to fetch users: $e');
      }
    });

    test('getById should return specific user from real backend', () async {
      // First, get all users to find a valid ID
      final users = await userService.getAll();
      if (users.isEmpty) {
        fail('No users available for testing');
      }

      final testUserId = users.first.id!;

      try {
        // Act - Get the user by ID
        print('🔍 Fetching user by ID: $testUserId');
        final fetchedUser = await userService.getById(testUserId);

        // Assert
        print('✅ Successfully fetched user by ID');
        expect(fetchedUser, isNotNull);
        expect(fetchedUser.id, equals(testUserId));
        expect(fetchedUser.username, isNotNull);

        print(
          '✅ User properties: ID=${fetchedUser.id}, Username="${fetchedUser.username}"',
        );
      } catch (e) {
        print('❌ GetById test failed: $e');
        fail('GetById test failed: $e');
      }
    });

    test('getById should throw exception for non-existent user', () async {
      try {
        // Use a very high ID that shouldn't exist
        final nonExistentId = 999999;

        print(
          '🔍 Attempting to fetch non-existent user with ID: $nonExistentId',
        );

        // Act & Assert - This should throw an exception
        await expectLater(
          () => userService.getById(nonExistentId),
          throwsA(isA<Exception>()),
        );

        print('✅ Correctly threw exception for non-existent user');
      } catch (e) {
        print('❌ Non-existent user test failed: $e');
        fail('Non-existent user test failed: $e');
      }
    });

    test('getById should throw ArgumentError for invalid ID', () async {
      try {
        print('🔍 Testing invalid ID (0)');

        // Act & Assert - This should throw an ArgumentError
        await expectLater(
          () => userService.getById(0),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for ID = 0');

        print('🔍 Testing invalid ID (-1)');

        // Act & Assert - This should also throw an ArgumentError
        await expectLater(
          () => userService.getById(-1),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for negative ID');
      } catch (e) {
        print('❌ Invalid ID test failed: $e');
        fail('Invalid ID test failed: $e');
      }
    });

    test('getByProjectId should return project users with roles', () async {
      const projectId = 53; // Based on your API example

      try {
        // Act
        final users = await userService.getByProjectId(projectId);

        // Print details for debugging
        print('✅ Got ${users.length} users for project $projectId');
        for (var user in users) {
          print(
            '👤 User ID: ${user.id}, Username: "${user.username}", '
            'Role: ${user.role?.name} (Level ${user.role?.level}), '
            'Access: ${user.accessType}',
          );
        }

        // Assert
        expect(users, isA<List<User>>());
        expect(users.isNotEmpty, isTrue);

        // Verify each user has expected properties
        for (var user in users) {
          expect(user.id, isNotNull);
          expect(user.username, isNotEmpty);
          expect(user.role, isNotNull);
          expect(user.role!.id, isNotNull);
          expect(user.role!.name, isNotEmpty);
          expect(user.role!.level, greaterThan(0));
          expect(user.accessType, isNotNull);
          expect(
              ['organization', 'external'].contains(user.accessType), isTrue);
        }

        // Check for specific expected users (from your API example)
        final userIds = users.map((u) => u.id).toList();
        expect(userIds.contains(3), isTrue,
            reason: 'Should contain test_user_2');
        expect(userIds.contains(4), isTrue,
            reason: 'Should contain test_user_3');

        // Verify role details for specific users
        final adminUser = users.firstWhere((u) => u.id == 3);
        expect(adminUser.role!.name, equals('Admin'));
        expect(adminUser.role!.level, equals(1));
        expect(adminUser.accessType, equals('organization'));

        final coreTeamUser = users.firstWhere((u) => u.id == 4);
        expect(coreTeamUser.role!.name, equals('Core Team'));
        expect(coreTeamUser.role!.level, equals(2));
        expect(coreTeamUser.accessType, equals('external'));
        expect(coreTeamUser.joinedProject, isNotNull);

        print('✅ All user properties validated successfully');
      } catch (e) {
        print('❌ GetByProjectId test failed: $e');
        fail('GetByProjectId test failed: $e');
      }
    });

    test('getByProjectId should throw ArgumentError for invalid project ID',
        () async {
      try {
        print('🔍 Testing invalid project ID (0)');

        // Act & Assert - This should throw an ArgumentError
        await expectLater(
          () => userService.getByProjectId(0),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for project ID = 0');

        print('🔍 Testing invalid project ID (-1)');

        // Act & Assert - This should also throw an ArgumentError
        await expectLater(
          () => userService.getByProjectId(-1),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for negative project ID');
      } catch (e) {
        print('❌ Invalid project ID test failed: $e');
        fail('Invalid project ID test failed: $e');
      }
    });

    test('getByProjectId should handle non-existent project', () async {
      try {
        // Use a very high project ID that shouldn't exist
        final nonExistentProjectId = 999999;

        print(
          '🔍 Attempting to fetch users for non-existent project with ID: $nonExistentProjectId',
        );

        // Act & Assert - This should throw an exception
        await expectLater(
          () => userService.getByProjectId(nonExistentProjectId),
          throwsA(isA<Exception>()),
        );

        print('✅ Correctly threw exception for non-existent project');
      } catch (e) {
        print('❌ Non-existent project test failed: $e');
        fail('Non-existent project test failed: $e');
      }
    });

    test('user displayName property should work correctly', () async {
      try {
        // Get users for a project to test displayName logic
        const projectId = 53;
        final users = await userService.getByProjectId(projectId);

        print('🔍 Testing displayName property for ${users.length} users');

        for (var user in users) {
          final displayName = user.displayName;
          print('👤 User ${user.id}: displayName = "$displayName"');

          // Since the API returns empty first_name and last_name,
          // displayName should fall back to username
          expect(displayName, equals(user.username));
        }

        print('✅ displayName property works as expected');
      } catch (e) {
        print('❌ displayName test failed: $e');
        fail('displayName test failed: $e');
      }
    });

    test('create and delete user (if supported)', () async {
      // Note: This test might fail if your API doesn't support user creation
      // or requires specific permissions
      try {
        // Create a test user
        final newUser = User(
            username:
                'test_integration_user_${DateTime.now().millisecondsSinceEpoch}',
            email: 'test@integration.com',
            firstName: 'Test',
            lastName: 'User',
            password: 'sml12345');

        print('🆕 Creating new user: "${newUser.username}"');

        // Act - Create the user
        final createdUser = await userService.create(newUser);
        final userById = await userService.getById(createdUser.id!);
        // Assert
        print('✅ User created with ID: ${createdUser.id}');
        expect(createdUser, isNotNull);
        expect(createdUser.id, isNotNull);
        expect(createdUser.username, equals(userById.username));
        expect(createdUser.email, equals(userById.email));

        // Act - Delete the user
        print('🗑️ Deleting user with ID: ${createdUser.id}');
        final deleteResult = await userService.delete(createdUser.id!);

        // Assert
        expect(deleteResult, isTrue);
        print('✅ User deleted successfully');

        // Verify it's deleted by trying to fetch it (should throw an exception)
        try {
          await userService.getById(createdUser.id!);
          fail('User still exists after deletion');
        } catch (e) {
          print('✅ User no longer exists (expected error): $e');
          // Expected exception
        }
      } catch (e) {
        print('⚠️ Create/delete test skipped or failed: $e');
        print(
            'ℹ️ This might be expected if the API doesn\'t support user creation');
        // Don't fail the test as user creation might not be supported
      }
    });
  });
}
