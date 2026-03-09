import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/group_member.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/share_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/avatar_circle.dart';
import '../groups/groups_screen.dart';
import '../onboarding/welcome_screen.dart';
import 'help_screen.dart';
import 'notification_settings_screen.dart';
import 'session_info_screen.dart';

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final groupId = authState.groupId;

    final groupInfoAsync = ref.watch(groupInfoProvider);
    final groupMembersAsync = ref.watch(groupMembersProvider);

    final membership = _currentMembership(user, groupId);
    final groupName = groupInfoAsync.valueOrNull?.name ??
        membership?.groupName ??
        'Current Group';
    final inviteCode = groupInfoAsync.valueOrNull?.inviteCode ?? '';
    final members = groupMembersAsync.valueOrNull ?? const <GroupMember>[];
    final currentMember = _resolveCurrentMember(user, membership, members);
    final memberCount = groupMembersAsync.valueOrNull?.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.groups_outlined),
          tooltip: 'All Groups',
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const GroupsScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GroupSummaryCard(
              groupName: groupName,
              inviteCode: inviteCode,
              memberCount: memberCount,
              currentMember: currentMember,
              onEditName: () => _showEditNameDialog(context, ref),
              onCopyInvite: inviteCode.isEmpty
                  ? null
                  : () => _copyInviteCode(context, inviteCode),
              onShowQr: inviteCode.isEmpty
                  ? null
                  : () => ShareInviteBottomSheet.show(
                        context,
                        inviteCode: inviteCode,
                        groupName: groupName,
                      ),
              onShareInvite: inviteCode.isEmpty
                  ? null
                  : () => ShareService.shareInviteCode(
                        inviteCode,
                        groupName: groupName,
                      ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Notification Settings'),
                    subtitle: const Text('Push and email preferences'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Session Info'),
                    subtitle: const Text('Debug and session details'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SessionInfoScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Onboarding Walkthrough'),
                    subtitle: const Text('See how the app works'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WelcomeScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.support_agent_outlined),
                    title: const Text('Help & Support'),
                    subtitle: const Text('FAQ and contact'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HelpScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: const Text('Log Out'),
                    subtitle: const Text('Sign out from this device'),
                    onTap: () => _showLogoutDialog(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.exit_to_app, color: AppColors.error),
                    title: const Text('Leave Current Group'),
                    subtitle: const Text(
                        'Remove this group from your current session'),
                    onTap: () => _showLeaveGroupDialog(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever,
                        color: AppColors.error),
                    title: const Text('Delete Current Group'),
                    subtitle: const Text('Only available for group creator'),
                    onTap: () => _showDeleteGroupDialog(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  UserGroupMembership? _currentMembership(User? user, String? groupId) {
    if (user == null || groupId == null) return null;
    for (final membership in user.groups) {
      if (membership.groupId == groupId) return membership;
    }
    return null;
  }

  GroupMember? _resolveCurrentMember(
    User? user,
    UserGroupMembership? membership,
    List<GroupMember> members,
  ) {
    if (membership != null) {
      for (final m in members) {
        if (m.userId == membership.userId) return m;
      }
      for (final m in members) {
        if (m.displayName == membership.displayName) return m;
      }
    }

    if (user != null) {
      return GroupMember(
        userId: user.oderId,
        displayName: user.displayName,
        colorAvatar: user.colorAvatar,
        avatarUrl: user.avatarUrl,
        answerStreak: user.answerStreak,
        longestAnswerStreak: user.longestAnswerStreak,
      );
    }

    return null;
  }

  Future<void> _showEditNameDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change display name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new display name'),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(ctx).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty) return;

    final success =
        await ref.read(authProvider.notifier).updateDisplayName(newName);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Display name updated' : 'Failed to update display name',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _copyInviteCode(BuildContext context, String inviteCode) async {
    final success = await ShareService.copyInviteCode(inviteCode);
    if (!context.mounted) return;
    ShareService.showCopyResult(context, success, inviteCode);
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content:
            const Text('You will need to log in again to access your groups.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const GroupsScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave group?'),
        content: const Text(
          'Are you sure you want to leave this group? You can join again later with the invite code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).leaveGroup();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const GroupsScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showDeleteGroupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete group?'),
        content: const Text(
          'This will permanently delete the group and all related data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteGroup(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authProvider);
    final groupId = authState.groupId;
    if (groupId == null) return;

    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not authenticated'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final api = ApiClient();
      final response = await api.delete(
        '/api/auth/groups/$groupId',
        accessToken: accessToken,
      );

      if (!context.mounted) return;

      if (response.statusCode == 200) {
        await ref.read(authProvider.notifier).leaveGroup();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const GroupsScreen()),
          (route) => false,
        );
      } else {
        String message = 'Failed to delete group (${response.statusCode})';
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          message = data['detail'] as String? ??
              data['message'] as String? ??
              message;
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _GroupSummaryCard extends StatelessWidget {
  final String groupName;
  final String inviteCode;
  final int? memberCount;
  final GroupMember? currentMember;
  final VoidCallback onEditName;
  final VoidCallback? onCopyInvite;
  final VoidCallback? onShowQr;
  final VoidCallback? onShareInvite;

  const _GroupSummaryCard({
    required this.groupName,
    required this.inviteCode,
    required this.memberCount,
    required this.currentMember,
    required this.onEditName,
    this.onCopyInvite,
    this.onShowQr,
    this.onShareInvite,
  });

  @override
  Widget build(BuildContext context) {
    final initials = groupName
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (currentMember != null)
                  AvatarCircle(
                    colorHex: currentMember!.colorAvatar,
                    initials: currentMember!.initials,
                    avatarUrl: currentMember!.avatarUrl,
                    size: 56,
                  )
                else
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      initials.isEmpty ? 'G' : initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        memberCount == null
                            ? 'Loading members...'
                            : '$memberCount member${memberCount == 1 ? '' : 's'}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onEditName,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Name'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Invite code',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    inviteCode.isEmpty ? 'Not available yet' : inviteCode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: onCopyInvite,
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy invite code',
                ),
                IconButton(
                  onPressed: onShowQr,
                  icon: const Icon(Icons.qr_code),
                  tooltip: 'Show QR',
                ),
                IconButton(
                  onPressed: onShareInvite,
                  icon: const Icon(Icons.share),
                  tooltip: 'Share invite',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
