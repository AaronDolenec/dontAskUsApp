import 'package:flutter_test/flutter_test.dart';
import 'package:dont_ask_us/models/notification_settings.dart';

void main() {
  group('NotificationSettings', () {
    test('parses API settings response fields', () {
      final model = NotificationSettings.fromJson({
        'display_name': 'Alice',
        'avatar_filename': 'alice.webp',
        'email_on_new_question': true,
        'email_on_reminder': false,
        'push_notifications_enabled': true,
      });

      expect(model.displayName, 'Alice');
      expect(model.avatarFilename, 'alice.webp');
      expect(model.emailOnNewQuestion, isTrue);
      expect(model.emailOnReminder, isFalse);
      expect(model.pushNotificationsEnabled, isTrue);
    });

    test('defaults to false booleans when fields are missing', () {
      final model = NotificationSettings.fromJson({});

      expect(model.emailOnNewQuestion, isFalse);
      expect(model.emailOnReminder, isFalse);
      expect(model.pushNotificationsEnabled, isFalse);
    });

    test('serializes update payload keys expected by API', () {
      final model = NotificationSettings(
        pushNotificationsEnabled: true,
        emailOnNewQuestion: false,
        emailOnReminder: true,
      );

      expect(model.toJson(), {
        'push_notifications_enabled': true,
        'email_on_new_question': false,
        'email_on_reminder': true,
      });
    });
  });
}
