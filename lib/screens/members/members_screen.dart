import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/group_provider.dart';
import '../../models/group.dart';
import '../../models/group_member.dart';
import '../../utils/app_colors.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/error_display.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/streak_badge.dart';
import '../groups/groups_screen.dart';

/// Screen displaying group members
class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  bool _sortByStreak = true;

  @override
  void initState() {
    super.initState();
    // Force a fresh fetch of members every time the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(groupMembersProvider);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(groupMembersProvider);
    final sortedMembers = _sortByStreak
        ? ref.watch(membersByStreakProvider)
        : ref.watch(membersByNameProvider);
    final groupInfoAsync = ref.watch(groupInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        leading: IconButton(
          icon: const Icon(Icons.groups_outlined),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const GroupsScreen()),
              (route) => false,
            );
          },
          tooltip: 'All Groups',
        ),
        actions: [
          PopupMenuButton<bool>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (value) {
              setState(() {
                _sortByStreak = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: true,
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: _sortByStreak ? AppColors.primary : null,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sort by Streak',
                      style: TextStyle(
                        color: _sortByStreak ? AppColors.primary : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: false,
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      color: !_sortByStreak ? AppColors.primary : null,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sort by Name',
                      style: TextStyle(
                        color: !_sortByStreak ? AppColors.primary : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const MemberListSkeleton(),
        error: (error, _) => ErrorDisplay(
          message: 'Failed to load members',
          details: error.toString(),
          onRetry: () => ref.refresh(groupMembersProvider),
        ),
        data: (members) {
          if (members.isEmpty) {
            return const EmptyStateDisplay(
              title: 'No Members Yet',
              subtitle: 'Share the invite code to get people to join!',
              icon: Icons.people_outline,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(groupMembersProvider);
              await ref.read(groupMembersProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sortedMembers.length + 1, // +1 for header
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Header with group info
                  return groupInfoAsync.when(
                    data: (group) =>
                        group != null ? _buildHeader(group) : const SizedBox(),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  );
                }

                final member = sortedMembers[index - 1];
                final rank = _sortByStreak ? index : null;

                return _MemberListItem(
                  member: member,
                  rank: rank,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Group group) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.group, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${group.memberCount} member${group.memberCount != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberListItem extends StatelessWidget {
  final GroupMember member;
  final int? rank;

  const _MemberListItem({
    required this.member,
    this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rank != null && rank! <= 3)
              SizedBox(
                width: 28,
                child: Text(
                  _getRankEmoji(rank!),
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              )
            else if (rank != null)
              SizedBox(
                width: 28,
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (rank != null) const SizedBox(width: 8),
            AvatarCircle(
              colorHex: member.colorAvatar,
              initials: member.initials,
              avatarUrl: member.avatarUrl,
              size: 48,
            ),
          ],
        ),
        title: Text(
          member.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Best: ${member.longestAnswerStreak} days',
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 12,
          ),
        ),
        trailing: StreakBadge(
          streak: member.answerStreak,
          compact: true,
        ),
      ),
    );
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }
}
