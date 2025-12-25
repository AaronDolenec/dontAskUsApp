import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Badge displaying streak count with fire emoji
class StreakBadge extends StatelessWidget {
  final int streak;
  final bool showLongest;
  final int? longestStreak;
  final double fontSize;
  final bool compact;

  const StreakBadge({
    super.key,
    required this.streak,
    this.showLongest = false,
    this.longestStreak,
    this.fontSize = 14,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = streak > 0;
    final bgColor = isActive 
        ? AppColors.streakActiveBackground 
        : AppColors.streakInactiveBackground;
    final textColor = isActive 
        ? AppColors.streakActive 
        : AppColors.streakInactive;
    
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isActive ? '🔥' : '💤',
              style: TextStyle(fontSize: fontSize),
            ),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isActive ? '🔥' : '💤',
            style: TextStyle(fontSize: fontSize),
          ),
          const SizedBox(width: 6),
          Text(
            '$streak day${streak != 1 ? 's' : ''}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: fontSize,
            ),
          ),
          if (showLongest && longestStreak != null && longestStreak! > streak) ...[
            const SizedBox(width: 8),
            Text(
              '(best: $longestStreak)',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: fontSize * 0.85,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Large streak display for home screen
class StreakDisplay extends StatelessWidget {
  final int streak;
  final int? longestStreak;

  const StreakDisplay({
    super.key,
    required this.streak,
    this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = streak > 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isActive 
                    ? AppColors.streakActiveBackground 
                    : AppColors.streakInactiveBackground,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  isActive ? '🔥' : '💤',
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Streak',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$streak day${streak != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.streakActive : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (longestStreak != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Best',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  Text(
                    '$longestStreak',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
