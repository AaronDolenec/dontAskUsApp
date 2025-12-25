import 'dart:convert';
import 'package:http/http.dart' as http;

/// Custom exception for API errors
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;

  ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  /// Create an ApiException from an HTTP response
  factory ApiException.fromResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiException(
        statusCode: response.statusCode,
        message: body['detail'] as String? ?? 'Unknown error',
        details: body,
      );
    } catch (_) {
      return ApiException(
        statusCode: response.statusCode,
        message: 'Request failed with status ${response.statusCode}',
      );
    }
  }

  /// Check if the error is due to invalid session
  bool get isUnauthorized => statusCode == 401;

  /// Check if the error is due to resource not found
  bool get isNotFound => statusCode == 404;

  /// Check if the error is a conflict (e.g., name already taken)
  bool get isConflict => statusCode == 409;

  /// Check if the error is rate limiting
  bool get isRateLimited => statusCode == 429;

  /// Check if the error is a server error
  bool get isServerError => statusCode >= 500;

  /// Get a user-friendly error message
  String get userFriendlyMessage {
    switch (statusCode) {
      case 400:
        return message;
      case 401:
        return 'Your session has expired. Please join the group again.';
      case 403:
        return 'You don\'t have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return message.isNotEmpty ? message : 'This name is already taken.';
      case 429:
        return 'Too many requests. Please slow down.';
      default:
        if (isServerError) {
          return 'Something went wrong on our end. Please try again later.';
        }
        return message;
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
