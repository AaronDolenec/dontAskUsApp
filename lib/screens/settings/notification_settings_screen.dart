import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification_settings.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  NotificationSettings? _settings;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    final fetched =
        await ref.read(authProvider.notifier).fetchNotificationSettings();
    setState(() {
      _settings = fetched ??
          NotificationSettings(
            pushEnabled: false,
            emailEnabled: false,
            pushForAllGroups: false,
          );
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_settings == null) return;
    setState(() => _loading = true);
    final success = await ref
        .read(authProvider.notifier)
        .updateNotificationSettings(_settings!);
    setState(() => _loading = false);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to save notification settings'),
        backgroundColor: AppColors.error,
      ));
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
                        title: const Text('Push notifications for this group'),
                        value: _settings!.pushEnabled,
                        onChanged: (v) {
                          setState(() {
                            _settings = NotificationSettings(
                              pushEnabled: v,
                              emailEnabled: _settings!.emailEnabled,
                              pushForAllGroups: _settings!.pushForAllGroups,
                            );
                          });
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Push notifications for all groups'),
                        value: _settings!.pushForAllGroups,
                        onChanged: (v) {
                          setState(() {
                            _settings = NotificationSettings(
                              pushEnabled: _settings!.pushEnabled,
                              emailEnabled: _settings!.emailEnabled,
                              pushForAllGroups: v,
                            );
                          });
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Email notifications'),
                        value: _settings!.emailEnabled,
                        onChanged: (v) {
                          setState(() {
                            _settings = NotificationSettings(
                              pushEnabled: _settings!.pushEnabled,
                              emailEnabled: v,
                              pushForAllGroups: _settings!.pushForAllGroups,
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
