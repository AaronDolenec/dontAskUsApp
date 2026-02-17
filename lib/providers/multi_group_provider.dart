import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/utils.dart';

/// Provider for managing multiple groups
class MultiGroupNotifier extends StateNotifier<MultiGroupState> {
  Timer? _refreshTimer;

  MultiGroupNotifier() : super(const MultiGroupState()) {
    _loadGroups();
  }

  /// Start periodic refresh (call from screen)
  void startPeriodicRefresh({Duration interval = const Duration(seconds: 30)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) {
      if (mounted) _loadGroups(silent: true);
    });
  }

  /// Stop periodic refresh
  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _loadGroups({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true);
    }

    try {
      final accessToken = await AuthService.getAccessToken();
      final api = ApiClient();

      // 1) Fetch fresh group list from server via /api/auth/me
      List<String> groupIds = await AuthService.getGroupsList();
      if (accessToken != null) {
        try {
          final meResponse =
              await api.get('/api/auth/me', accessToken: accessToken);
          if (meResponse.statusCode == 200) {
            final meData = jsonDecode(meResponse.body) as Map<String, dynamic>;
            final serverGroups = meData['groups'] as List? ??
                (meData['account'] is Map ? [] : []);
            // Also check top-level groups or account.groups
            final accountGroups = (meData['account'] is Map &&
                    (meData['account'] as Map).containsKey('groups'))
                ? (meData['account'] as Map)['groups'] as List? ?? []
                : serverGroups;
            final groupsList =
                serverGroups.isNotEmpty ? serverGroups : accountGroups;

            // Sync server groups to local storage
            final serverGroupIds = <String>[];
            for (final g in groupsList) {
              if (g is Map<String, dynamic>) {
                final gId = (g['group_id'] ?? '').toString();
                if (gId.isNotEmpty) {
                  serverGroupIds.add(gId);
                  await AuthService.saveGroupMembership(
                    groupId: gId,
                    userId: (g['user_id'] ?? '').toString(),
                    displayName: g['display_name'] as String? ?? '',
                    groupName: g['group_name'] as String?,
                  );
                }
              }
            }
            if (serverGroupIds.isNotEmpty) {
              groupIds = serverGroupIds;
            }
          }
        } catch (e) {
          debugPrint('DEBUG: Failed to fetch /api/auth/me for groups: $e');
          // Fall back to local storage groups
        }
      }

      final currentGroupId = await AuthService.getCurrentGroupId();

      // 2) For each group, load name + streak
      final groups = <GroupInfo>[];
      for (final groupId in groupIds) {
        final groupName = await AuthService.getGroupName(groupId);
        final displayName = await AuthService.getDisplayName(groupId);

        // Fetch the user's streak from the members endpoint
        int streak = 0;
        try {
          final userId = await AuthService.getUserId(groupId);
          if (accessToken != null && userId != null) {
            final response = await api.get(
              '/api/groups/$groupId/members',
              accessToken: accessToken,
            );
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              final List members = data is List
                  ? data
                  : (data is Map && data.containsKey('members')
                      ? data['members'] as List
                      : []);
              for (final m in members) {
                if (m['user_id'] == userId) {
                  streak = m['answer_streak'] as int? ?? 0;
                  break;
                }
              }
            }
          }
        } catch (_) {
          // Streak fetch failed, default to 0
        }

        groups.add(GroupInfo(
          groupId: groupId,
          groupName: groupName ?? displayName ?? 'Unknown Group',
          answerStreak: streak,
        ));
      }

      state = state.copyWith(
        groups: groups,
        currentGroupId: currentGroupId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> switchGroup(String groupId) async {
    if (groupId == state.currentGroupId) return;

    state = state.copyWith(isLoading: true);

    try {
      await AuthService.setCurrentGroup(groupId);
      state = state.copyWith(
        currentGroupId: groupId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> removeGroup(String groupId) async {
    try {
      await AuthService.clearSession(groupId);
      await _loadGroups();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() async {
    await _loadGroups();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// State for multi-group management
class MultiGroupState {
  final List<GroupInfo> groups;
  final String? currentGroupId;
  final bool isLoading;
  final String? error;

  const MultiGroupState({
    this.groups = const [],
    this.currentGroupId,
    this.isLoading = false,
    this.error,
  });

  MultiGroupState copyWith({
    List<GroupInfo>? groups,
    String? currentGroupId,
    bool? isLoading,
    String? error,
  }) {
    return MultiGroupState(
      groups: groups ?? this.groups,
      currentGroupId: currentGroupId ?? this.currentGroupId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  GroupInfo? get currentGroup {
    if (currentGroupId == null) return null;
    try {
      return groups.firstWhere((g) => g.groupId == currentGroupId);
    } catch (_) {
      return null;
    }
  }
}

/// Basic group info for multi-group list
class GroupInfo {
  final String groupId;
  final String groupName;
  final String? inviteCode;
  final int answerStreak;

  const GroupInfo({
    required this.groupId,
    required this.groupName,
    this.inviteCode,
    this.answerStreak = 0,
  });

  factory GroupInfo.fromJson(Map<String, dynamic> json) {
    return GroupInfo(
      groupId: json['group_id'] as String,
      groupName: json['group_name'] as String,
      inviteCode: json['invite_code'] as String?,
      answerStreak: json['answer_streak'] as int? ?? 0,
    );
  }
}

/// Provider for multi-group state
final multiGroupProvider =
    StateNotifierProvider<MultiGroupNotifier, MultiGroupState>((ref) {
  return MultiGroupNotifier();
});

/// Widget for selecting between groups
class GroupSelectorSheet extends ConsumerWidget {
  const GroupSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GroupSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(multiGroupProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Groups',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: () => _joinNewGroup(context),
                    icon: const Icon(Icons.add),
                    tooltip: 'Join another group',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else if (state.groups.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.group_off,
                      size: 48,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No groups yet',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.groups.length,
                itemBuilder: (context, index) {
                  final group = state.groups[index];
                  final isSelected = group.groupId == state.currentGroupId;

                  return _GroupListItem(
                    group: group,
                    isSelected: isSelected,
                    onTap: () => _selectGroup(context, ref, group.groupId),
                    onLongPress: () => _showGroupOptions(context, ref, group),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _selectGroup(BuildContext context, WidgetRef ref, String groupId) {
    ref.read(multiGroupProvider.notifier).switchGroup(groupId);
    Navigator.pop(context);

    // Reload auth state for new group
    ref.read(authProvider.notifier).reloadSession();

    // Trigger refresh of data for new group
    ref.invalidate(groupInfoProvider);
    ref.invalidate(questionProvider);
    ref.invalidate(groupMembersProvider);
  }

  void _joinNewGroup(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/join');
  }

  void _showGroupOptions(BuildContext context, WidgetRef ref, GroupInfo group) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Invite Code'),
              onTap: () {
                Navigator.pop(context);
                if (group.inviteCode != null) {
                  ShareService.shareInviteCode(
                    group.inviteCode!,
                    groupName: group.groupName,
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Leave Group',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmLeaveGroup(context, ref, group);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLeaveGroup(
      BuildContext context, WidgetRef ref, GroupInfo group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group?'),
        content: Text('Are you sure you want to leave "${group.groupName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(multiGroupProvider.notifier).removeGroup(group.groupId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

class _GroupListItem extends StatelessWidget {
  final GroupInfo group;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _GroupListItem({
    required this.group,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            group.groupName.isNotEmpty ? group.groupName[0].toUpperCase() : '?',
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
      title: Text(
        group.groupName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : const Icon(Icons.chevron_right),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
