// test/mocks/mock_api_client.dart

import 'package:mockito/mockito.dart';
import '../../lib/services/api_client.dart';

/// Mock class for ApiClient
class MockApiClient extends Mock implements ApiClient {
  @override
  Future<dynamic> get(String endpoint) async {
    return super.noSuchMethod(Invocation.method(#get, [endpoint]),
        returnValue: Future.value({}));
  }

  @override
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    return super.noSuchMethod(Invocation.method(#post, [endpoint, data]),
        returnValue: Future.value({}));
  }

  @override
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    return super.noSuchMethod(Invocation.method(#put, [endpoint, data]),
        returnValue: Future.value({}));
  }

  @override
  Future<dynamic> delete(String endpoint) async {
    return super.noSuchMethod(Invocation.method(#delete, [endpoint]),
        returnValue: Future.value({}));
  }

  @override
  void setAuthToken(String token) {
    super.noSuchMethod(Invocation.method(#setAuthToken, [token]));
  }
}
