import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:dont_ask_us/services/push_notification_service.dart';
import 'package:dont_ask_us/services/api_exception.dart';
import '../mocks/fake_api_client.dart';

void main() {
  group('PushNotificationService', () {
    test('registerDeviceToken returns parsed JSON on success', () async {
      final fake = FakeApiClient(
          onPost: (endpoint, body, {sessionToken, adminToken}) async {
        return http.Response('{"id":"abc","token":"t1"}', 200);
      });

      final result = await PushNotificationService.registerDeviceToken(
        userId: 'u1',
        sessionToken: 's1',
        platform: 'android',
        deviceTokenOverride: 't1',
        apiClient: fake,
      );

      expect(result, isA<Map<String, dynamic>>());
      expect(result!['id'], 'abc');
    });

    test('registerDeviceToken throws ApiException on non-200', () async {
      final fake = FakeApiClient(
          onPost: (endpoint, body, {sessionToken, adminToken}) async {
        return http.Response('{"error":"bad"}', 500);
      });

      expect(
        () => PushNotificationService.registerDeviceToken(
          userId: 'u1',
          sessionToken: 's1',
          platform: 'android',
          deviceTokenOverride: 't1',
          apiClient: fake,
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('unregisterDeviceToken calls delete and succeeds', () async {
      final fake =
          FakeApiClient(onDelete: (endpoint, {sessionToken, adminToken}) async {
        return http.Response('', 200);
      });

      await PushNotificationService.unregisterDeviceToken(
        userId: 'u1',
        sessionToken: 's1',
        deviceToken: 't1',
        apiClient: fake,
      );
    });

    test('listDeviceTokens returns list on success', () async {
      final fake = FakeApiClient(
          onGet: (endpoint, {sessionToken, adminToken, queryParams}) async {
        return http.Response('[{"token":"a"},{"token":"b"}]', 200);
      });

      final list = await PushNotificationService.listDeviceTokens(
          userId: 'u1', sessionToken: 's1', apiClient: fake);

      expect(list, isA<List<Map<String, dynamic>>>());
      expect(list.length, 2);
      expect(list[0]['token'], 'a');
    });
  });
}
