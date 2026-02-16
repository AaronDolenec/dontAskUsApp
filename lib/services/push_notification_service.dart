import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'api_client.dart';
import 'api_exception.dart';

class PushNotificationService {
  static Future<void> initialize() async {
    await Firebase.initializeApp();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
  }

  static Future<String?> getDeviceToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  static Future<Map<String, dynamic>?> registerDeviceToken({
    required String userId,
    required String accessToken,
    required String platform,
    String? deviceName,

    /// Optional override of the device token (used in tests). If provided,
    /// the real Firebase token will not be fetched.
    String? deviceTokenOverride,

    /// Optional ApiClient to use (useful for tests). If not provided a new
    /// ApiClient is created and disposed.
    ApiClient? apiClient,
  }) async {
    final token = deviceTokenOverride ?? await getDeviceToken();
    if (token == null) return null;

    final api = apiClient ?? ApiClient();
    final shouldDispose = apiClient == null;
    try {
      final response = await api.post(
        '/api/users/$userId/device-token',
        {
          'token': token,
          'platform': platform,
          if (deviceName != null) 'device_name': deviceName,
        },
        accessToken: accessToken,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException.fromResponse(response);
      }
    } finally {
      if (shouldDispose) api.dispose();
    }
  }

  static Future<void> unregisterDeviceToken({
    required String userId,
    required String accessToken,
    required String deviceToken,
    ApiClient? apiClient,
  }) async {
    final api = apiClient ?? ApiClient();
    final shouldDispose = apiClient == null;
    try {
      final endpoint =
          '/api/users/$userId/device-token?token=${Uri.encodeComponent(deviceToken)}';
      final response = await api.delete(endpoint, accessToken: accessToken);
      if (response.statusCode != 200) {
        throw ApiException.fromResponse(response);
      }
    } finally {
      if (shouldDispose) api.dispose();
    }
  }

  static Future<List<Map<String, dynamic>>> listDeviceTokens({
    required String userId,
    required String accessToken,
    ApiClient? apiClient,
  }) async {
    final api = apiClient ?? ApiClient();
    final shouldDispose = apiClient == null;
    try {
      final response = await api.get('/api/users/$userId/device-tokens',
          accessToken: accessToken);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        throw ApiException.fromResponse(response);
      }
    } finally {
      if (shouldDispose) api.dispose();
    }
  }
}
