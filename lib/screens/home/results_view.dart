import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../utils/utils.dart';

class ResultsView extends StatelessWidget {
  final DailyQuestion question;
  final List<GroupMember> members;
  final String? userAnswer;

  const ResultsView({
    super.key,
    required this.question,
    required this.members,
    this.userAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultsHeader(context),
        const SizedBox(height: 16),
        _buildResultsList(context),
        if (userAnswer != null) ...[
          const SizedBox(height: 16),
          _buildUserAnswerSection(context),
        ],
      ],
    );
  }

  Widget _buildResultsHeader(BuildContext context) {
    final totalVotes = _getTotalVotes();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Results',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$totalVotes vote${totalVotes == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsList(BuildContext context) {
    final optionCounts = question.optionCounts;
    if (optionCounts == null || optionCounts.isEmpty) {
      return _buildNoResultsMessage(context);
    }

    // Sort by vote count
    final sortedResults = optionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalVotes = _getTotalVotes();
    final maxVotes = sortedResults.isNotEmpty ? sortedResults.first.value : 0;

    return Column(
      children: sortedResults.map((entry) {
        final option = entry.key;
        final voteCount = entry.value;
        final percentage =
            totalVotes > 0 ? (voteCount / totalVotes * 100) : 0.0;
        final isWinning = voteCount == maxVotes && maxVotes > 0;

        // For member choices, resolve member names
        final displayOption = _resolveOptionDisplay(option);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ResultBar(
            option: displayOption,
            voteCount: voteCount,
            percentage: percentage,
            isWinning: isWinning,
            isUserAnswer: userAnswer == option,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoResultsMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.how_to_vote_outlined,
            size: 48,
            color:
                Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No votes yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to vote!',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildUserAnswerSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your answer',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _resolveOptionDisplay(userAnswer!),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalVotes() {
    final optionCounts = question.optionCounts;
    if (optionCounts == null) return 0;
    return optionCounts.values.fold(0, (sum, count) => sum + count);
  }

  String _resolveOptionDisplay(String option) {
    // Check if it's a member ID
    if (question.questionType == QuestionType.memberChoice ||
        question.questionType == QuestionType.duoChoice) {
      final member = members.firstWhere(
        (m) => m.userId == option,
        orElse: () => GroupMember(
          userId: option,
          displayName: option,
          colorAvatar: '#666666',
        ),
      );
      return member.displayName;
    }
    return option;
  }
}

class _ResultBar extends StatelessWidget {
  final String option;
  final int voteCount;
  final double percentage;
  final bool isWinning;
  final bool isUserAnswer;

  const _ResultBar({
    required this.option,
    required this.voteCount,
    required this.percentage,
    required this.isWinning,
    required this.isUserAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = isWinning ? AppColors.primary : AppColors.secondary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isUserAnswer ? AppColors.success : Theme.of(context).dividerColor,
          width: isUserAnswer ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          children: [
            // Background progress bar
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
              ),
            ),
            // Filled progress bar
            FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.2),
                ),
              ),
            ),
            // Content
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (isWinning)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: const Icon(
                        Icons.emoji_events,
                        size: 20,
                        color: AppColors.warning,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontWeight:
                            isWinning ? FontWeight.bold : FontWeight.w500,
                        color: isWinning ? barColor : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: barColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: barColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$voteCount',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: barColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
