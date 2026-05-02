import 'package:flutter/foundation.dart' show debugPrint, debugPrintStack;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/push_notification_service.dart';

final deviceTokenProvider = StateNotifierProvider<DeviceTokenNotifier, DeviceTokenState>((ref) {
  return DeviceTokenNotifier(ref);
});

class DeviceTokenState {
  final String? token;
  final List<dynamic>? tokensList;
  final String? message;
  DeviceTokenState({this.token, this.tokensList, this.message});

  DeviceTokenState copyWith({String? token, List<dynamic>? tokensList, String? message}) {
    return DeviceTokenState(
      token: token ?? this.token,
      tokensList: tokensList ?? this.tokensList,
      message: message ?? this.message,
    );
  }
}

class DeviceTokenNotifier extends StateNotifier<DeviceTokenState> {
  final Ref ref;
  DeviceTokenNotifier(this.ref) : super(DeviceTokenState());

  Future<void> fetchDeviceToken() async {
    debugPrint('🔍 Fetching device token...');
    final token = await PushNotificationService.getDeviceToken();
    if (token != null) {
      debugPrint('✅ Device token fetched: ${token.substring(0, 20)}...');
    } else {
      debugPrint('⚠️ No device token available');
    }
    state = state.copyWith(token: token);
  }

  Future<void> registerDeviceToken(
      {required String userId,
      required String accessToken,
      required String platform,
      String? deviceName}) async {
    try {
      debugPrint(
        '📱 Registering device token for user: $userId on platform: $platform',
      );
      final result = await PushNotificationService.registerDeviceToken(
        userId: userId,
        accessToken: accessToken,
        platform: platform,
        deviceName: deviceName,
      );
      if (result != null) {
        debugPrint('✅ Device token registered successfully');
        // Refresh token list after successful registration
        await listDeviceTokens(userId: userId, accessToken: accessToken);
        state = state.copyWith(message: 'Device token registered');
      } else {
        debugPrint('❌ Device token registration failed - no result');
        state = state.copyWith(message: 'No token available');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Exception registering device token: $e');
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(message: 'Failed to register device token: $e');
    }
  }

  Future<void> unregisterDeviceToken(
      {required String userId, required String accessToken, required String deviceToken}) async {
    try {
      debugPrint(
        '📱 Unregistering device token for user: $userId',
      );
      await PushNotificationService.unregisterDeviceToken(
        userId: userId,
        accessToken: accessToken,
        deviceToken: deviceToken,
      );
      debugPrint('✅ Device token unregistered successfully');
      // Refresh token list after removal
      await listDeviceTokens(userId: userId, accessToken: accessToken);
      state = state.copyWith(message: 'Device token unregistered');
    } catch (e, stackTrace) {
      debugPrint('❌ Exception unregistering device token: $e');
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(message: 'Failed to unregister device token: $e');
    }
  }

  Future<void> listDeviceTokens({required String userId, required String accessToken}) async {
    final tokens = await PushNotificationService.listDeviceTokens(
      userId: userId,
      accessToken: accessToken,
    );
    state = state.copyWith(tokensList: tokens);
  }
}
