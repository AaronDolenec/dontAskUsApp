import 'package:http/http.dart' as http;
import 'package:dont_ask_us/services/api_client.dart';

typedef GetHandler = Future<http.Response> Function(String endpoint,
    {String? sessionToken,
    String? adminToken,
    Map<String, String>? queryParams});
typedef PostHandler = Future<http.Response> Function(
    String endpoint, Map<String, dynamic> body,
    {String? sessionToken, String? adminToken});
typedef DeleteHandler = Future<http.Response> Function(String endpoint,
    {String? sessionToken, String? adminToken});

class FakeApiClient implements ApiClient {
  final GetHandler? onGet;
  final PostHandler? onPost;
  final DeleteHandler? onDelete;

  FakeApiClient({this.onGet, this.onPost, this.onDelete});

  @override
  Future<http.Response> get(String endpoint,
      {String? sessionToken,
      String? adminToken,
      Map<String, String>? queryParams}) {
    if (onGet != null) {
      return onGet!(endpoint,
          sessionToken: sessionToken,
          adminToken: adminToken,
          queryParams: queryParams);
    }
    throw UnimplementedError();
  }

  @override
  Future<http.Response> post(String endpoint, Map<String, dynamic> body,
      {String? sessionToken, String? adminToken}) {
    if (onPost != null) {
      return onPost!(endpoint, body,
          sessionToken: sessionToken, adminToken: adminToken);
    }
    throw UnimplementedError();
  }

  @override
  Future<http.Response> delete(String endpoint,
      {String? sessionToken, String? adminToken}) {
    if (onDelete != null) {
      return onDelete!(endpoint,
          sessionToken: sessionToken, adminToken: adminToken);
    }
    throw UnimplementedError();
  }

  @override
  Future<http.Response> put(String endpoint, Map<String, dynamic> body,
      {String? sessionToken, String? adminToken}) {
    throw UnimplementedError();
  }

  @override
  void dispose() {}

  @override
  String get baseUrl => throw UnimplementedError();
}
