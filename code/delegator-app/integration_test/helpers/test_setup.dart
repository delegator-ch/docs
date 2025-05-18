// integration_test/helpers/test_setup.dart

import 'package:flutter/material.dart';

/// Configuration for integration tests
class IntegrationTestConfig {
  /// The API base URL to use for integration tests
  /// Change this to point to your local Django server
  /// Test user credentials - should exist in your Django database
  static const testUsername = 'test_user_2';
  static const testPassword = 'sml12345';
}

/// Configure the app for integration testing
void setupIntegrationTests() {
  // Override the base URL in the API config
  // This is a hack since we can't easily change static constants
  // In a real app, you might want to use environment variables or build config
  //ApiConfig.baseUrl = IntegrationTestConfig.apiBaseUrl;

  // Set up WidgetsFlutterBinding for the Flutter test environment
  WidgetsFlutterBinding.ensureInitialized();
}
