// integration_test/services/event_service_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:delegator/services/event_service.dart';
import 'package:delegator/services/calendar_service.dart';
import 'package:delegator/services/auth_service.dart';
import 'package:delegator/models/api_client.dart';
import 'package:delegator/models/event.dart';
import 'package:delegator/models/calendar.dart';
import '../helpers/test_setup.dart';

void main() {
  late EventService eventService;
  late CalendarService calendarService;
  late AuthService authService;
  late ApiClient apiClient;
  late Calendar testCalendar;

  setUp(() async {
    // Set up the integration test environment
    setupIntegrationTests();

    // Create a real API client
    apiClient = ApiClient();

    // Create services
    eventService = EventService(apiClient: apiClient);
    calendarService = CalendarService(apiClient: apiClient);
    authService = AuthService(apiClient: apiClient);

    // Login to get proper authentication
    await authService.login(
      IntegrationTestConfig.testUsername,
      IntegrationTestConfig.testPassword,
    );

    // Get a calendar for testing
    final calendars = await calendarService.getAll();
    if (calendars.isEmpty) {
      fail('No calendars available for testing');
    }
    testCalendar = calendars.first;
    print('🗓️ Using calendar with ID: ${testCalendar.id}');
  });

  tearDown(() {
    apiClient.dispose();
  });

  group('EventService Integration Tests', () {
    test('getAll should return list of events from real backend', () async {
      // Act
      try {
        final events = await eventService.getAll();

        // Print details for debugging
        print('✅ Got ${events.length} events');
        for (var event in events) {
          print(
            '📅 Event ID: ${event.id}, Calendar ID: ${event.calender}, Start: ${event.start}',
          );
        }

        // Assert
        expect(events, isNotNull);
        expect(events, isA<List<Event>>());
        // Further assertions depend on your data
      } catch (e) {
        print('❌ Error fetching events: $e');
        fail('Failed to fetch events: $e');
      }
    });

    test('create and delete event', () async {
      // Get the current time for test event
      final now = DateTime.now();
      final later = now.add(Duration(hours: 2));

      // Create a test event
      try {
        final newEvent = Event(
          calender: testCalendar.id!,
          title: 'Test',
          start: now,
          end: later,
          isGig: false,
        );

        print('🆕 Creating new event for calendar ${testCalendar.id}');

        // Act - Create the event
        final createdEvent = await eventService.create(newEvent);

        // Assert
        print('✅ Event created with ID: ${createdEvent.id}');
        expect(createdEvent, isNotNull);
        expect(createdEvent.id, isNotNull);
        expect(createdEvent.calender, equals(testCalendar.id));
        print(
          '✅ Expected ${newEvent.start} and recieved ${createdEvent.start}',
        );
        /*expect(
          createdEvent.start.millisecondsSinceEpoch,
          closeTo(now.millisecondsSinceEpoch, 1000),
        );
        expect(
          createdEvent.end.millisecondsSinceEpoch,
          closeTo(later.millisecondsSinceEpoch, 1000),
        );
        */

        // Act - Delete the event
        print('🗑️ Deleting event with ID: ${createdEvent.id}');
        final deleteResult = await eventService.delete(createdEvent.id!);

        // Assert
        expect(deleteResult, isTrue);
        print('✅ Event deleted successfully');

        // Verify it's deleted by trying to fetch it (should throw an exception)
        try {
          await eventService.getById(createdEvent.id!);
          fail('Event still exists after deletion');
        } catch (e) {
          print('✅ Event no longer exists (expected error): $e');
          // Expected exception
        }
      } catch (e) {
        print('❌ Test failed: $e');
        fail('Test failed: $e');
      }
    });

    test('update event', () async {
      // Get the current time for test event
      final now = DateTime.now();
      final later = now.add(Duration(hours: 2));
      final evenLater = now.add(Duration(hours: 3));

      try {
        // Create a test event
        final newEvent = Event(
          calender: testCalendar.id!,
          title: 'Test',
          start: now,
          end: later,
          isGig: false,
        );

        print('🆕 Creating event for update test');

        // Create the event
        final createdEvent = await eventService.create(newEvent);
        print('✅ Created event with ID: ${createdEvent.id}');

        // Act - Update the event
        final updatedEvent = Event(
          id: createdEvent.id,
          title: 'Test',
          calender: testCalendar.id!,
          start: now,
          end: evenLater, // Extended end time
          isGig: true, // Changed to gig
        );

        print('🔄 Updating event to be a gig with longer duration');
        final result = await eventService.update(updatedEvent);

        // Assert
        print('✅ Event updated successfully');
        expect(result, isNotNull);
        expect(result.id, equals(createdEvent.id));
        expect(result.isGig, isTrue); // Verify gig status changed

        // Clean up - delete the test event
        print('🧹 Cleaning up - deleting test event');
        await eventService.delete(createdEvent.id!);
        print('✅ Test event deleted');
      } catch (e) {
        print('❌ Update test failed: $e');
        fail('Update test failed: $e');
      }
    });

    test(
      'getByCalendarId should return events for a specific calendar',
      () async {
        try {
          // Act
          final events = await eventService.getByCalendarId(testCalendar.id!);

          // Print details for debugging
          print(
            '✅ Got ${events.length} events for calendar ${testCalendar.id}',
          );

          // Assert
          expect(events, isA<List<Event>>());
          for (var event in events) {
            expect(event.calender, equals(testCalendar.id));
          }
        } catch (e) {
          print('❌ Test failed: $e');
          fail('Failed to fetch events by calendar ID: $e');
        }
      },
    );

    test('getGigs should return only gig events', () async {
      try {
        // Act
        final gigs = await eventService.getGigs();

        // Print details for debugging
        print('✅ Got ${gigs.length} gig events');

        // Assert
        expect(gigs, isA<List<Event>>());
        for (var gig in gigs) {
          expect(gig.isGig, isTrue);
        }
      } catch (e) {
        print('❌ Test failed: $e');
        fail('Failed to fetch gig events: $e');
      }
    });
  });
}
