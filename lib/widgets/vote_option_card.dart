import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Card for displaying a voting option
class VoteOptionCard extends StatelessWidget {
  final String option;
  final int? voteCount;
  final int? totalVotes;
  final bool isSelected;
  final bool showResults;
  final bool isWinner;
  final Color? color;
  final VoidCallback? onTap;
  final bool isLoading;

  const VoteOptionCard({
    super.key,
    required this.option,
    this.voteCount,
    this.totalVotes,
    this.isSelected = false,
    this.showResults = false,
    this.isWinner = false,
    this.color,
    this.onTap,
    this.isLoading = false,
  });

  double get _percentage {
    if (totalVotes == null || totalVotes == 0 || voteCount == null) return 0;
    return (voteCount! / totalVotes!) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final optionColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: showResults ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? optionColor.withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? optionColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: optionColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Progress bar background
                  if (showResults)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          width: constraints.maxWidth * (_percentage / 100),
                          decoration: BoxDecoration(
                            color: optionColor.withValues(
                                alpha: isWinner ? 0.2 : 0.1),
                          ),
                        ),
                      ),
                    ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Selection indicator
                        if (!showResults)
                          Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isSelected ? optionColor : AppColors.border,
                                width: 2,
                              ),
                              color:
                                  isSelected ? optionColor : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),

                        // Winner badge
                        if (showResults && isWinner)
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),

                        // Option text
                        Expanded(
                          child: Text(
                            option,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: isSelected || isWinner
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected ? optionColor : null,
                                    ),
                          ),
                        ),

                        // Loading indicator
                        if (isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        // Vote count and percentage
                        else if (showResults && voteCount != null) ...[
                          Text(
                            '${_percentage.toStringAsFixed(0)}%',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isWinner
                                          ? optionColor
                                          : AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '($voteCount)',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textLight,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Simple option chip for multiple selection
class VoteOptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback? onTap;

  const VoteOptionChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
