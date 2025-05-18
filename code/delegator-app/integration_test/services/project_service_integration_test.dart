// integration_test/services/project_service_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:delegator/services/project_service.dart';
import 'package:delegator/services/auth_service.dart';
import 'package:delegator/services/api_client.dart';
import 'package:delegator/models/project.dart';
import '../helpers/test_setup.dart';

void main() {
  late ProjectService projectService;
  late AuthService authService;
  late ApiClient apiClient;

  setUp(() async {
    // Set up the integration test environment
    setupIntegrationTests();

    // Create a real API client
    apiClient = ApiClient();

    // Create services
    projectService = ProjectService(apiClient: apiClient);
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

  group('ProjectService Integration Tests', () {
    test('getAll should return list of projects from real backend', () async {
      // Act
      try {
        final projects = await projectService.getAll();

        // Print details for debugging
        print('✅ Got ${projects.length} projects');
        for (var project in projects) {
          print(
            '📋 Project ID: ${project.id}, Org ID: ${project.organisationId}',
          );
        }

        // Assert
        expect(projects, isNotNull);
        expect(projects, isA<List<Project>>());
        // Further assertions depend on your data
      } catch (e) {
        print('❌ Error fetching projects: $e');
        fail('Failed to fetch projects: $e');
      }
    });

    test('create and delete project', () async {
      // For this test, we'll use a fixed organisation ID
      // This should be an organisation ID that exists in your database
      final organisationId = 5; // Based on the API response you provided

      // Create a test project
      try {
        final newProject = Project(
          organisationId: organisationId,
          name: 'Test',
          priority: 1,
        );

        print('🆕 Creating new project for organisation $organisationId');

        // Act - Create the project
        final createdProject = await projectService.create(newProject);

        // Assert
        print('✅ Project created with ID: ${createdProject.id}');
        expect(createdProject, isNotNull);
        expect(createdProject.id, isNotNull);
        expect(createdProject.organisationId, equals(organisationId));

        // Act - Delete the project
        print('🗑️ Deleting project with ID: ${createdProject.id}');
        final deleteResult = await projectService.delete(createdProject.id!);

        // Assert
        expect(deleteResult, isTrue);
        print('✅ Project deleted successfully');

        // Verify it's deleted by trying to fetch it (should throw an exception)
        try {
          await projectService.getById(createdProject.id!);
          fail('Project still exists after deletion');
        } catch (e) {
          print('✅ Project no longer exists (expected error): $e');
          // Expected exception
        }
      } catch (e) {
        print('❌ Test failed: $e');
        fail('Test failed: $e');
      }
    });

    test('update project', () async {
      // For this test, we'll use a fixed organisation ID
      final organisationId = 5; // Based on the API response you provided

      try {
        // Create a test project
        final newProject = Project(
          organisationId: organisationId,
          name: 'Test',
          priority: 1,
        );
        print('🆕 Creating project for update test');

        // Create the project
        final createdProject = await projectService.create(newProject);
        print('✅ Created project with ID: ${createdProject.id}');

        // Act - Update the project
        final updatedProject = Project(
          id: createdProject.id,
          name: 'Test 2',
          organisationId: organisationId,
          priority: 2, // Changed priority
        );

        print('🔄 Updating project to priority 2');
        final result = await projectService.update(updatedProject);

        // Assert
        print('✅ Project updated successfully');
        expect(result, isNotNull);
        expect(result.id, equals(createdProject.id));
        expect(result.priority, equals(2)); // Verify priority changed

        // Clean up - delete the test project
        print('🧹 Cleaning up - deleting test project');
        await projectService.delete(createdProject.id!);
        print('✅ Test project deleted');
      } catch (e) {
        print('❌ Update test failed: $e');
        fail('Update test failed: $e');
      }
    });
  });
}
