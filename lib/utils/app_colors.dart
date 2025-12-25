import 'package:flutter/material.dart';

/// App color palette
class AppColors {
  // Prevent instantiation
  AppColors._();

  // ============= Primary Brand Colors =============
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);

  // ============= Secondary Colors =============
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF059669);

  // ============= Background Colors =============
  static const Color background = Color(0xFFF9FAFB);
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF374151);

  // ============= Text Colors =============
  static const Color textPrimary = Color(0xFF111827);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textLightDark = Color(0xFF6B7280);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ============= Status Colors =============
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ============= Border & Divider Colors =============
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color dividerDark = Color(0xFF374151);

  // ============= Voting/Results Colors =============
  static const List<Color> voteColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Yellow/Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
  ];

  // ============= Avatar Colors =============
  static const List<Color> avatarColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Yellow
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
    Color(0xFF84CC16), // Lime
    Color(0xFF14B8A6), // Teal
    Color(0xFFA855F7), // Violet
    Color(0xFFE11D48), // Rose
  ];

  // ============= Streak Colors =============
  static const Color streakActive = Color(0xFFF97316);
  static const Color streakActiveBackground = Color(0xFFFFF7ED);
  static const Color streakInactive = Color(0xFF9CA3AF);
  static const Color streakInactiveBackground = Color(0xFFF3F4F6);

  // ============= Helper Methods =============

  /// Get a color from hex string (e.g., "#3B82F6")
  static Color fromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Convert color to hex string
  static String toHex(Color color, {bool withHash = true}) {
    final hex = color.toARGB32().toRadixString(16).substring(2).toUpperCase();
    return withHash ? '#$hex' : hex;
  }

  /// Get vote color by index (cycles through voteColors)
  static Color getVoteColor(int index) {
    return voteColors[index % voteColors.length];
  }

  /// Get avatar color by index (cycles through avatarColors)
  static Color getAvatarColor(int index) {
    return avatarColors[index % avatarColors.length];
  }

  /// Get contrasting text color for a background color
  static Color getContrastingTextColor(Color backgroundColor) {
    // Calculate luminance
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimary : textOnPrimary;
  }
}
