/// App-wide constants
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // ============= App Info =============
  static const String appName = 'dontAskUs';
  static const String appVersion = '1.0.0';

  // ============= Validation =============
  static const int minDisplayNameLength = 1;
  static const int maxDisplayNameLength = 50;
  static const int inviteCodeLength = 6;
  static const int maxGroupNameLength = 100;

  // ============= Animation Durations =============
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // ============= Cache Durations =============
  static const Duration questionCacheMaxAge = Duration(hours: 1);
  static const Duration membersCacheMaxAge = Duration(minutes: 30);
  static const Duration groupInfoCacheMaxAge = Duration(hours: 24);

  // ============= UI Constants =============
  static const double borderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 40.0;
  static const double avatarSizeLarge = 56.0;
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // ============= Spacing =============
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ============= Default Values =============
  static const String defaultAvatarColor = '#3B82F6';
  
  // ============= Regex Patterns =============
  static final RegExp hexColorPattern = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
  static final RegExp inviteCodePattern = RegExp(r'^[A-Z0-9]{6,8}$');
}
