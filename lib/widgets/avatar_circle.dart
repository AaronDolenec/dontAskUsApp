import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// A circular avatar with a solid color background or an uploaded image
class AvatarCircle extends StatelessWidget {
  final String colorHex;
  final String? initials;
  final String? avatarUrl;
  final double size;
  final bool showBorder;
  final Color? borderColor;

  const AvatarCircle({
    super.key,
    required this.colorHex,
    this.initials,
    this.avatarUrl,
    this.size = 40,
    this.showBorder = false,
    this.borderColor,
  });

  bool get _hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(colorHex);

    if (_hasAvatar) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(
                  color: borderColor ?? Colors.white,
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            avatarUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildColorFallback(color),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: borderColor ?? Colors.white,
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: initials != null
          ? Center(
              child: Text(
                initials!.toUpperCase(),
                style: TextStyle(
                  color: AppColors.getContrastingTextColor(color),
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.4,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildColorFallback(Color color) {
    return Container(
      width: size,
      height: size,
      color: color,
      child: initials != null
          ? Center(
              child: Text(
                initials!.toUpperCase(),
                style: TextStyle(
                  color: AppColors.getContrastingTextColor(color),
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.4,
                ),
              ),
            )
          : null,
    );
  }
}

/// Avatar with name label
class AvatarWithName extends StatelessWidget {
  final String colorHex;
  final String displayName;
  final String? avatarUrl;
  final double avatarSize;
  final TextStyle? nameStyle;
  final bool vertical;

  const AvatarWithName({
    super.key,
    required this.colorHex,
    required this.displayName,
    this.avatarUrl,
    this.avatarSize = 40,
    this.nameStyle,
    this.vertical = false,
  });

  String get _initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return displayName.substring(0, displayName.length >= 2 ? 2 : 1);
  }

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarCircle(
            colorHex: colorHex,
            initials: _initials,
            avatarUrl: avatarUrl,
            size: avatarSize,
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            style: nameStyle ?? Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AvatarCircle(
          colorHex: colorHex,
          initials: _initials,
          avatarUrl: avatarUrl,
          size: avatarSize,
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            displayName,
            style: nameStyle ?? Theme.of(context).textTheme.bodyLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
