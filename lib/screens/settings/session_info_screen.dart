import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../utils/app_colors.dart';

/// Session info screen for debugging
class SessionInfoScreen extends ConsumerStatefulWidget {
  const SessionInfoScreen({super.key});

  @override
  ConsumerState<SessionInfoScreen> createState() => _SessionInfoScreenState();
}

class _SessionInfoScreenState extends ConsumerState<SessionInfoScreen> {
  String? _groupId;
  String? _token;
  String? _userId;
  String? _displayName;
  String? _adminToken;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessionInfo();
  }

  Future<void> _loadSessionInfo() async {
    final groupId = await AuthService.getCurrentGroupId();
    if (groupId != null) {
      final token = await AuthService.getToken(groupId);
      final userId = await AuthService.getUserId(groupId);
      final displayName = await AuthService.getDisplayName(groupId);
      final adminToken = await AuthService.getAdminToken(groupId);

      setState(() {
        _groupId = groupId;
        _token = token;
        _userId = userId;
        _displayName = displayName;
        _adminToken = adminToken;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _maskToken(String? token) {
    if (token == null || token.length < 8) return token ?? 'N/A';
    return '${token.substring(0, 4)}${'•' * (token.length - 8)}${token.substring(token.length - 4)}';
  }

  Future<void> _copyToClipboard(String label, String? value) async {
    if (value == null) return;

    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Info'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Warning Card
                Card(
                  color: AppColors.warning.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This information is for debugging purposes. '
                            'Do not share your session token with others.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.warning,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // User Info Section
                Text(
                  'User Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),

                _InfoCard(
                  items: [
                    _InfoItem(
                      label: 'Display Name',
                      value:
                          _displayName ?? authState.user?.displayName ?? 'N/A',
                      onCopy: () => _copyToClipboard(
                        'Display Name',
                        _displayName ?? authState.user?.displayName,
                      ),
                    ),
                    _InfoItem(
                      label: 'User ID',
                      value: _userId ?? 'N/A',
                      onCopy: () => _copyToClipboard('User ID', _userId),
                    ),
                    _InfoItem(
                      label: 'Current Streak',
                      value: '${authState.user?.answerStreak ?? 0} days',
                    ),
                    _InfoItem(
                      label: 'Longest Streak',
                      value: '${authState.user?.longestAnswerStreak ?? 0} days',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Session Info Section
                Text(
                  'Session Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),

                _InfoCard(
                  items: [
                    _InfoItem(
                      label: 'Current Group ID',
                      value: _groupId ?? 'N/A',
                      onCopy: () => _copyToClipboard('Group ID', _groupId),
                    ),
                    _InfoItem(
                      label: 'Session Token',
                      value: _maskToken(_token),
                      isSecret: true,
                      onCopy: () => _copyToClipboard('Session Token', _token),
                    ),
                  ],
                ),

                // Admin Token (if available)
                if (_adminToken != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Admin Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _InfoCard(
                    items: [
                      _InfoItem(
                        label: 'Admin Token',
                        value: _maskToken(_adminToken),
                        isSecret: true,
                        onCopy: () =>
                            _copyToClipboard('Admin Token', _adminToken),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: AppColors.error.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.security,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Keep your admin token secret! Anyone with this token '
                              'can create questions and manage your group.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.error,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // API Info Section
                Text(
                  'API Configuration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),

                _InfoCard(
                  items: [
                    _InfoItem(
                      label: 'API Base URL',
                      value: ApiConfig.currentBaseUrl,
                      onCopy: () =>
                          _copyToClipboard('API URL', ApiConfig.currentBaseUrl),
                    ),
                    _InfoItem(
                      label: 'Environment',
                      value: ApiConfig.useProduction
                          ? 'Production'
                          : 'Development',
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;

  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              ListTile(
                title: Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textLight,
                      ),
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.value,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: item.isSecret ? 'monospace' : null,
                            ),
                      ),
                    ),
                    if (item.onCopy != null)
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: item.onCopy,
                        tooltip: 'Copy',
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  final bool isSecret;
  final VoidCallback? onCopy;

  const _InfoItem({
    required this.label,
    required this.value,
    this.isSecret = false,
    this.onCopy,
  });
}
