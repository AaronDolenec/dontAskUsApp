import 'package:flutter/material.dart';
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
  String? _email;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessionInfo();
  }

  Future<void> _loadSessionInfo() async {
    final groupId = await AuthService.getCurrentGroupId();
    final token = await AuthService.getAccessToken();
    final email = await AuthService.getEmail();

    if (groupId != null) {
      final userId = await AuthService.getUserId(groupId);
      final displayName = await AuthService.getDisplayName(groupId);
      final adminToken = await AuthService.getAdminToken(groupId);

      setState(() {
        _groupId = groupId;
        _token = token;
        _userId = userId;
        _displayName = displayName;
        _adminToken = adminToken;
        _email = email;
        _isLoading = false;
      });
    } else {
      setState(() {
        _token = token;
        _email = email;
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

    final success = await ShareService.copyText(value);
    if (mounted) {
      ShareService.showCopyResult(context, success, value);
    }
  }

  Future<void> _validateToken() async {
    final token = _token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No token available to validate')),
        );
      }
      return;
    }

    try {
      final api = ApiClient();
      final resp = await api.get('/api/auth/me', accessToken: token);
      final body = resp.body;
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Validate token: ${resp.statusCode}'),
            content: SingleChildScrollView(
              child: Text(body.isNotEmpty ? body : '(empty response)'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
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
                  color: AppColors.warning.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This information is for debugging purposes. '
                            'Do not share your access token with others.',
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

                // Auth Error Card
                if (authState.error != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: AppColors.error.withValues(alpha: 0.06),
                    child: ListTile(
                      leading: const Icon(Icons.error_outline, color: AppColors.error),
                      title: const Text('Last auth error'),
                      subtitle: Text(authState.error ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () async {
                          final notifier = ref.read(authProvider.notifier);
                          await notifier.reloadSession();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Retrying session restore')),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],

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
                      label: 'Email',
                      value: _email ?? authState.user?.email ?? 'N/A',
                      onCopy: () => _copyToClipboard(
                        'Email',
                        _email ?? authState.user?.email,
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
                      label: 'Access Token',
                      value: _maskToken(_token),
                      isSecret: true,
                      onCopy: () => _copyToClipboard('Access Token', _token),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Validate Token Button
                TextButton.icon(
                  onPressed: _validateToken,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Validate current token'),
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
                    color: AppColors.error.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
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
