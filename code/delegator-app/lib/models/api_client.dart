import 'dart:convert';
import 'package:delegator/models/http_response.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiClient {
  final http.Client _httpClient;
  final String baseUrl;
  final Map<String, String> _defaultHeaders;
  final bool enableLogging;

  String? _authToken;
  Function()? _onTokenRefreshNeeded; // Callback for token refresh

  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    Map<String, String>? defaultHeaders,
    this.enableLogging = true,
  })  : _httpClient = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _defaultHeaders =
            defaultHeaders ?? {'Content-Type': 'application/json'};

  /// Set or update the auth token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Set callback for when token refresh is needed
  void setTokenRefreshCallback(Function() callback) {
    _onTokenRefreshNeeded = callback;
  }

  /// GET request with auto retry on 401
  Future<Response> get(String endpoint, {Map<String, String>? headers}) async {
    return _makeRequestWithRetry(() async {
      final uri = Uri.parse(_buildUrl(endpoint));
      _log("📡 GET $uri");

      final response = await _httpClient.get(
        uri,
        headers: _mergeHeaders(headers),
      );

      return _handleResponse(response);
    });
  }

  /// POST request with auto retry on 401
  Future<dynamic> post(
    String endpoint,
    Object? body, {
    Map<String, String>? headers,
  }) async {
    return _makeRequestWithRetry(() async {
      final uri = Uri.parse(_buildUrl(endpoint));
      _log("📡 POST $uri");
      _log("📝 Body: ${jsonEncode(body)}");

      final response = await _httpClient.post(
        uri,
        headers: _mergeHeaders(headers),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    });
  }

  /// PUT request with auto retry on 401
  Future<dynamic> put(
    String endpoint,
    Object? body, {
    Map<String, String>? headers,
  }) async {
    return _makeRequestWithRetry(() async {
      final uri = Uri.parse(_buildUrl(endpoint));
      _log("📡 PUT $uri");
      _log("📝 Body: ${jsonEncode(body)}");

      final response = await _httpClient.put(
        uri,
        headers: _mergeHeaders(headers),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    });
  }

  /// DELETE request with auto retry on 401
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    return _makeRequestWithRetry(() async {
      final uri = Uri.parse(_buildUrl(endpoint));
      _log("📡 DELETE $uri");

      final response = await _httpClient.delete(
        uri,
        headers: _mergeHeaders(headers),
      );

      return _handleResponse(response);
    });
  }

  /// Make request with automatic retry on 401 Unauthorized
  Future<Response> _makeRequestWithRetry(
      Future<dynamic> Function() request) async {
    try {
      return await request();
    } on ApiException catch (e) {
      // If we get a 401 and have a refresh callback, try to refresh token
      if (e.statusCode == 401 && _onTokenRefreshNeeded != null) {
        _log("🔄 Token expired, attempting refresh...");

        try {
          // Call the refresh callback (this should be AuthService.refreshToken)
          await _onTokenRefreshNeeded!();
          _log("✅ Token refreshed, retrying request...");

          // Retry the original request with new token
          return await request();
        } catch (refreshError) {
          _log("❌ Token refresh failed: $refreshError");
          // Re-throw the original 401 error since refresh failed
          rethrow;
        }
      }

      // If not a 401 or no refresh callback, re-throw original error
      rethrow;
    }
  }

  /// Build full URL from endpoint
  String _buildUrl(String endpoint) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$cleanBase/$cleanEndpoint';
  }

  /// Combine default headers, token, and optional headers
  Map<String, String> _mergeHeaders(Map<String, String>? customHeaders) {
    final headers = Map<String, String>.from(_defaultHeaders);
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  /// Handles API response with statusCode check + JSON decoding
  Response _handleResponse(http.Response response) {
    _log("📦 Response: ${response.statusCode}");
    return Response(
        statusCode: response.statusCode, data: jsonDecode(response.body));
  }

  /// Extract user-friendly error message from different response formats
  String _extractErrorMessage(dynamic parsed) {
    if (parsed is Map<String, dynamic>) {
      // Handle Django's "detail" format: {"detail": "No active account..."}
      if (parsed.containsKey('detail')) {
        return parsed['detail'];
      }

      // Handle field validation errors: {"username": ["A user with that username..."]}
      final fieldErrors = <String>[];
      parsed.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          // Take first error message for each field
          fieldErrors.add('$key: ${value.first}');
        } else if (value is String) {
          fieldErrors.add('$key: $value');
        }
      });

      if (fieldErrors.isNotEmpty) {
        return fieldErrors.join(', ');
      }
    }

    // Fallback to string representation
    return parsed.toString();
  }

  void _log(String message) {
    if (enableLogging) print(message);
  }

  void dispose() {
    _httpClient.close();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException [$statusCode]: $message';
}
