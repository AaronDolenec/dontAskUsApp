import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/group_provider.dart';
import '../../models/group.dart';
import '../../models/group_member.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_motion.dart';
import '../../utils/app_routes.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/error_display.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/streak_badge.dart';
import '../../widgets/group_context_app_bar_title.dart';

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
      if (!mounted) return;
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
        title: const GroupContextAppBarTitle(title: 'Members'),
        leading: IconButton(
          icon: const Icon(Icons.groups_outlined),
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutePaths.groups,
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
      body: AnimatedSwitcher(
        duration: AppMotion.short,
        switchInCurve: AppMotion.outCurve,
        switchOutCurve: AppMotion.inCurve,
        child: membersAsync.when(
          loading: () => const KeyedSubtree(
            key: ValueKey('members-loading'),
            child: MemberListSkeleton(),
          ),
          error: (error, _) => KeyedSubtree(
            key: const ValueKey('members-error'),
            child: ErrorDisplay(
              message: 'Failed to load members',
              details: error.toString(),
              onRetry: () => ref.refresh(groupMembersProvider),
            ),
          ),
          data: (members) {
            if (members.isEmpty) {
              return const KeyedSubtree(
                key: ValueKey('members-empty'),
                child: EmptyStateDisplay(
                  title: 'No Members Yet',
                  subtitle: 'Share the invite code to get people to join!',
                  icon: Icons.people_outline,
                ),
              );
            }

            return KeyedSubtree(
              key: const ValueKey('members-list'),
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(groupMembersProvider);
                  await ref.read(groupMembersProvider.future);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: sortedMembers.length + 1, // +1 for header
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Header with group info
                      return groupInfoAsync.when(
                        data: (group) => group != null
                            ? _buildHeader(group)
                            : const SizedBox(),
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
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(Group group) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(0, 4, 0, 14),
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

class _MemberListItem extends StatefulWidget {
  final GroupMember member;
  final int? rank;

  const _MemberListItem({
    required this.member,
    this.rank,
  });

  @override
  State<_MemberListItem> createState() => _MemberListItemState();
}

class _MemberListItemState extends State<_MemberListItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _isHovering
        ? AppColors.primary.withValues(alpha: 0.3)
        : Theme.of(context).dividerColor.withValues(alpha: 0.45);

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedScale(
        scale: _isHovering ? 1.005 : 1,
        duration: AppMotion.micro,
        curve: AppMotion.hover,
        child: AnimatedContainer(
          margin: const EdgeInsets.symmetric(vertical: 4),
          duration: AppMotion.short,
          curve: AppMotion.hover,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: _isHovering
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.rank != null && widget.rank! <= 3)
                  SizedBox(
                    width: 28,
                    child: Text(
                      _getRankEmoji(widget.rank!),
                      style: const TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (widget.rank != null)
                  SizedBox(
                    width: 28,
                    child: Text(
                      '#${widget.rank}',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (widget.rank != null) const SizedBox(width: 8),
                AvatarCircle(
                  colorHex: widget.member.colorAvatar,
                  initials: widget.member.initials,
                  avatarUrl: widget.member.avatarUrl,
                  size: 48,
                ),
              ],
            ),
            title: Text(
              widget.member.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Best: ${widget.member.longestAnswerStreak} days',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
              ),
            ),
            trailing: StreakBadge(
              streak: widget.member.answerStreak,
              compact: true,
            ),
          ),
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
