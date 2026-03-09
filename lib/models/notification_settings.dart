class NotificationSettings {
  final bool pushNotificationsEnabled;
  final bool emailOnNewQuestion;
  final bool emailOnReminder;
  final String? displayName;
  final String? avatarFilename;

  NotificationSettings({
    required this.pushNotificationsEnabled,
    required this.emailOnNewQuestion,
    required this.emailOnReminder,
    this.displayName,
    this.avatarFilename,
  });

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return false;
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final parser = NotificationSettings(
      pushNotificationsEnabled: false,
      emailOnNewQuestion: false,
      emailOnReminder: false,
    );

    return NotificationSettings(
      pushNotificationsEnabled:
          parser._asBool(json['push_notifications_enabled']),
      emailOnNewQuestion: parser._asBool(json['email_on_new_question']),
      emailOnReminder: parser._asBool(json['email_on_reminder']),
      displayName: json['display_name'] as String?,
      avatarFilename: json['avatar_filename'] as String?,
    );
  }

  NotificationSettings copyWith({
    bool? pushNotificationsEnabled,
    bool? emailOnNewQuestion,
    bool? emailOnReminder,
    String? displayName,
    String? avatarFilename,
  }) {
    return NotificationSettings(
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailOnNewQuestion: emailOnNewQuestion ?? this.emailOnNewQuestion,
      emailOnReminder: emailOnReminder ?? this.emailOnReminder,
      displayName: displayName ?? this.displayName,
      avatarFilename: avatarFilename ?? this.avatarFilename,
    );
  }

  Map<String, dynamic> toJson() => {
        'push_notifications_enabled': pushNotificationsEnabled,
        'email_on_new_question': emailOnNewQuestion,
        'email_on_reminder': emailOnReminder,
      };
}
