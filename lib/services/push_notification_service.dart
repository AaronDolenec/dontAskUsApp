import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  static Future<void> initialize() async {
    await Firebase.initializeApp();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
  }

  static Future<String?> getDeviceToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  static Future<void> registerDeviceToken({
    required String userId,
    required String sessionToken,
    required String platform,
    String? deviceName,
  }) async {
    final token = await getDeviceToken();
    if (token == null) return;
    // TODO: Send token to backend using ApiClient
    // POST /api/users/{user_id}/device-token
    // X-Session-Token: <session_token>
    // { token, platform, device_name }
  }

  static Future<void> unregisterDeviceToken({
    required String userId,
    required String sessionToken,
    required String deviceToken,
  }) async {
    // TODO: Send DELETE to backend
    // /api/users/{user_id}/device-token?token=<device_token>
    // X-Session-Token: <session_token>
  }

  static Future<void> listDeviceTokens({
    required String userId,
    required String sessionToken,
  }) async {
    // TODO: Send GET to backend
    // /api/users/{user_id}/device-tokens
    // X-Session-Token: <session_token>
  }
}
