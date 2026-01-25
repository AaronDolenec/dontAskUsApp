import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../utils/utils.dart';

class HistoryItem extends StatelessWidget {
  final DailyQuestion question;
  final String? userAnswer;
  final VoidCallback? onTap;

  const HistoryItem({
    super.key,
    required this.question,
    this.userAnswer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildQuestionText(context),
              const SizedBox(height: 12),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today,
                size: 12,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(question.questionDate),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        _buildQuestionTypeChip(context),
      ],
    );
  }

  Widget _buildQuestionTypeChip(BuildContext context) {
    final typeInfo = _getQuestionTypeInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            typeInfo.icon,
            size: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 4),
          Text(
            typeInfo.label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionText(BuildContext context) {
    return Text(
      question.questionText,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter(BuildContext context) {
    final totalVotes = _getTotalVotes();
    final hasVoted = userAnswer != null;

    return Row(
      children: [
        // User's answer
        if (hasVoted) ...[
          const Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'You answered: $userAnswer',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ] else ...[
          Icon(
            Icons.cancel_outlined,
            size: 16,
            color:
                Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 6),
          Text(
            'Not answered',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.5),
                ),
          ),
          const Spacer(),
        ],
        // Vote count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.how_to_vote,
                size: 12,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                '$totalVotes vote${totalVotes == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final questionDate = DateTime(date.year, date.month, date.day);

    if (questionDate == today) {
      return 'Today';
    } else if (questionDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  int _getTotalVotes() {
    final optionCounts = question.optionCounts;
    if (optionCounts == null) return 0;
    return optionCounts.values.fold(0, (sum, count) => sum + count);
  }

  _QuestionTypeInfo _getQuestionTypeInfo() {
    switch (question.questionType) {
      case QuestionType.binaryVote:
        return _QuestionTypeInfo(Icons.thumbs_up_down, 'Yes/No');
      case QuestionType.singleChoice:
        return _QuestionTypeInfo(Icons.radio_button_checked, 'Choice');
      case QuestionType.freeText:
        return _QuestionTypeInfo(Icons.text_fields, 'Text');
      case QuestionType.memberChoice:
        return _QuestionTypeInfo(Icons.person, 'Member');
      case QuestionType.duoChoice:
        return _QuestionTypeInfo(Icons.people, 'Duo');
    }
  }
}

class _QuestionTypeInfo {
  final IconData icon;
  final String label;

  _QuestionTypeInfo(this.icon, this.label);
}
