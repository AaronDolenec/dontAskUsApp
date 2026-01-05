import 'package:flutter_test/flutter_test.dart';

import 'package:dont_ask_us/services/services.dart';

void main() {
  group('ApiConfig', () {
    test('baseUrl is set correctly', () {
      expect(ApiConfig.baseUrl, isNotEmpty);
    });

    test('wsBaseUrl is set correctly', () {
      expect(ApiConfig.wsBaseUrl, isNotEmpty);
      expect(ApiConfig.wsBaseUrl, startsWith('ws'));
    });

    test('timeout is reasonable', () {
      expect(ApiConfig.timeout, greaterThan(Duration.zero));
      expect(ApiConfig.timeout, lessThanOrEqualTo(const Duration(seconds: 60)));
    });
  });

  group('ApiException', () {
    test('creates exception with message and status code', () {
      final exception = ApiException(
        statusCode: 400,
        message: 'Test error',
      );
      expect(exception.message, 'Test error');
      expect(exception.statusCode, 400);
      expect(exception.toString(), 'ApiException(400): Test error');
    });

    test('isUnauthorized returns correct value', () {
      final unauthorizedException = ApiException(
        statusCode: 401,
        message: 'Unauthorized',
      );
      final otherException = ApiException(
        statusCode: 400,
        message: 'Bad request',
      );

      expect(unauthorizedException.isUnauthorized, true);
      expect(otherException.isUnauthorized, false);
    });

    test('isNotFound returns correct value', () {
      final notFoundException = ApiException(
        statusCode: 404,
        message: 'Not found',
      );
      final otherException = ApiException(
        statusCode: 400,
        message: 'Bad request',
      );

      expect(notFoundException.isNotFound, true);
      expect(otherException.isNotFound, false);
    });

    test('isConflict returns correct value', () {
      final conflictException = ApiException(
        statusCode: 409,
        message: 'Conflict',
      );

      expect(conflictException.isConflict, true);
    });

    test('isRateLimited returns correct value', () {
      final rateLimitException = ApiException(
        statusCode: 429,
        message: 'Rate limited',
      );

      expect(rateLimitException.isRateLimited, true);
    });

    test('isServerError returns correct value', () {
      final serverException = ApiException(
        statusCode: 500,
        message: 'Server error',
      );
      final serverException503 = ApiException(
        statusCode: 503,
        message: 'Service unavailable',
      );

      expect(serverException.isServerError, true);
      expect(serverException503.isServerError, true);
    });

    test('userFriendlyMessage returns correct messages', () {
      expect(
        ApiException(statusCode: 401, message: '').userFriendlyMessage,
        contains('session'),
      );
      expect(
        ApiException(statusCode: 403, message: '').userFriendlyMessage,
        contains('permission'),
      );
      expect(
        ApiException(statusCode: 404, message: '').userFriendlyMessage,
        contains('not found'),
      );
      expect(
        ApiException(statusCode: 429, message: '').userFriendlyMessage,
        contains('many requests'),
      );
      expect(
        ApiException(statusCode: 500, message: '').userFriendlyMessage,
        contains('Something went wrong'),
      );
    });
  });

  group('ShareService', () {
    test('generateDeepLink creates correct format', () {
      final link = ShareService.generateDeepLink('ABC123');
      expect(link, 'dontaskus://join/ABC123');
    });
  });
}
