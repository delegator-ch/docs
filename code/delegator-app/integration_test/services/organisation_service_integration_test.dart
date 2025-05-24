// integration_test/services/organisation_service_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:delegator/services/organisation_service.dart';
import 'package:delegator/services/auth_service.dart';
import 'package:delegator/services/api_client.dart';
import 'package:delegator/models/organisation.dart';
import 'package:delegator/models/project.dart';
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
  });
}
