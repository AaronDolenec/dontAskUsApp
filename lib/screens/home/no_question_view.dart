import 'package:flutter/material.dart';

import '../../utils/utils.dart';

class NoQuestionView extends StatelessWidget {
  final VoidCallback? onRefresh;

  const NoQuestionView({
    super.key,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.question_mark_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No question today',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "There's no question for today yet.\nCheck back later!",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
