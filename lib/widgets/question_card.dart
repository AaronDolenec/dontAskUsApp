import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/app_colors.dart';
import 'answer_details_section.dart';

/// Card displaying the daily question
class QuestionCard extends StatelessWidget {
  final DailyQuestion question;
  final Widget? votingWidget;
  final Widget? resultsWidget;

  const QuestionCard({
    super.key,
    required this.question,
    this.votingWidget,
    this.resultsWidget,
  });

  String get _questionTypeLabel {
    switch (question.questionType) {
      case QuestionType.binaryVote:
        return 'Yes/No Vote';
      case QuestionType.singleChoice:
        return 'Single Choice';
      case QuestionType.freeText:
        return 'Free Response';
      case QuestionType.memberChoice:
        return 'Vote for Someone';
      case QuestionType.duoChoice:
        return 'Vote for a Pair';
    }
  }

  IconData get _questionTypeIcon {
    switch (question.questionType) {
      case QuestionType.binaryVote:
        return Icons.thumbs_up_down;
      case QuestionType.singleChoice:
        return Icons.radio_button_checked;
      case QuestionType.freeText:
        return Icons.edit_note;
      case QuestionType.memberChoice:
        return Icons.person;
      case QuestionType.duoChoice:
        return Icons.people;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question type badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _questionTypeIcon,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _questionTypeLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (question.allowMultiple)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Multi-select',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Featured member badge (for {member} placeholder questions)
            if (question.featuredMember != null) ...[
              FeaturedMemberBadge(memberName: question.featuredMember!),
              const SizedBox(height: 12),
            ],

            // Question text
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 20),

            // Voting or Results widget
            if (question.hasUserVoted && resultsWidget != null)
              resultsWidget!
            else if (votingWidget != null)
              votingWidget!,

            // Vote count
            if (question.hasUserVoted && question.totalVotes > 0) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.how_to_vote,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${question.totalVotes} vote${question.totalVotes != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact question card for history – expandable to show results
class QuestionHistoryCard extends StatefulWidget {
  final DailyQuestion question;
  final VoidCallback? onTap;

  const QuestionHistoryCard({
    super.key,
    required this.question,
    this.onTap,
  });

  @override
  State<QuestionHistoryCard> createState() => _QuestionHistoryCardState();
}

class _QuestionHistoryCardState extends State<QuestionHistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final hasResults = (question.optionCounts != null &&
            question.optionCounts!.isNotEmpty &&
            question.totalVotes > 0) ||
        (question.answerDetails != null && question.answerDetails!.isNotEmpty);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: hasResults
            ? () => setState(() => _expanded = !_expanded)
            : widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date + featured member
              Row(
                children: [
                  Text(
                    _formatDate(question.questionDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textLight,
                        ),
                  ),
                  if (question.featuredMember != null) ...[
                    const SizedBox(width: 8),
                    FeaturedMemberBadge(memberName: question.featuredMember!),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // Question text
              Text(
                question.questionText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: _expanded ? null : 2,
                overflow: _expanded ? null : TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Badges + expand hint
              Row(
                children: [
                  if (question.hasUserVoted) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 14, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Answered',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${question.totalVotes} vote${question.totalVotes != 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (hasResults) ...[
                    const Spacer(),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),

              // Expandable results
              if (_expanded && hasResults) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _HistoryResultsSection(question: question),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Inline results section shown inside an expanded history card
class _HistoryResultsSection extends StatelessWidget {
  final DailyQuestion question;

  const _HistoryResultsSection({required this.question});

  @override
  Widget build(BuildContext context) {
    final optionCounts = question.optionCounts ?? {};
    final totalVotes = question.totalVotes;

    // Sort options by vote count descending, filter zeros
    final sorted = optionCounts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final bool isFreeText = question.questionType == QuestionType.freeText;

    if (sorted.isEmpty && !isFreeText) {
      return const Text(
        'No votes recorded',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    final maxCount = sorted.isNotEmpty ? sorted.first.value : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Featured member badge
        if (question.featuredMember != null) ...[
          FeaturedMemberBadge(memberName: question.featuredMember!),
          const SizedBox(height: 12),
        ],

        if (!isFreeText) ...[
          Text(
            'Results',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ...sorted.map((entry) {
            final option = entry.key;
            final count = entry.value;
            final pct = totalVotes > 0 ? (count / totalVotes * 100) : 0.0;
            final isWinner = count == maxCount;
            final barColor = isWinner ? AppColors.primary : AppColors.secondary;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isWinner)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.emoji_events,
                              size: 16, color: AppColors.warning),
                        ),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontWeight:
                                isWinner ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: barColor,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '($count)',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalVotes > 0 ? count / totalVotes : 0,
                      minHeight: 6,
                      backgroundColor: barColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        barColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],

        // Answer details — who answered what
        if (question.answerDetails != null &&
            question.answerDetails!.isNotEmpty) ...[
          const SizedBox(height: 12),
          AnswerDetailsSection(
            answerDetails: question.answerDetails!,
            questionType: question.questionType.apiValue,
            groupByOption: !isFreeText,
          ),
        ],
      ],
    );
  }
}
