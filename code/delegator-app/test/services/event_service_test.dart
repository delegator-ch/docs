// test/services/event_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:delegator/services/event_service.dart';
import 'package:delegator/models/event.dart';
import 'package:delegator/models/calendar.dart';
import 'package:delegator/models/organisation.dart';
import 'package:delegator/config/api_config.dart';
import '../mocks/mock_api_client.dart';

void main() {
  late MockApiClient mockApiClient;
  late EventService eventService;

  setUp(() {
    mockApiClient = MockApiClient();
    eventService = EventService(apiClient: mockApiClient);
  });

  group('EventService', () {
    final testOrganisation = Organisation(id: 1, name: 'Test Organisation');
    final testCalendar = Calendar(id: 1, organisation: testOrganisation);

    final testEvent = Event(
      id: 1,
      calendar: testCalendar,
      start: DateTime(2023, 1, 1, 10, 0),
      end: DateTime(2023, 1, 1, 12, 0),
      isGig: true,
    );

    final testEvents = [
      testEvent,
      Event(
        id: 2,
        calendar: testCalendar,
        start: DateTime(2023, 1, 2, 10, 0),
        end: DateTime(2023, 1, 2, 12, 0),
        isGig: false,
      ),
    ];

    test('getAll should return list of events', () async {
      // Arrange
      final eventsJson =
          testEvents
              .map(
                (e) => {
                  'id': e.id,
                  'calendar': {
                    'id': e.calendar.id,
                    'organisation': {
                      'id': e.calendar.organisation.id,
                      'name': e.calendar.organisation.name,
                    },
                  },
                  'start': e.start.toIso8601String(),
                  'end': e.end.toIso8601String(),
                  'is_gig': e.isGig,
                },
              )
              .toList();

      when(
        mockApiClient.get(ApiConfig.events),
      ).thenAnswer((_) async => eventsJson);

      // Act
      final result = await eventService.getAll();

      // Assert
      expect(result.length, equals(2));
      expect(result[0].id, equals(1));
      expect(result[1].id, equals(2));
      verify(mockApiClient.get(ApiConfig.events)).called(1);
    });

    test('getById should return an event', () async {
      // Arrange
      final eventJson = {
        'id': testEvent.id,
        'calendar': {
          'id': testEvent.calendar.id,
          'organisation': {
            'id': testEvent.calendar.organisation.id,
            'name': testEvent.calendar.organisation.name,
          },
        },
        'start': testEvent.start.toIso8601String(),
        'end': testEvent.end.toIso8601String(),
        'is_gig': testEvent.isGig,
      };

      when(
        mockApiClient.get('${ApiConfig.events}/${testEvent.id}'),
      ).thenAnswer((_) async => eventJson);

      // Act
      final result = await eventService.getById(testEvent.id!);

      // Assert
      expect(result.id, equals(testEvent.id));
      expect(result.isGig, equals(testEvent.isGig));
      verify(
        mockApiClient.get('${ApiConfig.events}/${testEvent.id}'),
      ).called(1);
    });

    test('create should create an event', () async {
      // Arrange
      final eventJson = {
        'id': testEvent.id,
        'calendar': {
          'id': testEvent.calendar.id,
          'organisation': {
            'id': testEvent.calendar.organisation.id,
            'name': testEvent.calendar.organisation.name,
          },
        },
        'start': testEvent.start.toIso8601String(),
        'end': testEvent.end.toIso8601String(),
        'is_gig': testEvent.isGig,
      };

      when(
        mockApiClient.post(ApiConfig.events, testEvent.toJson()),
      ).thenAnswer((_) async => eventJson);

      // Act
      final result = await eventService.create(testEvent);

      // Assert
      expect(result.id, equals(testEvent.id));
      verify(
        mockApiClient.post(ApiConfig.events, testEvent.toJson()),
      ).called(1);
    });

    test('update should update an event', () async {
      // Arrange
      final eventJson = {
        'id': testEvent.id,
        'calendar': {
          'id': testEvent.calendar.id,
          'organisation': {
            'id': testEvent.calendar.organisation.id,
            'name': testEvent.calendar.organisation.name,
          },
        },
        'start': testEvent.start.toIso8601String(),
        'end': testEvent.end.toIso8601String(),
        'is_gig': testEvent.isGig,
      };

      when(
        mockApiClient.put(
          '${ApiConfig.events}/${testEvent.id}',
          testEvent.toJson(),
        ),
      ).thenAnswer((_) async => eventJson);

      // Act
      final result = await eventService.update(testEvent);

      // Assert
      expect(result.id, equals(testEvent.id));
      verify(
        mockApiClient.put(
          '${ApiConfig.events}/${testEvent.id}',
          testEvent.toJson(),
        ),
      ).called(1);
    });

    test('delete should delete an event', () async {
      // Arrange
      when(
        mockApiClient.delete('${ApiConfig.events}/${testEvent.id}'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await eventService.delete(testEvent.id!);

      // Assert
      expect(result, isTrue);
      verify(
        mockApiClient.delete('${ApiConfig.events}/${testEvent.id}'),
      ).called(1);
    });

    test('getByCalendarId should return events for a calendar', () async {
      // Arrange
      final calendarId = 1;
      final eventsJson =
          testEvents
              .map(
                (e) => {
                  'id': e.id,
                  'calendar': {
                    'id': e.calendar.id,
                    'organisation': {
                      'id': e.calendar.organisation.id,
                      'name': e.calendar.organisation.name,
                    },
                  },
                  'start': e.start.toIso8601String(),
                  'end': e.end.toIso8601String(),
                  'is_gig': e.isGig,
                },
              )
              .toList();

      when(
        mockApiClient.get('${ApiConfig.events}?calendar=$calendarId'),
      ).thenAnswer((_) async => eventsJson);

      // Act
      final result = await eventService.getByCalendarId(calendarId);

      // Assert
      expect(result.length, equals(2));
      verify(
        mockApiClient.get('${ApiConfig.events}?calendar=$calendarId'),
      ).called(1);
    });
  });
}
