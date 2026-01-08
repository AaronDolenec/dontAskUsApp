import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/providers.dart';
import '../../services/share_service.dart';
import '../../utils/app_colors.dart';
import '../../models/models.dart';
import '../main/main_screen.dart';

/// Screen for creating a new group
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Group? _createdGroup;
  bool _showSuccess = false;
  bool _isJoining = false;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = AppColors.toHex(AppColors.avatarColors.first);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final group = await ref.read(authProvider.notifier).createGroup(
          _nameController.text.trim(),
        );

    if (group != null && mounted) {
      setState(() {
        _createdGroup = group;
        _showSuccess = true;
      });
    }
  }

  Future<void> _copyInviteCode() async {
    if (_createdGroup == null) return;

    final success =
        await ShareService.copyInviteCode(_createdGroup!.inviteCode);
    if (mounted) {
      ShareService.showCopyResult(context, success, _createdGroup!.inviteCode);
    }
  }

  void _shareInviteCode() {
    if (_createdGroup == null) return;

    Share.share(
      'Join my group "${_createdGroup!.name}" on dontAskUs!\n\nInvite code: ${_createdGroup!.inviteCode}',
      subject: 'Join my dontAskUs group!',
    );
  }

  Future<void> _joinMyGroup() async {
    if (_createdGroup == null || _displayNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your display name')),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      final success = await ref.read(authProvider.notifier).joinGroup(
            inviteCode: _createdGroup!.inviteCode,
            displayName: _displayNameController.text.trim(),
            colorAvatar: _selectedColor,
          );

      if (mounted) {
        setState(() => _isJoining = false);

        if (success) {
          // Navigate to main screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
        } else {
          // Show error if joining failed
          final authState = ref.read(authProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  authState.error ?? 'Failed to join group. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (_showSuccess && _createdGroup != null) {
      return _buildSuccessView(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group_add,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),

                // Header
                Text(
                  'Create Your Group',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a new group and invite your friends to join the fun!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Group Name Input
                Text(
                  'Group Name',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., The Awesome Squad',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a group name';
                    }
                    if (value.trim().length > 100) {
                      return 'Group name must be 100 characters or less';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You\'ll become the admin of this group and can create daily questions for everyone to answer.',
                          style: TextStyle(
                            color: AppColors.info,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Error message
                if (authState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authState.error!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Create Button
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleCreate,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Group'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  size: 50,
                  color: AppColors.success,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Group Created! 🎉',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _createdGroup!.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Join your group section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Join Your Group',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your display name to join as the first member',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          hintText: 'Your display name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // Color selection
                      Text(
                        'Choose your color',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppColors.avatarColors.map((color) {
                          final hex = AppColors.toHex(color);
                          final isSelected = _selectedColor == hex;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = hex),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Error message
                      if (authState.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            authState.error!,
                            style: const TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      ElevatedButton(
                        onPressed: _isJoining ? null : _joinMyGroup,
                        child: _isJoining
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Join Group'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Invite Code Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Share with friends',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                      const SizedBox(height: 12),

                      // Invite code display with select-all
                      GestureDetector(
                        onTap: _copyInviteCode,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            _createdGroup!.inviteCode,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                  color: AppColors.primary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to copy',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textLight,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _copyInviteCode,
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copy'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _shareInviteCode,
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Share'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // QR Code (collapsible)
              ExpansionTile(
                title: const Text('Show QR Code'),
                leading: const Icon(Icons.qr_code),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: _createdGroup!.inviteCode,
                        size: 180,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
