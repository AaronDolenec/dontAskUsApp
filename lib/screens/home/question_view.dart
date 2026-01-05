import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../utils/utils.dart';

class QuestionView extends StatelessWidget {
  final DailyQuestion question;
  final bool hasVoted;
  final VoidCallback? onRefresh;

  const QuestionView({
    super.key,
    required this.question,
    required this.hasVoted,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildQuestionText(context),
            const SizedBox(height: 8),
            _buildQuestionTypeIndicator(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                "Today's Question",
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        if (hasVoted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  'Voted',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionText(BuildContext context) {
    return Text(
      question.questionText,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
    );
  }

  Widget _buildQuestionTypeIndicator(BuildContext context) {
    final typeInfo = _getQuestionTypeInfo();

    return Row(
      children: [
        Icon(
          typeInfo.icon,
          size: 16,
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Text(
          typeInfo.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withOpacity(0.6),
              ),
        ),
        if (question.allowMultiple) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Multiple answers',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.secondary,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  _QuestionTypeInfo _getQuestionTypeInfo() {
    switch (question.questionType) {
      case QuestionType.binaryVote:
        return _QuestionTypeInfo(Icons.thumbs_up_down, 'Yes or No');
      case QuestionType.singleChoice:
        return _QuestionTypeInfo(Icons.radio_button_checked, 'Choose one');
      case QuestionType.freeText:
        return _QuestionTypeInfo(Icons.text_fields, 'Free text');
      case QuestionType.memberChoice:
        return _QuestionTypeInfo(Icons.person, 'Vote for a member');
      case QuestionType.duoChoice:
        return _QuestionTypeInfo(Icons.people, 'Vote for a pair');
    }
  }
}

class _QuestionTypeInfo {
  final IconData icon;
  final String label;

  _QuestionTypeInfo(this.icon, this.label);
}
