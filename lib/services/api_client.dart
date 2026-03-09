import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'auth_service.dart'; // for automatic session refresh on 401

/// HTTP client for API communication
class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? ApiConfig.currentBaseUrl,
        _client = client ?? http.Client();

  /// Build common headers
  Map<String, String> _buildHeaders({
    String? accessToken,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }

  /// Perform a GET request
  Future<http.Response> get(
    String endpoint, {
    String? accessToken,
    Map<String, String>? queryParams,
  }) async {
    String url = '$baseUrl$endpoint';

    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final separator = url.contains('?') ? '&' : '?';
      url = '$url$separator$queryString';
    }

    final headers = _buildHeaders(
      accessToken: accessToken,
    );
    final shouldTryRefresh =
        accessToken != null && endpoint != '/api/auth/refresh';

    try {
      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.timeout);
      // if unauthorized, attempt to refresh session once
      if (response.statusCode == 401 && shouldTryRefresh) {
        await AuthService.autoRefreshSession();
        // retry once with potentially refreshed token
        final newAccessToken = await AuthService.getAccessToken();
        if (newAccessToken != null) {
          final retryHeaders = _buildHeaders(accessToken: newAccessToken);
          return await _client
              .get(Uri.parse(url), headers: retryHeaders)
              .timeout(ApiConfig.timeout);
        }
      }
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
    String? accessToken,
  }) async {
    final url = '$baseUrl$endpoint';

    final headers = _buildHeaders(
      accessToken: accessToken,
    );
    final shouldTryRefresh =
        accessToken != null && endpoint != '/api/auth/refresh';

    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);
      if (response.statusCode == 401 && shouldTryRefresh) {
        await AuthService.autoRefreshSession();
        final newAccessToken = await AuthService.getAccessToken();
        if (newAccessToken != null) {
          final retryHeaders = _buildHeaders(accessToken: newAccessToken);
          return await _client
              .post(
                Uri.parse(url),
                headers: retryHeaders,
                body: jsonEncode(body),
              )
              .timeout(ApiConfig.timeout);
        }
      }
      return response;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Perform a multipart POST request (for file uploads like avatars)
  Future<http.Response> postMultipart(
    String endpoint, {
    required String filePath,
    required String fileField,
    String? accessToken,
    Map<String, String>? fields,
  }) async {
    final url = '$baseUrl$endpoint';

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send().timeout(ApiConfig.timeout);
      return await http.Response.fromStream(streamedResponse);
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Perform a multipart POST request using bytes (works on web and mobile)
  Future<http.Response> postMultipartBytes(
    String endpoint, {
    required List<int> fileBytes,
    required String fileName,
    required String fileField,
    String? accessToken,
    Map<String, String>? fields,
  }) async {
    final url = '$baseUrl$endpoint';

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      // Determine content type from file extension
      final ext = fileName.split('.').last.toLowerCase();
      final mimeType = switch (ext) {
        'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
        'png' => MediaType('image', 'png'),
        'gif' => MediaType('image', 'gif'),
        'webp' => MediaType('image', 'webp'),
        _ => MediaType('image', 'jpeg'),
      };

      request.files.add(http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: fileName,
        contentType: mimeType,
      ));

      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send().timeout(ApiConfig.timeout);
      return await http.Response.fromStream(streamedResponse);
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
    String? accessToken,
  }) async {
    final url = '$baseUrl$endpoint';

    final headers = _buildHeaders(
      accessToken: accessToken,
    );
    final shouldTryRefresh =
        accessToken != null && endpoint != '/api/auth/refresh';

    try {
      final response = await _client
          .put(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);
      if (response.statusCode == 401 && shouldTryRefresh) {
        await AuthService.autoRefreshSession();
        final newAccessToken = await AuthService.getAccessToken();
        if (newAccessToken != null) {
          final retryHeaders = _buildHeaders(accessToken: newAccessToken);
          return await _client
              .put(
                Uri.parse(url),
                headers: retryHeaders,
                body: jsonEncode(body),
              )
              .timeout(ApiConfig.timeout);
        }
      }
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
    String? accessToken,
  }) async {
    final url = '$baseUrl$endpoint';

    final headers = _buildHeaders(
      accessToken: accessToken,
    );
    final shouldTryRefresh =
        accessToken != null && endpoint != '/api/auth/refresh';

    try {
      final response = await _client
          .delete(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.timeout);
      if (response.statusCode == 401 && shouldTryRefresh) {
        await AuthService.autoRefreshSession();
        final newAccessToken = await AuthService.getAccessToken();
        if (newAccessToken != null) {
          final retryHeaders = _buildHeaders(accessToken: newAccessToken);
          return await _client
              .delete(Uri.parse(url), headers: retryHeaders)
              .timeout(ApiConfig.timeout);
        }
      }
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
