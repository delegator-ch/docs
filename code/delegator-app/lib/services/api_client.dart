import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiClient {
  final http.Client _httpClient;
  final String baseUrl;
  final Map<String, String> _defaultHeaders;
  final bool enableLogging;

  String? _authToken;

  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    Map<String, String>? defaultHeaders,
    this.enableLogging = true,
  }) : _httpClient = httpClient ?? http.Client(),
       baseUrl = baseUrl ?? ApiConfig.baseUrl,
       _defaultHeaders = defaultHeaders ?? {'Content-Type': 'application/json'};

  /// Set or update the auth token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// GET request
  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    final uri = Uri.parse(_buildUrl(endpoint));
    _log("📡 GET $uri");

    final response = await _httpClient.get(
      uri,
      headers: _mergeHeaders(headers),
    );

    return _handleResponse(response);
  }

  /// POST request
  Future<dynamic> post(
    String endpoint,
    Object? body, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(_buildUrl(endpoint));
    _log("📡 POST $uri");
    _log("📝 Body: ${jsonEncode(body)}");

    final response = await _httpClient.post(
      uri,
      headers: _mergeHeaders(headers),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  /// PUT request
  Future<dynamic> put(
    String endpoint,
    Object? body, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(_buildUrl(endpoint));
    _log("📡 PUT $uri");
    _log("📝 Body: ${jsonEncode(body)}");

    final response = await _httpClient.put(
      uri,
      headers: _mergeHeaders(headers),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  /// DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(_buildUrl(endpoint));
    _log("📡 DELETE $uri");

    final response = await _httpClient.delete(
      uri,
      headers: _mergeHeaders(headers),
    );

    return _handleResponse(response);
  }

  /// Build full URL from endpoint
  String _buildUrl(String endpoint) {
    final cleanBase =
        baseUrl.endsWith('/')
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
  dynamic _handleResponse(http.Response response) {
    _log("📦 Response: ${response.statusCode}");

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

    if (response.body.isEmpty) {
      return isSuccess
          ? null
          : throw ApiException(response.statusCode, 'Empty response');
    }

    try {
      final parsed = jsonDecode(response.body);

      if (isSuccess) {
        return parsed;
      } else {
        throw ApiException(response.statusCode, parsed.toString());
      }
    } catch (e) {
      throw ApiException(response.statusCode, 'Invalid JSON: ${response.body}');
    }
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
