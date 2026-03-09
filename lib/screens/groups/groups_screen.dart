import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/multi_group_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_feedback.dart';
import '../../utils/app_motion.dart';
import '../../utils/app_routes.dart';
import '../profile/profile_screen.dart';
import '../../widgets/avatar_circle.dart';

/// Screen showing all groups the user belongs to.
/// This is the first screen after login.
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({
    super.key,
    this.initialSnackMessage,
  });

  final String? initialSnackMessage;

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh groups list when screen loads and start periodic refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(multiGroupProvider.notifier).refresh();
      ref.read(multiGroupProvider.notifier).startPeriodicRefresh();

      final message = widget.initialSnackMessage;
      if (message != null && message.isNotEmpty) {
        AppFeedback.showInfo(context, message);
      }
    });
  }

  @override
  void dispose() {
    // Stop periodic refresh when leaving the screen
    ref.read(multiGroupProvider.notifier).stopPeriodicRefresh();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(multiGroupProvider.notifier).refresh();
  }

  Future<void> _selectGroup(GroupInfo group) async {
    // Switch to this group via auth provider
    HapticFeedback.selectionClick();
    await ref.read(authProvider.notifier).switchGroup(group.groupId);
    if (mounted) {
      Navigator.of(context).pushNamed(AppRoutePaths.groupHome(group.groupId));
    }
  }

  void _joinGroup() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pushNamed(AppRoutePaths.join);
  }

  void _createGroup() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pushNamed(AppRoutePaths.create);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('You will need to log in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutePaths.auth, (route) => false);
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return name.substring(0, name.length >= 2 ? 2 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final multiGroupState = ref.watch(multiGroupProvider);
    final authState = ref.watch(authProvider);
    final groups = multiGroupState.groups;

    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('dontAskUs'),
        automaticallyImplyLeading: false,
        leading: user != null
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()),
                      );
                    },
                    child: AvatarCircle(
                      colorHex: user.colorAvatar,
                      initials: _getInitials(user.displayName),
                      avatarUrl: user.avatarUrl,
                      size: 36,
                    ),
                  ),
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: AnimatedSwitcher(
          duration: AppMotion.short,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: multiGroupState.isLoading && groups.isEmpty
              ? const Center(
                  key: ValueKey('groups-loading'),
                  child: CircularProgressIndicator(),
                )
              : groups.isEmpty
                  ? KeyedSubtree(
                      key: const ValueKey('groups-empty'),
                      child: _buildNoGroupsView(context),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('groups-list'),
                      child: _buildGroupsList(context, groups, authState),
                    ),
        ),
      ),
    );
  }

  Widget _buildNoGroupsView(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to dontAskUs!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Join a group to start answering daily questions with your friends.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Primary: Join a Group
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _joinGroup,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Join a Group'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Secondary: Create a Group
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _createGroup,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Create a Group'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsList(
      BuildContext context, List<GroupInfo> groups, AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            'Your Groups',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        // Groups list
        Expanded(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _GroupCard(
                group: group,
                onTap: () => _selectGroup(group),
              );
            },
          ),
        ),

        // Bottom action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _joinGroup,
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Join Group'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _createGroup,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Group'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupInfo group;
  final VoidCallback onTap;

  const _GroupCard({
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    group.groupName.isNotEmpty
                        ? group.groupName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.groupName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (group.memberCount > 0)
                      Text(
                        '${group.memberCount} member${group.memberCount != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                  ],
                ),
              ),
              // Group streak indicator (highest streak in the group)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: group.groupStreak > 0
                      ? AppColors.streakActive.withValues(alpha: 0.12)
                      : AppColors.streakInactiveBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🔥',
                      style: TextStyle(
                        fontSize: 14,
                        color: group.groupStreak > 0
                            ? AppColors.streakActive
                            : AppColors.streakInactive,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${group.groupStreak}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: group.groupStreak > 0
                            ? AppColors.streakActive
                            : AppColors.streakInactive,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
