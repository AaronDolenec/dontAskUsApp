class NotificationSettings {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool pushForAllGroups;

  NotificationSettings({
    required this.pushEnabled,
    required this.emailEnabled,
    required this.pushForAllGroups,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushEnabled: json['push_enabled'] as bool? ?? false,
      emailEnabled: json['email_enabled'] as bool? ?? false,
      pushForAllGroups: json['push_for_all_groups'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'push_enabled': pushEnabled,
        'email_enabled': emailEnabled,
        'push_for_all_groups': pushForAllGroups,
      };
}
