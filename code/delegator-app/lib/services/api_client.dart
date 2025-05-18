// lib/services/api_client.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// API Client that handles HTTP requests to the backend
class ApiClient {
  final http.Client _httpClient;
  final String baseUrl;
  final Map<String, String> _headers;

  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    Map<String, String>? headers,
  }) : _httpClient = httpClient ?? http.Client(),
       baseUrl = baseUrl ?? ApiConfig.baseUrl,
       _headers = headers ?? {'Content-Type': 'application/json'};

  /// Set the authorization token for subsequent requests
  void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  /// GET request to fetch data
  Future<dynamic> get(String endpoint) async {
    final formattedEndpoint = _ensureTrailingSlash(endpoint);
    print("📡 GET request to: $baseUrl/$formattedEndpoint");

    final response = await _httpClient.get(
      Uri.parse('$baseUrl/$formattedEndpoint'),
      headers: _headers,
    );

    print("📦 Response status: ${response.statusCode}");
    return _handleResponse(response);
  }

  /// GET request to fetch data from a full URL
  Future<dynamic> getFromUrl(String url) async {
    print("📡 GET request to URL: $url");

    final response = await _httpClient.get(Uri.parse(url), headers: _headers);

    print("📦 Response status: ${response.statusCode}");
    return _handleResponse(response);
  }

  /// POST request to create data
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final formattedEndpoint = _ensureTrailingSlash(endpoint);
    print("📡 POST request to: $baseUrl/$formattedEndpoint");
    print("📝 Request data: ${jsonEncode(data)}");

    final response = await _httpClient.post(
      Uri.parse('$baseUrl/$formattedEndpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );

    print("📦 Response status: ${response.statusCode}");
    return _handleResponse(response);
  }

  /// PUT request to update data
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final formattedEndpoint = _ensureTrailingSlash(endpoint);
    print("📡 PUT request to: $baseUrl/$formattedEndpoint");

    final response = await _httpClient.put(
      Uri.parse('$baseUrl/$formattedEndpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );

    print("📦 Response status: ${response.statusCode}");
    return _handleResponse(response);
  }

  /// DELETE request to remove data
  Future<dynamic> delete(String endpoint) async {
    final formattedEndpoint = _ensureTrailingSlash(endpoint);
    print("📡 DELETE request to: $baseUrl/$formattedEndpoint");

    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/$formattedEndpoint'),
      headers: _headers,
    );

    print("📦 Response status: ${response.statusCode}");
    return _handleResponse(response);
  }

  /// Ensure endpoint has a trailing slash for Django REST Framework
  String _ensureTrailingSlash(String endpoint) {
    if (!endpoint.endsWith('/')) {
      return '$endpoint/';
    }
    return endpoint;
  }

  /// Handle HTTP response and convert to appropriate format
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;

      final parsedJson = jsonDecode(response.body);
      return parsedJson;
    } else {
      try {
        final errorJson = jsonDecode(response.body);
        print("❌ API Error: $errorJson");
        throw ApiException(
          statusCode: response.statusCode,
          message: errorJson.toString(),
        );
      } catch (e) {
        print("❌ API Error (raw): ${response.body}");
        throw ApiException(
          statusCode: response.statusCode,
          message: response.body,
        );
      }
    }
  }

  /// Close the HTTP client when done
  void dispose() {
    _httpClient.close();
  }
}

/// Exception thrown when API requests fail
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: [$statusCode] $message';
}
