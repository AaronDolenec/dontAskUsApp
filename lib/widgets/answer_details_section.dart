import 'package:flutter/material.dart';

import '../models/answer_detail.dart';
import '../utils/app_colors.dart';
import 'avatar_circle.dart';

/// Section that displays who answered what — shows each member's avatar and
/// their answer. Supports all question types.
class AnswerDetailsSection extends StatelessWidget {
  final List<AnswerDetail> answerDetails;
  final String? questionType;

  /// If true, groups answers by option (e.g. "Yes" → [Alice, Charlie]).
  final bool groupByOption;

  const AnswerDetailsSection({
    super.key,
    required this.answerDetails,
    this.questionType,
    this.groupByOption = true,
  });

  @override
  Widget build(BuildContext context) {
    if (answerDetails.isEmpty) return const SizedBox.shrink();

    if (groupByOption && questionType != 'free_text') {
      return _buildGroupedView(context);
    }
    return _buildListView(context);
  }

  /// Build a grouped view: each option shows the avatars of members who chose it.
  Widget _buildGroupedView(BuildContext context) {
    // Group members by their answer
    final Map<String, List<AnswerDetail>> grouped = {};
    for (final detail in answerDetails) {
      final answers = detail.answerList ?? [detail.answerString ?? '?'];
      for (final ans in answers) {
        grouped.putIfAbsent(ans, () => []).add(detail);
      }
    }

    // Sort by number of votes descending
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context),
        const SizedBox(height: 12),
        ...sortedEntries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GroupedOptionRow(
              option: entry.key,
              members: entry.value,
            ),
          );
        }),
      ],
    );
  }

  /// Build a flat list view: each member shown with their answer (good for
  /// free_text or when groupByOption is false).
  Widget _buildListView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context),
        const SizedBox(height: 12),
        ...answerDetails.map((detail) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AnswerDetailTile(detail: detail),
          );
        }),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.people_outline,
          size: 16,
          color: Theme.of(context)
              .textTheme
              .bodySmall
              ?.color
              ?.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 6),
        Text(
          'Who answered what',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        Text(
          '${answerDetails.length} answered',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textLight,
              ),
        ),
      ],
    );
  }
}

/// Row showing an option with stacked avatars of members who chose it.
class _GroupedOptionRow extends StatelessWidget {
  final String option;
  final List<AnswerDetail> members;

  const _GroupedOptionRow({
    required this.option,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Option label
          Text(
            option,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          // Stacked member avatars + names
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: members.map((detail) {
              return Tooltip(
                message: detail.displayName,
                child: Chip(
                  avatar: AvatarCircle(
                    colorHex: detail.colorAvatar,
                    initials: detail.initials,
                    avatarUrl: detail.avatarUrl,
                    size: 24,
                  ),
                  label: Text(
                    detail.displayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// A single tile showing a member's avatar, name, and their answer.
class _AnswerDetailTile extends StatelessWidget {
  final AnswerDetail detail;

  const _AnswerDetailTile({required this.detail});

  @override
  Widget build(BuildContext context) {
    final answerText = detail.textAnswer ?? detail.answerString ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarCircle(
            colorHex: detail.colorAvatar,
            initials: detail.initials,
            avatarUrl: detail.avatarUrl,
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (answerText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    answerText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge/tag showing the featured member for {member} placeholder questions.
class FeaturedMemberBadge extends StatelessWidget {
  final String memberName;

  const FeaturedMemberBadge({
    super.key,
    required this.memberName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            'Featuring $memberName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
