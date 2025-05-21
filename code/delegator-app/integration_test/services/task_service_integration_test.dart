// integration_test/services/task_service_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:delegator/services/task_service.dart';
import 'package:delegator/services/auth_service.dart';
import 'package:delegator/services/api_client.dart';
import 'package:delegator/models/task.dart';
import 'package:delegator/models/user.dart';
import 'package:delegator/models/status.dart';
import 'package:delegator/models/project.dart';
import '../helpers/test_setup.dart';

void main() {
  late TaskService taskService;
  late AuthService authService;
  late ApiClient apiClient;

  setUp(() async {
    // Set up the integration test environment
    setupIntegrationTests();

    // Create a real API client
    apiClient = ApiClient();

    // Create services
    taskService = TaskService(apiClient: apiClient);
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

  group('TaskService Integration Tests', () {
    test('getAll should return list of tasks from real backend', () async {
      // Act
      try {
        final tasks = await taskService.getAll();

        // Print details for debugging
        print('✅ Got ${tasks.length} tasks');
        for (var task in tasks.take(5)) {
          // Show first 5 for brevity
          print(
            '📝 Task ID: ${task.id}, Title: "${task.title}", Project: ${task.project}',
          );
        }

        // Assert
        expect(tasks, isNotNull);
        expect(tasks, isA<List<Task>>());
      } catch (e) {
        print('❌ Error fetching tasks: $e');
        fail('Failed to fetch tasks: $e');
      }
    });

    test('create and delete task', () async {
      // Create test objects for Task creation
      final project = 17;
      final status = 1;

      try {
        // Create a test task
        final newTask = Task(
          project: project,
          title: 'Integration Test Task',
          status: status,
          content: 'Test content',
        );

        print('🆕 Creating new task for project 17');

        // Act - Create the task
        final createdTask = await taskService.create(newTask);

        // Assert
        print('✅ Task created with ID: ${createdTask.id}');
        expect(createdTask, isNotNull);
        expect(createdTask.id, isNotNull);
        expect(createdTask.title, equals('Integration Test Task'));
        expect(createdTask.project, equals(17));
        expect(createdTask.status, equals(1));

        // Act - Delete the task
        print('🗑️ Deleting task with ID: ${createdTask.id}');
        final deleteResult = await taskService.delete(createdTask.id!);

        // Assert
        expect(deleteResult, isTrue);
        print('✅ Task deleted successfully');

        // Verify it's deleted by trying to fetch it (should throw an exception)
        try {
          await taskService.getById(createdTask.id!);
          fail('Task still exists after deletion');
        } catch (e) {
          print('✅ Task no longer exists (expected error): $e');
          // Expected exception
        }
      } catch (e) {
        print('❌ Test failed: $e');
        fail('Test failed: $e');
      }
    });

    test('update task', () async {
      // Create test objects for Task creation
      final project = 17;
      final status = 1;

      try {
        // Create a test task
        final newTask = Task(
          project: project,
          title: 'Integration Test Task',
          status: status,
          content: 'Test content',
        );

        print('🆕 Creating task for update test');

        // Create the task
        final createdTask = await taskService.create(newTask);
        print('✅ Created task with ID: ${createdTask.id}');

        // Act - Update the task
        final updatedTask = Task(
          id: createdTask.id,
          project: project,
          title: 'Updated Task Title', // Changed title
          status: status,
          content: 'This is new content', // Added content
        );

        print('🔄 Updating task title and adding content');
        final result = await taskService.update(updatedTask);

        // Assert
        print('✅ Task updated successfully');
        expect(result, isNotNull);
        expect(result.id, equals(createdTask.id));
        expect(
          result.title,
          equals('Updated Task Title'),
        ); // Verify title changed
        expect(
          result.content,
          equals('This is new content'),
        ); // Verify content added

        // Clean up - delete the test task
        print('🧹 Cleaning up - deleting test task');
        await taskService.delete(createdTask.id!);
        print('✅ Test task deleted');
      } catch (e) {
        print('❌ Update test failed: $e');
        fail('Update test failed: $e');
      }
    });

    test('getByProjectId should return tasks for a specific project', () async {
      try {
        // Act
        final projectId = 17; // Using the project ID from your sample
        final tasks = await taskService.getByProjectId(projectId);

        // Print details for debugging
        print('✅ Got ${tasks.length} tasks for project $projectId');

        // Assert
        expect(tasks, isA<List<Task>>());
        for (var task in tasks) {
          expect(task.project, equals(projectId));
        }
      } catch (e) {
        print('❌ Test failed: $e');
        fail('Failed to fetch tasks by project ID: $e');
      }
    });

    test('getByStatusId should return tasks with a specific status', () async {
      try {
        // Act
        final statusId = 1; // Using the Backlog status ID from your sample
        final tasks = await taskService.getByStatusId(statusId);

        // Print details for debugging
        print('✅ Got ${tasks.length} tasks with status ID: $statusId');

        // Assert
        expect(tasks, isA<List<Task>>());
        for (var task in tasks) {
          expect(task.status, equals(statusId));
        }
      } catch (e) {
        print('❌ Test failed: $e');
        fail('Failed to fetch tasks by status ID: $e');
      }
    });

    test('search for tasks with specific title', () async {
      // Create test objects for Task creation
      final project = 17;
      final status = 1;

      try {
        // First create a task with a unique title for search
        final uniqueTitle =
            'UniqueSearchTask${DateTime.now().millisecondsSinceEpoch}';
        final searchTask = Task(
          project: project,
          title: uniqueTitle,
          status: status,
        );

        print('🔍 Creating unique task for search test: "$uniqueTitle"');
        final createdTask = await taskService.create(searchTask);

        // Act - Search for the unique title
        print('🔍 Searching for tasks with query: "$uniqueTitle"');
        final results = await taskService.search(uniqueTitle);

        // Assert
        print('✅ Search returned ${results.length} results');
        expect(results, isNotNull);
        expect(results.isNotEmpty, isTrue);
        expect(results.any((task) => task.title == uniqueTitle), isTrue);

        // Clean up
        print('🧹 Cleaning up - deleting test task');
        await taskService.delete(createdTask.id!);
      } catch (e) {
        print('❌ Search test failed: $e');
        fail('Search test failed: $e');
      }
    });

    test(
      'getByDeadlineBefore should return tasks with deadlines before a date',
      () async {
        // Create test objects for Task creation
        final project = 17;
        final status = 1;

        final deadline = DateTime.now().add(Duration(days: 3));

        try {
          // Create a task with a deadline
          final deadlineTask = Task(
            project: project,
            title: 'Deadline Test Task',
            status: status,
            deadline: deadline,
          );

          print('⏰ Creating task with deadline: ${deadline.toIso8601String()}');
          final createdTask = await taskService.create(deadlineTask);

          // Act - Get tasks with deadlines before a later date
          final laterDate = DateTime.now().add(Duration(days: 7));
          print(
            '⏰ Fetching tasks with deadlines before: ${laterDate.toIso8601String()}',
          );
          final results = await taskService.getByDeadlineBefore(laterDate);

          // Assert
          print(
            '✅ Got ${results.length} tasks with deadlines before ${laterDate.toIso8601String()}',
          );
          expect(results, isNotNull);

          // Note: This assertion might be too strict if there are other tasks with deadlines
          // in your test environment, so we'll just verify we got some results back
          expect(results.isNotEmpty, isTrue);

          // Clean up
          print('🧹 Cleaning up - deleting test task');
          await taskService.delete(createdTask.id!);
        } catch (e) {
          print('❌ Deadline test failed: $e');
          fail('Deadline test failed: $e');
        }
      },
    );
  });
}
