// integration_test/services/auth_service_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delegator/services/auth_service.dart';
import 'package:delegator/services/api_client.dart';
import '../helpers/test_setup.dart';

// These integration tests connect to your real backend
// and should be run when you have your Django server running
void main() {
  late AuthService authService;
  late ApiClient apiClient;

  setUp(() async {
    // Set up the integration test environment
    setupIntegrationTests();

    // Clear shared preferences before each test
    SharedPreferences.setMockInitialValues({});

    // Create a real API client pointing to your backend
    apiClient = ApiClient(httpClient: http.Client());

    // Create an auth service with the real API client
    authService = AuthService(apiClient: apiClient);
  });

  tearDown(() {
    // Clean up resources
    apiClient.dispose();
  });

  group('AuthService Integration Tests', () {
    test('login should authenticate with real backend', () async {
      print(
        '🔍 Starting login test with username: ${IntegrationTestConfig.testUsername}',
      );

      try {
        // Act
        final result = await authService.login(
          IntegrationTestConfig.testUsername,
          IntegrationTestConfig.testPassword,
        );

        print('✅ Login successful, got user: ${result.username}');

        // Assert
        expect(result, isNotNull);
        expect(result.username, equals(IntegrationTestConfig.testUsername));

        // Verify tokens were stored
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString('access_token');
        final refreshToken = prefs.getString('refresh_token');

        print('🔑 Access token stored: ${accessToken?.substring(0, 10)}...');
        print('🔄 Refresh token stored: ${refreshToken?.substring(0, 10)}...');

        expect(accessToken, isNotNull);
        expect(refreshToken, isNotNull);
      } catch (e) {
        print('❌ Login FAILED with error: $e');
        fail('Login failed: $e');
      }
    });

    test('getCurrentUser should return user after login', () async {
      // Arrange
      await authService.login(
        IntegrationTestConfig.testUsername,
        IntegrationTestConfig.testPassword,
      );

      // Act
      final user = await authService.getCurrentUser();

      // Assert
      expect(user, isNotNull);
      expect(user!.username, equals(IntegrationTestConfig.testUsername));
    });

    test('isLoggedIn should return true after login', () async {
      // Arrange
      await authService.login(
        IntegrationTestConfig.testUsername,
        IntegrationTestConfig.testPassword,
      );

      // Act
      final isLoggedIn = await authService.isLoggedIn();

      // Assert
      expect(isLoggedIn, isTrue);
    });

    test('logout should clear authentication data', () async {
      // Arrange
      await authService.login(
        IntegrationTestConfig.testUsername,
        IntegrationTestConfig.testPassword,
      );

      // Act
      await authService.logout();

      // Assert
      final isLoggedIn = await authService.isLoggedIn();
      expect(isLoggedIn, isFalse);

      final user = await authService.getCurrentUser();
      expect(user, isNull);
    });

    // Testing initialization (recovering session from storage)
    test('init should restore session if token exists', () async {
      // Arrange
      // First login to get a token
      await authService.login(
        IntegrationTestConfig.testUsername,
        IntegrationTestConfig.testPassword,
      );

      // Create a new service instance (simulating app restart)
      final newAuthService = AuthService(apiClient: ApiClient());

      // Act
      final result = await newAuthService.init();

      // Assert
      expect(result, isTrue);

      // Verify user session is valid
      final user = await newAuthService.getCurrentUser();
      expect(user, isNotNull);
      expect(user!.username, equals(IntegrationTestConfig.testUsername));
    });
  });
}
