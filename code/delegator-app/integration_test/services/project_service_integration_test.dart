// integration_test/services/project_service_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:delegator/services/project_service.dart';
import 'package:delegator/services/auth_service.dart';
import 'package:delegator/models/api_client.dart';
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

    // Add this test to your existing project_service_integration_test.dart file
// within the 'ProjectService Integration Tests' group

    test('getById should return specific project from real backend', () async {
      // First, create a project to ensure we have one to fetch
      final organisationId = 5; // Based on your existing test pattern

      try {
        // Create a test project first
        final newProject = Project(
          organisationId: organisationId,
          name: 'Test Project for GetById',
          priority: 1,
        );

        print('🆕 Creating project for getById test');
        final createdProject = await projectService.create(newProject);
        print('✅ Created project with ID: ${createdProject.id}');

        // Act - Get the project by ID
        print('🔍 Fetching project by ID: ${createdProject.id}');
        final fetchedProject = await projectService.getById(createdProject.id!);

        // Assert
        print('✅ Successfully fetched project by ID');
        expect(fetchedProject, isNotNull);
        expect(fetchedProject.id, equals(createdProject.id));
        expect(fetchedProject.name, equals('Test Project for GetById'));
        expect(fetchedProject.organisationId, equals(organisationId));
        expect(fetchedProject.priority, equals(1));

        print('✅ All project properties match expected values');

        // Clean up - delete the test project
        print('🧹 Cleaning up - deleting test project');
        await projectService.delete(createdProject.id!);
        print('✅ Test project deleted');
      } catch (e) {
        print('❌ GetById test failed: $e');
        fail('GetById test failed: $e');
      }
    });

    test('getById should throw exception for non-existent project', () async {
      try {
        // Use a very high ID that shouldn't exist
        final nonExistentId = 999999;

        print(
            '🔍 Attempting to fetch non-existent project with ID: $nonExistentId');

        // Act & Assert - This should throw an exception
        await expectLater(
          () => projectService.getById(nonExistentId),
          throwsA(isA<Exception>()),
        );

        print('✅ Correctly threw exception for non-existent project');
      } catch (e) {
        print('❌ Non-existent project test failed: $e');
        fail('Non-existent project test failed: $e');
      }
    });

    test('getById should throw ArgumentError for invalid ID', () async {
      try {
        print('🔍 Testing invalid ID (0)');

        // Act & Assert - This should throw an ArgumentError
        await expectLater(
          () => projectService.getById(0),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for ID = 0');

        print('🔍 Testing invalid ID (-1)');

        // Act & Assert - This should also throw an ArgumentError
        await expectLater(
          () => projectService.getById(-1),
          throwsA(isA<ArgumentError>()),
        );

        print('✅ Correctly threw ArgumentError for negative ID');
      } catch (e) {
        print('❌ Invalid ID test failed: $e');
        fail('Invalid ID test failed: $e');
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
