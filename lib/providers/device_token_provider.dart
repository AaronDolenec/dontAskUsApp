import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/push_notification_service.dart';

final deviceTokenProvider =
    StateNotifierProvider<DeviceTokenNotifier, DeviceTokenState>((ref) {
  return DeviceTokenNotifier(ref);
});

class DeviceTokenState {
  final String? token;
  final List<dynamic>? tokensList;
  final String? message;
  DeviceTokenState({this.token, this.tokensList, this.message});

  DeviceTokenState copyWith(
      {String? token, List<dynamic>? tokensList, String? message}) {
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
    final token = await PushNotificationService.getDeviceToken();
    state = state.copyWith(token: token);
  }

  Future<void> registerDeviceToken(
      {required String userId,
      required String sessionToken,
      required String platform,
      String? deviceName}) async {
    await PushNotificationService.registerDeviceToken(
      userId: userId,
      sessionToken: sessionToken,
      platform: platform,
      deviceName: deviceName,
    );
    state = state.copyWith(message: 'Device token registered');
  }

  Future<void> unregisterDeviceToken(
      {required String userId,
      required String sessionToken,
      required String deviceToken}) async {
    await PushNotificationService.unregisterDeviceToken(
      userId: userId,
      sessionToken: sessionToken,
      deviceToken: deviceToken,
    );
    state = state.copyWith(message: 'Device token unregistered');
  }

  Future<void> listDeviceTokens(
      {required String userId, required String sessionToken}) async {
    await PushNotificationService.listDeviceTokens(
      userId: userId,
      sessionToken: sessionToken,
    );
    // TODO: Update state.tokensList with actual tokens from backend
  }
}
