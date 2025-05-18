// test/services/auth_service_test.dart

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delegator/services/auth_service.dart';
import 'package:delegator/models/user.dart';
import 'package:delegator/config/api_config.dart';
import '../mocks/mock_api_client.dart';

void main() {
  late MockApiClient mockApiClient;
  late AuthService authService;

  setUp(() {
    mockApiClient = MockApiClient();
    authService = AuthService(apiClient: mockApiClient);

    // Set up SharedPreferences mock
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService', () {
    const testUsername = 'testuser';
    const testPassword = 'password123';
    final testUser = User(id: 1, username: testUsername, isPremium: true);
    const testToken = 'test_token_12345';

    test('login should authenticate user and store token', () async {
      // Arrange
      final loginResponse = {
        'token': testToken,
        'user': {
          'id': testUser.id,
          'username': testUser.username,
          'is_premium': testUser.isPremium,
        },
      };

      when(
        mockApiClient.post(ApiConfig.token, {
          'username': testUsername,
          'password': testPassword,
        }),
      ).thenAnswer((_) async => loginResponse);

      // Act
      final result = await authService.login(testUsername, testPassword);

      // Assert
      expect(result.id, equals(testUser.id));
      expect(result.username, equals(testUser.username));
      expect(result.isPremium, equals(testUser.isPremium));

      // Verify token was set in API client
      verify(mockApiClient.setAuthToken(testToken)).called(1);

      // Verify token was stored
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), equals(testToken));
    });

    test('init should restore session if token exists', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'auth_token': testToken});

      // Act
      final result = await authService.init();

      // Assert
      expect(result, isTrue);
      verify(mockApiClient.setAuthToken(testToken)).called(1);
    });

    test('init should return false if no token exists', () async {
      // Arrange (empty SharedPreferences set in setUp)

      // Act
      final result = await authService.init();

      // Assert
      expect(result, isFalse);
      verifyNever(mockApiClient.setAuthToken(''));
    });

    test('logout should clear stored data', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'auth_token': testToken,
        'current_user': jsonEncode({
          'id': testUser.id,
          'username': testUser.username,
          'is_premium': testUser.isPremium,
        }),
      });

      // Act
      await authService.logout();

      // Assert
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('current_user'), isNull);
    });

    test('getCurrentUser should return stored user', () async {
      // Arrange
      final userData = {
        'id': testUser.id,
        'username': testUser.username,
        'is_premium': testUser.isPremium,
      };

      SharedPreferences.setMockInitialValues({
        'current_user': jsonEncode(userData),
      });

      // Act
      final result = await authService.getCurrentUser();

      // Assert
      expect(result, isNotNull);
      expect(result!.id, equals(testUser.id));
      expect(result.username, equals(testUser.username));
    });

    test('getCurrentUser should return null if no user data', () async {
      // Arrange (empty SharedPreferences set in setUp)

      // Act
      final result = await authService.getCurrentUser();

      // Assert
      expect(result, isNull);
    });

    test('isLoggedIn should return true if token exists', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'auth_token': testToken});

      // Act
      final result = await authService.isLoggedIn();

      // Assert
      expect(result, isTrue);
    });

    test('isLoggedIn should return false if no token', () async {
      // Arrange (empty SharedPreferences set in setUp)

      // Act
      final result = await authService.isLoggedIn();

      // Assert
      expect(result, isFalse);
    });
  });
}
