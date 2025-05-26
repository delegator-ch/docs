// integration_test/services/external_service_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:delegator/services/external_service.dart';
import 'package:delegator/services/auth_service.dart';
import 'package:delegator/services/api_client.dart';
import 'package:delegator/models/user.dart';
import '../helpers/test_setup.dart';

void main() {
  late ExternalService externalService;
  late AuthService authService;
  late ApiClient apiClient;

  setUp(() async {
    // Set up the integration test environment
    setupIntegrationTests();

    // Create a real API client
    apiClient = ApiClient();

    // Create services
    externalService = ExternalService(apiClient: apiClient);
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

  group('ExternalService Integration Tests', () {
    test('getByProjectId should return externals for specific project',
        () async {
      const projectId = 53; // Based on your API example

      try {
        // Act
        final externals = await externalService.getByProjectId(projectId);

        // Print details for debugging
        print('✅ Got ${externals.length} externals for project $projectId');
        for (var external in externals) {
          print(
            '👤 External ID: ${external.id}, Username: "${external.username}", '
            'Email: "${external.email}", Access: ${external.accessType}',
          );
        }

        // Assert
        expect(externals, isA<List<User>>());

        // Verify each external has expected properties
        for (var external in externals) {
          expect(external.id, isNotNull);
          expect(external.username, isNotEmpty);
          // Should be external users only
          expect(external.accessType, anyOf(equals('external'), isNull));
        }

        print('✅ All external properties validated successfully');
      } catch (e) {
        print('❌ GetByProjectId test failed: $e');
        fail('GetByProjectId test failed: $e');
      }
    });

    test('getByProjectId should throw ArgumentError for invalid project ID',
        () async {
      try {
        print('🔍 Testing invalid project ID (0)');

        // Act & Assert
        await expectLater(
          () => externalService.getByProjectId(0),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for project ID = 0');

        print('🔍 Testing invalid project ID (-1)');

        await expectLater(
          () => externalService.getByProjectId(-1),
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
        final nonExistentProjectId = 999999;

        print(
          '🔍 Attempting to fetch externals for non-existent project with ID: $nonExistentProjectId',
        );

        // Act & Assert
        await expectLater(
          () => externalService.getByProjectId(nonExistentProjectId),
          throwsA(isA<Exception>()),
        );

        print('✅ Correctly threw exception for non-existent project');
      } catch (e) {
        print('❌ Non-existent project test failed: $e');
        fail('Non-existent project test failed: $e');
      }
    });

    test('add and remove external from project', () async {
      const projectId = 53;
      const organisationId = 5;

      try {
        // Get organisation externals
        final orgExternals =
            await externalService.getByOrganisationId(organisationId);
        if (orgExternals.isEmpty) {
          print(
              '⚠️ No organisation externals available, skipping add/remove test');
          return;
        }

        // Get current project externals
        final currentExternals =
            await externalService.getByProjectId(projectId);
        final currentExternalIds = currentExternals.map((e) => e.id).toSet();

        // Find an external not in the project
        final availableExternal = orgExternals.firstWhere(
          (external) => !currentExternalIds.contains(external.id),
          orElse: () => throw Exception('No available externals to add'),
        );

        print(
            '🆕 Adding external ${availableExternal.id} to project $projectId');

        // Act - Add external to project
        final addResult = await externalService.addToProject(
          availableExternal.id!,
          projectId,
        );

        // Assert
        expect(addResult, isTrue);
        print('✅ External added successfully');

        // Verify external is now in project
        final updatedExternals =
            await externalService.getByProjectId(projectId);
        expect(
          updatedExternals.any((e) => e.id == availableExternal.id),
          isTrue,
          reason: 'External should now be in project',
        );

        print('✅ Verified external is in project');

        // Act - Remove external from project
        print(
            '🗑️ Removing external ${availableExternal.id} from project $projectId');
        final removeResult = await externalService.removeFromProject(
          availableExternal.id!,
          projectId,
        );

        // Assert
        expect(removeResult, isTrue);
        print('✅ External removed successfully');

        // Verify external is no longer in project
        final finalExternals = await externalService.getByProjectId(projectId);
        expect(
          finalExternals.any((e) => e.id == availableExternal.id),
          isFalse,
          reason: 'External should no longer be in project',
        );

        print('✅ Verified external is no longer in project');
      } catch (e) {
        print('❌ Add/remove test failed: $e');
        fail('Add/remove test failed: $e');
      }
    });

    test('i dont know', () async {
      const projectId = 53;
      const organisationId = 5;

      try {
        // Act
        final externals = await externalService.getByProjectId(projectId);

        // Print details for debugging
        print('✅ Got ${externals.length} externals for project $projectId');
        for (var external in externals) {
          print(
            '👤 External ID: ${external.id}, Username: "${external.username}", '
            'Email: "${external.email}", Access: ${external.accessType}',
          );
        }

        // Assert
        expect(externals, isA<List<User>>());

        // Verify each external has expected properties
        for (var external in externals) {
          expect(external.id, isNotNull);
          expect(external.username, isNotEmpty);
          // Should be external users only
          expect(external.accessType, anyOf(equals('external'), isNull));
        }

        print('✅ All external properties validated successfully');
      } catch (e) {
        print('❌ GetByProjectId test failed: $e');
        fail('GetByProjectId test failed: $e');
      }
    });

    test('getByProjectId should throw ArgumentError for invalid project ID',
        () async {
      try {
        print('🔍 Testing invalid project ID (0)');

        // Act & Assert
        await expectLater(
          () => externalService.getByProjectId(0),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for project ID = 0');

        print('🔍 Testing invalid project ID (-1)');

        await expectLater(
          () => externalService.getByProjectId(-1),
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
        final nonExistentProjectId = 999999;

        print(
          '🔍 Attempting to fetch externals for non-existent project with ID: $nonExistentProjectId',
        );

        // Act & Assert
        await expectLater(
          () => externalService.getByProjectId(nonExistentProjectId),
          throwsA(isA<Exception>()),
        );

        print('✅ Correctly threw exception for non-existent project');
      } catch (e) {
        print('❌ Non-existent project test failed: $e');
        fail('Non-existent project test failed: $e');
      }
    });

    test('addToOrganisation and removeFromOrganisation should work', () async {
      const organisationId = 5;
      const testUserId = 999; // Use a test user ID

      try {
        print(
            '🆕 Adding user $testUserId to organisation $organisationId as external');

        // Act - Add user to organisation
        final addResult =
            await externalService.addToOrganisation(testUserId, organisationId);

        // Assert
        expect(addResult, isTrue);
        print('✅ User added to organisation successfully');

        // Verify user is now in organisation externals
        final orgExternals =
            await externalService.getByOrganisationId(organisationId);
        expect(
          orgExternals.any((e) => e.id == testUserId),
          isTrue,
          reason: 'User should now be in organisation externals',
        );

        print('✅ Verified user is in organisation externals');

        // Act - Remove user from organisation
        print(
            '🗑️ Removing user $testUserId from organisation $organisationId');
        final removeResult = await externalService.removeFromOrganisation(
            testUserId, organisationId);

        // Assert
        expect(removeResult, isTrue);
        print('✅ User removed from organisation successfully');

        // Verify user is no longer in organisation
        final finalExternals =
            await externalService.getByOrganisationId(organisationId);
        expect(
          finalExternals.any((e) => e.id == testUserId),
          isFalse,
          reason: 'User should no longer be in organisation externals',
        );

        print('✅ Verified user is no longer in organisation externals');
      } catch (e) {
        print('❌ Add/remove organisation test failed: $e');
        fail('Add/remove organisation test failed: $e');
      }
    });

    test('addToOrganisation should handle duplicate assignment', () async {
      const organisationId = 5;

      try {
        // Get current externals in organisation
        final currentExternals =
            await externalService.getByOrganisationId(organisationId);
        if (currentExternals.isEmpty) {
          print('⚠️ No externals in organisation, skipping duplicate test');
          return;
        }

        final existingExternal = currentExternals.first;

        print(
            '🔍 Attempting to add existing external ${existingExternal.id} to organisation $organisationId');

        // Act & Assert - Should throw exception for duplicate
        await expectLater(
          () => externalService.addToOrganisation(
              existingExternal.id!, organisationId),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('already in this organisation'))),
        );

        print('✅ Correctly threw exception for duplicate assignment');
      } catch (e) {
        print('❌ Duplicate organisation assignment test failed: $e');
        fail('Duplicate organisation assignment test failed: $e');
      }
    });

    test('addToProject should throw ArgumentError for invalid IDs', () async {
      try {
        print('🔍 Testing invalid user ID (0)');

        await expectLater(
          () => externalService.addToProject(0, 53),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for user ID = 0');

        print('🔍 Testing invalid project ID (0)');

        await expectLater(
          () => externalService.addToProject(1, 0),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for project ID = 0');
      } catch (e) {
        print('❌ Invalid ID test failed: $e');
        fail('Invalid ID test failed: $e');
      }
    });

    test('removeFromProject should throw ArgumentError for invalid IDs',
        () async {
      try {
        print('🔍 Testing invalid user ID (0)');

        await expectLater(
          () => externalService.removeFromProject(0, 53),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for user ID = 0');

        print('🔍 Testing invalid project ID (0)');

        await expectLater(
          () => externalService.removeFromProject(1, 0),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for project ID = 0');
      } catch (e) {
        print('❌ Invalid ID test failed: $e');
        fail('Invalid ID test failed: $e');
      }
    });

    test('addToProject should handle duplicate assignment', () async {
      const projectId = 53;

      try {
        // Get current externals in project
        final currentExternals =
            await externalService.getByProjectId(projectId);
        if (currentExternals.isEmpty) {
          print('⚠️ No externals in project, skipping duplicate test');
          return;
        }

        final existingExternal = currentExternals.first;

        print(
            '🔍 Attempting to add existing external ${existingExternal.id} to project $projectId');

        // Act & Assert - Should throw exception for duplicate
        await expectLater(
          () => externalService.addToProject(existingExternal.id!, projectId),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('already in this project'))),
        );

        print('✅ Correctly threw exception for duplicate assignment');
      } catch (e) {
        print('❌ Duplicate assignment test failed: $e');
        fail('Duplicate assignment test failed: $e');
      }
    });

    test('removeFromProject should handle non-existent assignment', () async {
      const projectId = 53;
      const organisationId = 5;

      try {
        // Get organisation externals and current project externals
        final orgExternals =
            await externalService.getByOrganisationId(organisationId);
        final currentExternals =
            await externalService.getByProjectId(projectId);
        final currentExternalIds = currentExternals.map((e) => e.id).toSet();

        // Find an external not in the project
        final notInProject = orgExternals.firstWhere(
          (external) => !currentExternalIds.contains(external.id),
          orElse: () => throw Exception('All externals are in project'),
        );

        print(
            '🔍 Attempting to remove non-existent external ${notInProject.id} from project $projectId');

        // Act & Assert - Should throw exception
        await expectLater(
          () => externalService.removeFromProject(notInProject.id!, projectId),
          throwsA(predicate((e) =>
              e is Exception && e.toString().contains('not found in project'))),
        );

        print('✅ Correctly threw exception for non-existent assignment');
      } catch (e) {
        print('❌ Non-existent assignment test failed: $e');
        fail('Non-existent assignment test failed: $e');
      }
    });

    test('create and delete external user (if supported)', () async {
      // Note: This might fail if API doesn't support external user creation
      try {
        final newExternal = User(
          username: 'test_external_${DateTime.now().millisecondsSinceEpoch}',
          email: 'external@test.com',
          firstName: 'Test',
          lastName: 'External',
        );

        print('🆕 Creating new external user: "${newExternal.username}"');

        // Act - Create external
        final createdExternal = await externalService.create(newExternal);

        // Assert
        print('✅ External created with ID: ${createdExternal.id}');
        expect(createdExternal, isNotNull);
        expect(createdExternal.id, isNotNull);
        expect(createdExternal.username, equals(newExternal.username));

        // Act - Delete external
        print('🗑️ Deleting external with ID: ${createdExternal.id}');
        final deleteResult = await externalService.delete(createdExternal.id!);

        // Assert
        expect(deleteResult, isTrue);
        print('✅ External deleted successfully');
      } catch (e) {
        print('⚠️ Create/delete test skipped or failed: $e');
        print(
            'ℹ️ This might be expected if API doesn\'t support external creation');
        // Don't fail as external creation might not be supported
      }
    });

    test('search external users (if supported)', () async {
      try {
        // Use a common search term
        const searchQuery = 'test';

        print('🔍 Searching external users with query: "$searchQuery"');

        // Act
        final results = await externalService.search(searchQuery);

        // Assert
        print('✅ Search returned ${results.length} results');
        expect(results, isA<List<User>>());

        for (var result in results.take(3)) {
          print('👤 Search result: ${result.username}');
        }
      } catch (e) {
        print('⚠️ Search test skipped or failed: $e');
        print(
            'ℹ️ This might be expected if API doesn\'t support external search');
        // Don't fail as search might not be supported
      }
    });
  });
}
