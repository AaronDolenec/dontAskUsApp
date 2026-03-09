import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/question_provider.dart';
import '../../services/auth_service.dart';
import '../../services/share_service.dart';
import '../../services/api_client.dart';
import '../../services/api_config.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_feedback.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/color_picker.dart';

/// Profile / Account screen accessible from the user avatar in the top-left.
/// Shows avatar, lets the user change their avatar color and password,
/// and contains debug / session information.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Password change
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _didAttemptPasswordSubmit = false;
  bool _isChangingPassword = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;

  // Avatar upload
  bool _isUploadingAvatar = false;

  // Debug info
  String? _groupId;
  String? _userId;
  String? _displayName;
  String? _email;
  bool _debugLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadDebugInfo() async {
    final groupId = await AuthService.getCurrentGroupId();
    final email = await AuthService.getEmail();

    if (groupId != null) {
      final userId = await AuthService.getUserId(groupId);
      final displayName = await AuthService.getDisplayName(groupId);
      if (mounted) {
        setState(() {
          _groupId = groupId;
          _userId = userId;
          _displayName = displayName;
          _email = email;
          _debugLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _email = email;
          _debugLoading = false;
        });
      }
    }
  }

  Future<void> _copyToClipboard(String label, String? value) async {
    if (value == null) return;
    final success = await ShareService.copyText(value);
    if (mounted) {
      ShareService.showCopyResult(context, success, value);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      setState(() => _didAttemptPasswordSubmit = true);
      AppFeedback.showInfo(context, 'Please fix the password fields.');
      return;
    }

    setState(() => _isChangingPassword = true);

    final success = await ref.read(authProvider.notifier).changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );

    setState(() => _isChangingPassword = false);

    if (mounted) {
      if (success) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        AppFeedback.showSuccess(context, 'Password changed successfully');
      } else {
        AppFeedback.showError(
          context,
          'Failed to change password. Check your current password.',
        );
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (picked == null) return;

    // Validate file size (max 2MB)
    final bytes = await picked.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      if (mounted) {
        AppFeedback.showError(
            context, 'Image is too large. Maximum size is 2MB.');
      }
      return;
    }

    setState(() => _isUploadingAvatar = true);

    final error = await ref.read(authProvider.notifier).uploadAvatar(
          fileBytes: bytes,
          fileName: picked.name,
        );

    if (mounted) {
      setState(() => _isUploadingAvatar = false);
      if (error == null) {
        AppFeedback.showSuccess(context, 'Avatar uploaded successfully!');
      } else {
        AppFeedback.showError(context, 'Upload failed: $error');
      }
    }
  }

  Future<void> _deleteAvatar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Avatar?'),
        content: const Text(
            'Your profile photo will be removed and replaced with your color avatar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUploadingAvatar = true);

    final error = await ref.read(authProvider.notifier).deleteAvatar();

    if (mounted) {
      setState(() => _isUploadingAvatar = false);
      if (error == null) {
        AppFeedback.showSuccess(context, 'Avatar removed');
      } else {
        AppFeedback.showError(context, 'Failed to remove avatar: $error');
      }
    }
  }

  Future<void> _showApiDiagnostics() async {
    final api = ApiClient();
    final buffer = StringBuffer();

    try {
      final health = await api.get('/health');
      buffer.writeln('GET /health → ${health.statusCode}');
      if (health.body.isNotEmpty) {
        final body = health.body.length > 300
            ? '${health.body.substring(0, 300)}...'
            : health.body;
        buffer.writeln('Body: $body');
      }

      final token = await AuthService.getAccessToken();
      if (token == null || token.isEmpty) {
        buffer.writeln();
        buffer.writeln('Auth check skipped: no access token found.');
      } else {
        final me = await api.get('/api/auth/me', accessToken: token);
        buffer.writeln();
        buffer.writeln('GET /api/auth/me → ${me.statusCode}');
        final meBody =
            me.body.length > 300 ? '${me.body.substring(0, 300)}...' : me.body;
        if (meBody.isNotEmpty) {
          buffer.writeln('Body: $meBody');
        }
      }

      buffer.writeln();
      buffer.writeln('API Base URL: ${ApiConfig.currentBaseUrl}');
    } catch (e) {
      buffer
        ..writeln('Diagnostics failed: ${e.toString()}')
        ..writeln('API URL: ${ApiConfig.currentBaseUrl}');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('API Diagnostics'),
        content: SingleChildScrollView(child: Text(buffer.toString())),
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
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Avatar & Identity ───
          _buildAvatarSection(user),
          const SizedBox(height: 32),

          // ─── Change Password ───
          _buildSectionHeader('Change Password'),
          const SizedBox(height: 8),
          _buildChangePasswordCard(),
          const SizedBox(height: 32),

          // ─── Debug & Session Info ───
          _buildSectionHeader('Debug & Session Info'),
          const SizedBox(height: 8),
          _buildDebugSection(authState),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─────────────────────── Avatar Section ───────────────────────

  Widget _buildAvatarSection(User? user) {
    if (user == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Not logged in')),
        ),
      );
    }

    final initials = _getInitials(user.displayName);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Large avatar with upload overlay
            Stack(
              children: [
                AvatarCircle(
                  colorHex: user.colorAvatar,
                  initials: initials,
                  avatarUrl: user.avatarUrl,
                  size: 96,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Upload profile photo',
                      constraints:
                          const BoxConstraints(minWidth: 44, minHeight: 44),
                      onPressed:
                          _isUploadingAvatar ? null : _pickAndUploadAvatar,
                      icon: _isUploadingAvatar
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Upload / Delete buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('Upload Photo'),
                ),
                if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _isUploadingAvatar ? null : _deleteAvatar,
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                    label: const Text('Remove',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            Text(
              user.displayName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (user.email != null) ...[
              const SizedBox(height: 4),
              Text(
                user.email!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final currentStreak = ref.watch(userStreakProvider);
              final longestStreak = ref.watch(longestStreakProvider);
              return Text(
                '🔥 $currentStreak day streak (Best: ${longestStreak ?? 0})',
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Avatar color picker
            Text(
              'Avatar Color',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Used when no photo is uploaded',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textLight,
                  ),
            ),
            const SizedBox(height: 12),
            ColorPicker(
              selectedColor: user.colorAvatar,
              onColorSelected: (hexColor) {
                ref.read(authProvider.notifier).updateAvatarColor(hexColor);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── Password Section ───────────────────────

  Widget _buildChangePasswordCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _passwordFormKey,
          autovalidateMode: _didAttemptPasswordSubmit
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: !_showCurrentPassword,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_showCurrentPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(
                        () => _showCurrentPassword = !_showCurrentPassword),
                  ),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_showNewPassword,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_showNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _showNewPassword = !_showNewPassword),
                  ),
                  helperText: 'Min 8 chars, uppercase, lowercase, and a digit',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  if (!value.contains(RegExp(r'[A-Z]'))) {
                    return 'Must contain an uppercase letter';
                  }
                  if (!value.contains(RegExp(r'[a-z]'))) {
                    return 'Must contain a lowercase letter';
                  }
                  if (!value.contains(RegExp(r'[0-9]'))) {
                    return 'Must contain a digit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_showNewPassword,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _changePassword(),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isChangingPassword ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isChangingPassword
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Change Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────── Debug Section ───────────────────────

  Widget _buildDebugSection(AuthState authState) {
    if (_debugLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Column(
      children: [
        // Auth error
        if (authState.error != null) ...[
          const SizedBox(height: 12),
          Card(
            color: AppColors.error.withValues(alpha: 0.06),
            child: ListTile(
              leading: const Icon(Icons.error_outline, color: AppColors.error),
              title: const Text('Last auth error'),
              subtitle: Text(authState.error ?? ''),
            ),
          ),
        ],

        const SizedBox(height: 12),

        // User info
        _DebugInfoCard(
          title: 'User Information',
          items: [
            _DebugItem(
              label: 'Display Name',
              value: _displayName ?? authState.user?.displayName ?? 'N/A',
              onCopy: () => _copyToClipboard(
                  'Display Name', _displayName ?? authState.user?.displayName),
            ),
            _DebugItem(
              label: 'Email',
              value: _email ?? authState.user?.email ?? 'N/A',
              onCopy: () =>
                  _copyToClipboard('Email', _email ?? authState.user?.email),
            ),
            _DebugItem(
              label: 'User ID',
              value: _userId ?? 'N/A',
              onCopy: () => _copyToClipboard('User ID', _userId),
            ),
            _DebugItem(
              label: 'Current Streak',
              value: '${ref.watch(userStreakProvider)} days',
            ),
            _DebugItem(
              label: 'Longest Streak',
              value: '${ref.watch(longestStreakProvider) ?? 0} days',
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Session info
        _DebugInfoCard(
          title: 'Session Information',
          items: [
            _DebugItem(
              label: 'Current Group ID',
              value: _groupId ?? 'N/A',
              onCopy: () => _copyToClipboard('Group ID', _groupId),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // API config
        _DebugInfoCard(
          title: 'API Configuration',
          items: [
            _DebugItem(
              label: 'API Base URL',
              value: ApiConfig.currentBaseUrl,
              onCopy: () =>
                  _copyToClipboard('API URL', ApiConfig.currentBaseUrl),
            ),
            _DebugItem(
              label: 'Environment',
              value: ApiConfig.useProduction ? 'Production' : 'Development',
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Quick actions
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.api),
                title: const Text('API Diagnostics'),
                subtitle:
                    const Text('Check health endpoint and authenticated API'),
                onTap: _showApiDiagnostics,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────── Helpers ───────────────────────

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return name.substring(0, name.length >= 2 ? 2 : 1);
  }
}

// ─────────────────────── Debug Info Widgets ───────────────────────

class _DebugInfoCard extends StatelessWidget {
  final String title;
  final List<_DebugItem> items;

  const _DebugInfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Card(
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
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textLight),
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.value,
                            style: Theme.of(context).textTheme.bodyMedium,
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
        ),
      ],
    );
  }
}

class _DebugItem {
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _DebugItem({
    required this.label,
    required this.value,
    this.onCopy,
  });
}
