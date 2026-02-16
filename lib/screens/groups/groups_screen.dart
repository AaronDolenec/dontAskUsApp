import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../utils/app_colors.dart';
import '../main/main_screen.dart';
import '../onboarding/join_group_screen.dart';
import '../onboarding/create_group_screen.dart';
import '../onboarding/auth_screen.dart';
import '../settings/session_info_screen.dart';

/// Screen showing all groups the user belongs to.
/// This is the first screen after login.
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh groups list when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(multiGroupProvider.notifier).refresh();
    });
  }

  Future<void> _selectGroup(GroupInfo group) async {
    // Switch to this group via auth provider
    await ref.read(authProvider.notifier).switchGroup(group.groupId);
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  void _joinGroup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
    );
  }

  void _createGroup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
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
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final multiGroupState = ref.watch(multiGroupProvider);
    final authState = ref.watch(authProvider);
    final groups = multiGroupState.groups;

    return Scaffold(
      appBar: AppBar(
        title: const Text('dontAskUs'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SessionInfoScreen()),
              );
            },
            tooltip: 'Session Info',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: multiGroupState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty
              ? _buildNoGroupsView(context)
              : _buildGroupsList(context, groups, authState),
    );
  }

  Widget _buildNoGroupsView(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                child: Text(
                  group.groupName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              // Streak indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: group.answerStreak > 0
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
                        color: group.answerStreak > 0
                            ? AppColors.streakActive
                            : AppColors.streakInactive,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${group.answerStreak}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: group.answerStreak > 0
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
