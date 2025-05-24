// integration_test/services/chat_service_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:delegator/services/chat_service.dart';
import 'package:delegator/services/auth_service.dart';
import 'package:delegator/services/api_client.dart';
import 'package:delegator/models/chat.dart';
import '../helpers/test_setup.dart';

void main() {
  late ChatService chatService;
  late AuthService authService;
  late ApiClient apiClient;

  setUp(() async {
    // Set up the integration test environment
    setupIntegrationTests();

    // Create a real API client
    apiClient = ApiClient();

    // Create services
    chatService = ChatService(apiClient: apiClient);
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

  group('ChatService Integration Tests', () {
    test('getAll should return list of chats from real backend', () async {
      // Act
      try {
        final chats = await chatService.getAll();

        // Print details for debugging
        print('✅ Got ${chats.length} chats');
        for (var chat in chats) {
          print(
            '💬 Chat ID: ${chat.id}, Org ID: ${chat.organisation}, Type: ${chat.chatType}',
          );
        }

        // Assert
        expect(chats, isNotNull);
        expect(chats, isA<List<Chat>>());
        // Further assertions depend on your data
      } catch (e) {
        print('❌ Error fetching chats: $e');
        fail('Failed to fetch chats: $e');
      }
    });

    test('create and delete chat', () async {
      // For this test, we'll use a fixed organisation ID
      final organisationId = 5; // Based on the API response you provided

      try {
        // Create a test chat
        final newChat = Chat(
          organisation: organisationId,
          name: 'Test Integration Chat',
          minRoleLevel: 5,
        );

        print('🆕 Creating new chat for organisation $organisationId');

        // Act - Create the chat
        final createdChat = await chatService.create(newChat);

        // Assert
        print('✅ Chat created with ID: ${createdChat.id}');
        expect(createdChat, isNotNull);
        expect(createdChat.id, isNotNull);
        expect(createdChat.organisation, equals(organisationId));
        expect(createdChat.name, equals('Test Integration Chat'));

        // Act - Delete the chat
        print('🗑️ Deleting chat with ID: ${createdChat.id}');
        final deleteResult = await chatService.delete(createdChat.id!);

        // Assert
        expect(deleteResult, isTrue);
        print('✅ Chat deleted successfully');

        // Verify it's deleted by trying to fetch it (should throw an exception)
        try {
          await chatService.getById(createdChat.id!);
          fail('Chat still exists after deletion');
        } catch (e) {
          print('✅ Chat no longer exists (expected error): $e');
          // Expected exception
        }
      } catch (e) {
        print('❌ Test failed: $e');
        fail('Test failed: $e');
      }
    });

    test(
      'getByOrganisationId should return chats for a specific organisation',
      () async {
        try {
          // Act
          final organisationId = 5; // Based on the API response you provided
          final chats = await chatService.getByOrganisationId(organisationId);

          // Print details for debugging
          print('✅ Got ${chats.length} chats for organisation $organisationId');

          // Assert
          expect(chats, isA<List<Chat>>());
          for (var chat in chats) {
            expect(chat.organisation, equals(organisationId));
          }
        } catch (e) {
          print('❌ Test failed: $e');
          fail('Failed to fetch chats by organisation ID: $e');
        }
      },
    );

    test('update chat should modify chat properties', () async {
      // For this test, we'll use a fixed organisation ID
      final organisationId = 5; // Based on the API response you provided

      try {
        // Create a test chat
        final newChat = Chat(
          organisation: organisationId,
          name: 'Original Chat Name',
          minRoleLevel: 5,
        );

        print('🆕 Creating chat for update test');

        // Create the chat
        final createdChat = await chatService.create(newChat);
        print('✅ Created chat with ID: ${createdChat.id}');

        // Act - Update the chat
        final updatedChat = Chat(
          id: createdChat.id,
          organisation: organisationId,
          name: 'Updated Chat Name', // Changed name
          minRoleLevel: 5,
        );

        print('🔄 Updating chat name');
        final result = await chatService.update(updatedChat);

        // Assert
        print('✅ Chat updated successfully');
        expect(result, isNotNull);
        expect(result.id, equals(createdChat.id));
        expect(result.name, equals('Updated Chat Name')); // Verify name changed

        // Clean up - delete the test chat
        print('🧹 Cleaning up - deleting test chat');
        await chatService.delete(createdChat.id!);
        print('✅ Test chat deleted');
      } catch (e) {
        print('❌ Update test failed: $e');
        fail('Update test failed: $e');
      }
    });
  });
}
