// integration_test/services/message_service_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:delegator/services/message_service.dart';
import 'package:delegator/services/chat_service.dart';
import 'package:delegator/services/auth_service.dart';
import 'package:delegator/services/api_client.dart';
import 'package:delegator/models/message.dart';
import 'package:delegator/models/chat.dart';
import '../helpers/test_setup.dart';

void main() {
  late MessageService messageService;
  late ChatService chatService;
  late AuthService authService;
  late ApiClient apiClient;
  late Chat testChat;

  setUp(() async {
    // Set up the integration test environment
    setupIntegrationTests();

    // Create a real API client
    apiClient = ApiClient();

    // Create services
    messageService = MessageService(apiClient: apiClient);
    chatService = ChatService(apiClient: apiClient);
    authService = AuthService(apiClient: apiClient);

    // Login to get proper authentication
    await authService.login(
      IntegrationTestConfig.testUsername,
      IntegrationTestConfig.testPassword,
    );

    // Get a chat for testing
    final chats = await chatService.getAll();
    if (chats.isEmpty) {
      fail('No chats available for testing');
    }
    testChat = chats.first;
    print('💬 Using chat with ID: ${testChat.id}');
  });

  tearDown(() {
    apiClient.dispose();
  });

  group('MessageService Integration Tests', () {
    test('getAll should return list of messages from real backend', () async {
      // Act
      try {
        final messages = await messageService.getAll();

        // Print details for debugging
        print('✅ Got ${messages.length} messages');
        for (var message in messages.take(5)) {
          // Show first 5 for brevity
          print(
            '📝 Message ID: ${message.id}, Chat ID: ${message.chat}, Content: "${message.content}"',
          );
        }

        // Assert
        expect(messages, isNotNull);
        expect(messages, isA<List<Message>>());
        // Further assertions depend on your data
      } catch (e) {
        print('❌ Error fetching messages: $e');
        fail('Failed to fetch messages: $e');
      }
    });

    test('getByChatId should return messages for a specific chat', () async {
      try {
        // Act
        final messages = await messageService.getByChatId(testChat.id!);

        // Print details for debugging
        print('✅ Got ${messages.length} messages for chat ${testChat.id}');

        // Assert
        expect(messages, isA<List<Message>>());
        for (var message in messages) {
          expect(message.chat, equals(testChat.id));
        }
      } catch (e) {
        print('❌ Test failed: $e');
        fail('Failed to fetch messages by chat ID: $e');
      }
    });

    test('create and delete message', () async {
      try {
        // Create a test message
        final newMessage = Message(
          user: 3, // Assuming this is the user ID from the test login
          chat: testChat.id!,
          content: 'Integration Test Message',
        );

        print('🆕 Creating new message for chat ${testChat.id}');

        // Act - Create the message
        final createdMessage = await messageService.create(newMessage);

        // Assert
        print('✅ Message created with ID: ${createdMessage.id}');
        expect(createdMessage, isNotNull);
        expect(createdMessage.id, isNotNull);
        expect(createdMessage.chat, equals(testChat.id));
        expect(createdMessage.content, equals('Integration Test Message'));

        // Act - Delete the message
        print('🗑️ Deleting message with ID: ${createdMessage.id}');
        final deleteResult = await messageService.delete(createdMessage.id!);

        // Assert
        expect(deleteResult, isTrue);
        print('✅ Message deleted successfully');

        // Verify it's deleted by trying to fetch it (should throw an exception)
        try {
          await messageService.getById(createdMessage.id!);
          fail('Message still exists after deletion');
        } catch (e) {
          print('✅ Message no longer exists (expected error): $e');
          // Expected exception
        }
      } catch (e) {
        print('❌ Test failed: $e');
        fail('Test failed: $e');
      }
    });

    test('update message', () async {
      try {
        // Create a test message
        final newMessage = Message(
          user: 3, // Assuming this is the user ID from the test login
          chat: testChat.id!,
          content: 'Original Message Content',
        );

        print('🆕 Creating message for update test');

        // Create the message
        final createdMessage = await messageService.create(newMessage);
        print('✅ Created message with ID: ${createdMessage.id}');

        // Act - Update the message
        final updatedMessage = Message(
          id: createdMessage.id,
          user: createdMessage.user,
          chat: createdMessage.chat,
          content: 'Updated Message Content', // Changed content
        );

        print('🔄 Updating message content');
        final result = await messageService.update(updatedMessage);

        // Assert
        print('✅ Message updated successfully');
        expect(result, isNotNull);
        expect(result.id, equals(createdMessage.id));
        expect(
          result.content,
          equals('Updated Message Content'),
        ); // Verify content changed

        // Clean up - delete the test message
        print('🧹 Cleaning up - deleting test message');
        await messageService.delete(createdMessage.id!);
        print('✅ Test message deleted');
      } catch (e) {
        print('❌ Update test failed: $e');
        fail('Update test failed: $e');
      }
    });

    test('search should find messages with matching content', () async {
      // First, create a message with a unique search term
      final uniqueContent =
          'UniqueSearchContent${DateTime.now().millisecondsSinceEpoch}';

      try {
        // Create test message
        final searchMessage = Message(
          user: 3,
          chat: testChat.id!,
          content: uniqueContent,
        );

        print('🔍 Creating unique message for search test: "$uniqueContent"');
        final createdMessage = await messageService.create(searchMessage);

        // Act - Search for the unique content
        print('🔍 Searching for messages with query: "$uniqueContent"');
        final results = await messageService.search(uniqueContent);

        // Assert
        print('✅ Search returned ${results.length} results');
        expect(results, isNotNull);
        expect(results.isNotEmpty, isTrue);
        expect(
          results.any((message) => message.content == uniqueContent),
          isTrue,
        );

        // Clean up
        print('🧹 Cleaning up - deleting test message');
        await messageService.delete(createdMessage.id!);
      } catch (e) {
        print('❌ Search test failed: $e');
        fail('Search test failed: $e');
      }
    });

    test('sendMessage convenience method should work', () async {
      try {
        // Act
        print('📤 Sending message to chat ${testChat.id}');
        final sentMessage = await messageService.sendMessage(
          testChat.id!,
          'Sent with convenience method',
        );

        // Assert
        print('✅ Message sent with ID: ${sentMessage.id}');
        expect(sentMessage, isNotNull);
        expect(sentMessage.id, isNotNull);
        expect(sentMessage.chat, equals(testChat.id));
        expect(sentMessage.content, equals('Sent with convenience method'));

        // Clean up
        print('🧹 Cleaning up - deleting test message');
        await messageService.delete(sentMessage.id!);
      } catch (e) {
        print('❌ Send message test failed: $e');
        fail('Send message test failed: $e');
      }
    });
  });
}
