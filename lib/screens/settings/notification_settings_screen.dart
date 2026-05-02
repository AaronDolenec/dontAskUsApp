import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification_settings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_token_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  NotificationSettings? _settings;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    final fetched = await ref.read(authProvider.notifier).fetchNotificationSettings();
    setState(() {
      _settings = fetched ??
          NotificationSettings(
            pushNotificationsEnabled: false,
            emailOnNewQuestion: false,
            emailOnReminder: false,
          );
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_settings == null) return;
    setState(() => _loading = true);

    try {
      // If push notifications are being enabled, register device token first
      if (_settings!.pushNotificationsEnabled && !(await _isPushAlreadyRegistered())) {
        final registered = await _registerDeviceToken();
        if (!registered) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              'Failed to register device for push notifications. Check logs.',
            ),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 5),
          ));
          setState(() => _loading = false);
          return;
        }
      }

      final success = await ref.read(authProvider.notifier).updateNotificationSettings(_settings!);
      setState(() => _loading = false);
      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to save notification settings. Check logs.'),
          backgroundColor: AppColors.error,
        ));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Notification settings saved'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error saving notification settings: $e'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<bool> _isPushAlreadyRegistered() async {
    final user = ref.read(authProvider).user;
    return user?.groups.isNotEmpty ?? false;
  }

  Future<bool> _registerDeviceToken() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    final groupId = authState.groupId;

    if (user == null || groupId == null) {
      debugPrint('❌ No user or group found for device token registration');
      return false;
    }

    // Find the userId for this group
    String? userId;
    for (final group in user.groups) {
      if (group.groupId == groupId && group.userId.isNotEmpty) {
        userId = group.userId;
        break;
      }
    }

    if (userId == null) {
      debugPrint('❌ No user ID found for group $groupId');
      return false;
    }

    final accessToken = await AuthService.getAccessToken();
    if (accessToken == null) {
      debugPrint('❌ No access token for device token registration');
      return false;
    }

    try {
      final platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
      await ref.read(deviceTokenProvider.notifier).registerDeviceToken(
            userId: userId,
            accessToken: accessToken,
            platform: platform,
          );
      return true;
    } catch (e) {
      debugPrint('❌ Exception registering device token: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _settings == null
              ? const Center(child: Text('Unable to load settings'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Push notifications'),
                        subtitle: const Text('Enable Firebase push messages'),
                        value: _settings!.pushNotificationsEnabled,
                        onChanged: (v) {
                          setState(() {
                            _settings = _settings!.copyWith(
                              pushNotificationsEnabled: v,
                            );
                          });
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Email on new question'),
                        subtitle: const Text(
                          'Get an email whenever a new daily question is available',
                        ),
                        value: _settings!.emailOnNewQuestion,
                        onChanged: (v) {
                          setState(() {
                            _settings = _settings!.copyWith(
                              emailOnNewQuestion: v,
                            );
                          });
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Email reminders'),
                        subtitle: const Text(
                          'Get reminder emails if you have not answered yet',
                        ),
                        value: _settings!.emailOnReminder,
                        onChanged: (v) {
                          setState(() {
                            _settings = _settings!.copyWith(
                              emailOnReminder: v,
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _save,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
