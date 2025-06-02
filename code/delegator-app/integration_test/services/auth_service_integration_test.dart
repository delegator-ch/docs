// integration_test/services/auth_service_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delegator/services/auth_service.dart';
import 'package:delegator/models/api_client.dart';
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

        print('✅ Login successful, got user: ${result.user?.username}');

        // Assert
        expect(result.success, isTrue);
        expect(result.user, isNotNull);
        expect(
            result.user!.username, equals(IntegrationTestConfig.testUsername));

        // Verify user is logged in
        final isLoggedIn = await authService.isLoggedIn();
        expect(isLoggedIn, isTrue);

        print('🔑 User is now logged in');
      } catch (e) {
        print('❌ Login FAILED with error: $e');
        fail('Login failed: $e');
      }
    });

    test('register should create new user account', () async {
      // Generate unique username to avoid conflicts
      final uniqueUsername =
          'test_register_${DateTime.now().millisecondsSinceEpoch}';

      print('🔍 Starting registration test with username: $uniqueUsername');

      try {
        // Act
        final result = await authService.register(
          uniqueUsername,
          IntegrationTestConfig.testPassword,
        );

        print('✅ Registration successful, got user: ${result.user?.username}');

        // Assert
        expect(result.success, isTrue);
        expect(result.user, isNotNull);
        expect(result.user!.username, equals(uniqueUsername));

        // Verify user is logged in after registration
        final isLoggedIn = await authService.isLoggedIn();
        expect(isLoggedIn, isTrue);

        print('🔑 User is automatically logged in after registration');
      } catch (e) {
        print('❌ Registration FAILED with error: $e');
        fail('Registration failed: $e');
      }
    });

    test('register should fail with duplicate username', () async {
      print('🔍 Testing registration with duplicate username');

      try {
        // Attempt to register with existing username
        final result = await authService.register(
          IntegrationTestConfig
              .testUsername, // This username should already exist
          IntegrationTestConfig.testPassword,
        );

        // Should not succeed
        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.toLowerCase(), contains('username'));

        print('✅ Registration correctly failed with duplicate username');
      } catch (e) {
        print('❌ Duplicate username test failed: $e');
        fail('Duplicate username test failed: $e');
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

    test('init should return false when no token exists', () async {
      // Arrange - ensure we start with no stored tokens
      await authService.clearAllAuthData();

      // Create a new service instance
      final newAuthService = AuthService(apiClient: ApiClient());

      // Act
      final result = await newAuthService.init();

      // Assert
      expect(result, isFalse);

      // Verify no user session
      final user = await newAuthService.getCurrentUser();
      expect(user, isNull);
    });

    test('login should handle invalid credentials', () async {
      print('🔍 Testing login with invalid credentials');

      try {
        // Act
        final result = await authService.login(
          'invalid_username',
          'invalid_password',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        expect(result.user, isNull);

        print('✅ Login correctly failed with invalid credentials');
      } catch (e) {
        print('❌ Invalid credentials test failed: $e');
        fail('Invalid credentials test failed: $e');
      }
    });

    test('remember me functionality should work', () async {
      print('🔍 Testing remember me functionality');

      try {
        // Login with remember me enabled
        await authService.login(
          IntegrationTestConfig.testUsername,
          IntegrationTestConfig.testPassword,
          rememberMe: true,
        );

        // Check remember me is enabled
        final rememberMeEnabled = await authService.isRememberMeEnabled();
        expect(rememberMeEnabled, isTrue);

        // Check last username is stored
        final lastUsername = await authService.getLastUsername();
        expect(lastUsername, equals(IntegrationTestConfig.testUsername));

        print('✅ Remember me functionality works correctly');
      } catch (e) {
        print('❌ Remember me test failed: $e');
        fail('Remember me test failed: $e');
      }
    });

    test('clearAllAuthData should remove all authentication data', () async {
      // Arrange - login first
      await authService.login(
        IntegrationTestConfig.testUsername,
        IntegrationTestConfig.testPassword,
      );

      // Verify user is logged in
      expect(await authService.isLoggedIn(), isTrue);

      // Act
      await authService.clearAllAuthData();

      // Assert
      expect(await authService.isLoggedIn(), isFalse);
      expect(await authService.getCurrentUser(), isNull);
      expect(await authService.isRememberMeEnabled(), isFalse);
      expect(await authService.getLastUsername(), isNull);

      print('✅ All authentication data cleared successfully');
    });
  });
}
