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
    required String sessionToken,
    required String platform,
    String? deviceName,
  }) async {
    final token = await getDeviceToken();
    if (token == null) return null;

    final api = ApiClient();
    try {
      final response = await api.post(
        '/api/users/$userId/device-token',
        {
          'token': token,
          'platform': platform,
          if (deviceName != null) 'device_name': deviceName,
        },
        sessionToken: sessionToken,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException.fromResponse(response);
      }
    } finally {
      api.dispose();
    }
  }

  static Future<void> unregisterDeviceToken({
    required String userId,
    required String sessionToken,
    required String deviceToken,
  }) async {
    final api = ApiClient();
    try {
      final endpoint =
          '/api/users/$userId/device-token?token=${Uri.encodeComponent(deviceToken)}';
      final response = await api.delete(endpoint, sessionToken: sessionToken);
      if (response.statusCode != 200) {
        throw ApiException.fromResponse(response);
      }
    } finally {
      api.dispose();
    }
  }

  static Future<List<Map<String, dynamic>>> listDeviceTokens({
    required String userId,
    required String sessionToken,
  }) async {
    final api = ApiClient();
    try {
      final response = await api.get('/api/users/$userId/device-tokens',
          sessionToken: sessionToken);
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
      api.dispose();
    }
  }
}
