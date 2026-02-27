import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/group.dart';
import '../../models/user.dart';
import '../../models/group_member.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/share_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import '../../widgets/avatar_circle.dart';
import '../groups/groups_screen.dart';
import 'notification_settings_screen.dart';
import 'session_info_screen.dart';
import 'help_screen.dart';

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Removed unused variables per analyzer suggestion

    final authState = ref.watch(authProvider);
    final user = authState.user;
    final groupId = authState.groupId;
    final groupMembership =
        (user != null && groupId != null && user.groups.isNotEmpty)
            ? user.groups.firstWhere(
                (g) => g.groupId == groupId,
                orElse: () => UserGroupMembership(
                  userId: '',
                  groupId: '',
                  groupName: '',
                  displayName: '',
                ),
              )
            : null;
    // Convert UserGroupMembership to Group for _GroupInfoCard
    Group? group;
    if (groupMembership != null) {
      group = Group(
        id: 0,
        groupId: groupMembership.groupId,
        name: groupMembership.groupName,
        inviteCode: '',
        createdAt: DateTime.now(),
        memberCount: 0,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group != null) ...[
              _GroupInfoCard(group: group),
              const SizedBox(height: 24),
            ],
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
            ListTile(
              leading: const Icon(Icons.help_outline),
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
            const Divider(height: 32),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showLeaveGroupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group?'),
        content: const Text(
          'Are you sure you want to leave this group? '
          'You can rejoin later using the invite code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).leaveGroup();

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const GroupsScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  void _showDeleteGroupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Group?'),
        content: const Text(
          'This will permanently delete the group and all its data '
          '(members, questions, answers). This cannot be undone.\n\n'
          'Only the group creator can delete a group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not authenticated'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final api = ApiClient();
      final response = await api.delete(
        '/api/admin/groups/$groupId',
        accessToken: accessToken,
      );

      if (!context.mounted) return;

      if (response.statusCode == 200) {
        // Clean up local data
        await AuthService.clearSession(groupId);
        await ref.read(authProvider.notifier).leaveGroup();

        if (context.mounted) {
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
        }
      } else {
        String message;
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          message = data['detail'] as String? ??
              data['message'] as String? ??
              'Failed to delete group';
        } catch (_) {
          message = response.statusCode == 403
              ? 'Only the group creator can delete this group'
              : response.statusCode == 404
                  ? 'Group not found'
                  : 'Failed to delete group (${response.statusCode})';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ignore: unused_element
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('dontAskUs'),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A group-based daily question and voting platform. '
              'Answer questions, vote with your friends, and maintain your streak!',
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            Text(
              '© 2026 dontAskUs',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 4),
            Text(
              'Licensed under Creative Commons',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _GroupInfoCard extends ConsumerWidget {
  final Group group;
  const _GroupInfoCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupMembersAsync = ref.watch(groupMembersProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final groupId = authState.groupId;
    // Find the current user as a GroupMember
    GroupMember? currentMember;
    int memberCount = 0;
    groupMembersAsync.when(
      data: (members) {
        memberCount = members.length;
        if (user != null && groupId != null) {
          currentMember = members.firstWhere(
            (m) => m.userId == user.oderId || m.displayName == user.displayName,
            orElse: () => GroupMember(
              userId: user.oderId,
              displayName: user.displayName,
              colorAvatar: user.colorAvatar,
              avatarUrl: user.avatarUrl,
            ),
          );
        }
      },
      loading: () {},
      error: (_, __) {},
    );

    // Group initials fallback
    String groupInitials = group.name.isNotEmpty
        ? group.name
            .trim()
            .split(' ')
            .map((w) => w[0])
            .take(3)
            .join()
            .toUpperCase()
        : 'G';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // User avatar (always use AvatarCircle)
                if (currentMember != null)
                  AvatarCircle(
                    colorHex: currentMember!.colorAvatar,
                    initials: currentMember!.initials,
                    avatarUrl: currentMember!.avatarUrl,
                    size: 56,
                  )
                else
                  // Group fallback: colored circle with initials
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      groupInitials,
                      style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people_outline,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            memberCount > 0
                                ? '$memberCount member${memberCount != 1 ? 's' : ''}'
                                : 'Loading members...',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Change your display name for this group',
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Name'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    onPressed: () async {
                      final newName = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            title: const Text(
                                'Change Display Name for This Group'),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: 'Enter new display name',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(controller.text),
                                child: const Text('Save'),
                              ),
                            ],
                          );
                        },
                      );
                      if (newName != null && newName.trim().isNotEmpty) {
                        final success = await ref
                            .read(authProvider.notifier)
                            .updateDisplayName(newName.trim());
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to update display name'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Invite Code',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textLight,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.inviteCode,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: AppColors.primary,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    final success =
                        await ShareService.copyInviteCode(group.inviteCode);
                    if (context.mounted) {
                      ShareService.showCopyResult(
                          context, success, group.inviteCode);
                    }
                  },
                  tooltip: 'Copy',
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Invite QR Code'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: QrImageView(
                                data: group.inviteCode,
                                size: 200,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              group.inviteCode,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: 'Show QR',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Share.share(
                    'Join my group "${group.name}" on dontAskUs!\n\nInvite code: ${group.inviteCode}',
                    subject: 'Join my dontAskUs group!',
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Share Invite'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
