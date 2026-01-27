import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../utils/app_colors.dart';
import '../../widgets/widgets.dart';
import '../admin/create_question_screen.dart';
import '../admin/question_sets_screen.dart';
import '../onboarding/join_group_screen.dart';
import 'help_screen.dart';
import 'session_info_screen.dart';
import 'recover_session_screen.dart';

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final groupInfoAsync = ref.watch(groupInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Info Section
            groupInfoAsync.when(
              data: (group) => group != null
                  ? _GroupInfoCard(group: group)
                  : const SizedBox(),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, __) => const SizedBox(),
            ),

            const SizedBox(height: 24),

            // User Section
            Text(
              'Account',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  if (authState.user != null)
                    ListTile(
                      leading: AvatarCircle(
                        colorHex: authState.user!.colorAvatar,
                        initials: authState.user!.displayName.substring(0, 2),
                      ),
                      title: Text(authState.user!.displayName),
                      subtitle: Text(
                          'Streak: 🔥 ${authState.user!.answerStreak} days (Best: ${authState.user!.longestAnswerStreak})'),
                    ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.swap_horiz),
                    title: const Text('Switch Groups'),
                    subtitle: const Text('Manage your groups'),
                    onTap: () => GroupSelectorSheet.show(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.group_add),
                    title: const Text('Join Another Group'),
                    subtitle: const Text('Enter a new invite code'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const JoinGroupScreen(isAddingGroup: true),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app),
                    title: const Text('Leave Group'),
                    subtitle: const Text('You can rejoin with the invite code'),
                    onTap: () => _showLeaveGroupDialog(context, ref),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Admin Section (only shown to admins)
            if (authState.isAdmin) ...[
              Text(
                'Admin',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: const Text('Create Question'),
                      subtitle: const Text('Add today\'s question'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateQuestionScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.library_books_outlined),
                      title: const Text('Question Sets'),
                      subtitle: const Text('Manage question templates'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const QuestionSetsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.api),
                      title: const Text('API Diagnostics'),
                      subtitle: const Text('Check API reachability and CORS'),
                      onTap: () => _showApiDiagnostics(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.bug_report),
                      title: const Text('Run Test Create Question'),
                      subtitle:
                          const Text('Post a sample question (admins only)'),
                      onTap: () => _runTestCreateQuestion(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // About Section
            Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About dontAskUs'),
                    subtitle: const Text('Version 1.0.0'),
                    onTap: () => _showAboutDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help & Support'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HelpScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Session Info'),
                    subtitle: const Text('Debug information'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SessionInfoScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account Section
            Text(
              'Account',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Clear All Data'),
                subtitle: const Text('Logout and clear all stored data'),
                onTap: () => _showClearDataDialog(context, ref),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.vpn_key),
                title: const Text('Recover Account'),
                subtitle:
                    const Text('Enter a session token provided by an admin'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const RecoverSessionScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

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
                  MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
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

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will log you out and clear all stored data from this device. '
          'You will need to join a group again to continue using the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).logout();

              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/onboarding',
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

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

  Future<void> _showApiDiagnostics(BuildContext context) async {
    final api = ApiClient();
    String title = 'API Diagnostics';
    String content;

    try {
      final response = await api.get('/api/');
      content =
          'Status: ${response.statusCode}\nBody: ${response.body}\nHeaders: ${response.headers}';
    } catch (e) {
      content =
          'Network error: ${e.toString()}\nAPI URL: ${ApiConfig.currentBaseUrl}';
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _runTestCreateQuestion(
      BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authProvider);
    if (!authState.isAdmin || authState.groupId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only admins can run this test')),
        );
      }
      return;
    }

    final adminToken = await ref.read(adminTokenProvider.future);
    final api = ref.read(apiClientProvider);
    final groupId = authState.groupId!;

    final body = {
      'question_text': 'Test question from client',
      'question_type': 'binary_vote',
    };

    try {
      final response = await api.post('/api/groups/$groupId/questions', body,
          adminToken: adminToken);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Test question created successfully')));
        }
      } else {
        final exception = ApiException.fromResponse(response);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Test failed: ${exception.userFriendlyMessage}')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Network error: ${e.toString()}')));
      }
    }
  }
}

class _GroupInfoCard extends StatelessWidget {
  final Group group;

  const _GroupInfoCard({required this.group});

  Future<void> _copyInviteCode(BuildContext context) async {
    final success = await ShareService.copyInviteCode(group.inviteCode);
    if (context.mounted) {
      ShareService.showCopyResult(context, success, group.inviteCode);
    }
  }

  void _shareInviteCode() {
    Share.share(
      'Join my group "${group.name}" on dontAskUs!\n\nInvite code: ${group.inviteCode}',
      subject: 'Join my dontAskUs group!',
    );
  }

  void _showQRCode(BuildContext context) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.group, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
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
                  onPressed: () => _copyInviteCode(context),
                  tooltip: 'Copy',
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: () => _showQRCode(context),
                  tooltip: 'Show QR',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _shareInviteCode,
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
