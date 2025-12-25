import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_exception.dart';

/// HTTP client for API communication
class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? ApiConfig.currentBaseUrl,
        _client = client ?? http.Client();

  /// Perform a GET request
  Future<http.Response> get(
    String endpoint, {
    String? sessionToken,
    String? adminToken,
    Map<String, String>? queryParams,
  }) async {
    String url = '$baseUrl$endpoint';

    // Build query parameters
    final params = <String, String>{};
    if (sessionToken != null) {
      params['session_token'] = sessionToken;
    }
    if (queryParams != null) {
      params.addAll(queryParams);
    }

    if (params.isNotEmpty) {
      final queryString = params.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final separator = url.contains('?') ? '&' : '?';
      url = '$url$separator$queryString';
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (adminToken != null) {
      headers['X-Admin-Token'] = adminToken;
    }

    try {
      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.timeout);
      return response;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Perform a POST request
  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? sessionToken,
    String? adminToken,
  }) async {
    String url = '$baseUrl$endpoint';

    if (sessionToken != null) {
      final separator = url.contains('?') ? '&' : '?';
      url = '$url${separator}session_token=$sessionToken';
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (adminToken != null) {
      headers['X-Admin-Token'] = adminToken;
    }

    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);
      return response;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Perform a PUT request
  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? sessionToken,
    String? adminToken,
  }) async {
    String url = '$baseUrl$endpoint';

    if (sessionToken != null) {
      final separator = url.contains('?') ? '&' : '?';
      url = '$url${separator}session_token=$sessionToken';
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (adminToken != null) {
      headers['X-Admin-Token'] = adminToken;
    }

    try {
      final response = await _client
          .put(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);
      return response;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Perform a DELETE request
  Future<http.Response> delete(
    String endpoint, {
    String? sessionToken,
    String? adminToken,
  }) async {
    String url = '$baseUrl$endpoint';

    if (sessionToken != null) {
      final separator = url.contains('?') ? '&' : '?';
      url = '$url${separator}session_token=$sessionToken';
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (adminToken != null) {
      headers['X-Admin-Token'] = adminToken;
    }

    try {
      final response = await _client
          .delete(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.timeout);
      return response;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}
