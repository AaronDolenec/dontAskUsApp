import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification_settings.dart';
import '../../providers/auth_provider.dart';
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
      // If enabling push notifications on web, request permission first
      if (kIsWeb && _settings!.pushNotificationsEnabled) {
        debugPrint(
          '🌐 Web app: requesting browser notification permission before saving',
        );
        final permissionGranted =
            await ref.read(authProvider.notifier).requestNotificationPermission();
        if (!permissionGranted) {
          setState(() => _loading = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              'Browser notification permission denied. Please allow notifications in your browser settings to receive push messages.',
            ),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 6),
          ));
          return;
        }
      }

      final success =
          await ref.read(authProvider.notifier).updateNotificationSettings(_settings!);
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

  Future<void> _sendTestNotification() async {
    setState(() => _loading = true);
    final success = await ref.read(authProvider.notifier).sendTestNotification();
    setState(() => _loading = false);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Failed to send test notification. Check logs and ensure push notifications are enabled.'),
        backgroundColor: AppColors.error,
        duration: Duration(seconds: 5),
      ));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Test notification sent! Check your device.'),
      backgroundColor: AppColors.success,
    ));
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _save,
                            child: const Text('Save'),
                          ),
                          OutlinedButton(
                            onPressed:
                                _settings!.pushNotificationsEnabled ? _sendTestNotification : null,
                            child: const Text('Send Test Notification'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
