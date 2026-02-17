import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/multi_group_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/color_picker.dart';
import '../../widgets/error_display.dart';
import '../groups/groups_screen.dart';
import 'create_group_screen.dart';

/// Screen for joining a group with invite code
class JoinGroupScreen extends ConsumerStatefulWidget {
  /// If true, this is adding a new group (not initial onboarding)
  final bool isAddingGroup;

  const JoinGroupScreen({super.key, this.isAddingGroup = false});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _inviteCodeController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedColor;
  bool _isLoadingPreview = false;
  String? _previewGroupName;
  int? _previewMemberCount;
  String? _previewError;

  @override
  void initState() {
    super.initState();
    _selectedColor = AppColors.toHex(AppColors.avatarColors.first);
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchGroupPreview(String code) async {
    if (code.length < 6) {
      setState(() {
        _previewGroupName = null;
        _previewMemberCount = null;
        _previewError = null;
      });
      return;
    }

    setState(() {
      _isLoadingPreview = true;
      _previewError = null;
    });

    final group =
        await ref.read(groupPreviewProvider(code.toUpperCase()).future);

    setState(() {
      _isLoadingPreview = false;
      if (group != null) {
        _previewGroupName = group.name;
        _previewMemberCount = group.memberCount;
        _previewError = null;
      } else {
        _previewGroupName = null;
        _previewMemberCount = null;
        _previewError = 'Group not found';
      }
    });
  }

  Future<void> _handleJoin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_previewGroupName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid invite code')),
      );
      return;
    }

    try {
      final success = await ref.read(authProvider.notifier).joinGroup(
            inviteCode: _inviteCodeController.text.trim(),
            displayName: _displayNameController.text.trim(),
            colorAvatar: _selectedColor,
          );

      if (mounted) {
        if (success) {
          // Refresh multi-group list
          ref.read(multiGroupProvider.notifier).refresh();

          if (widget.isAddingGroup) {
            // Just pop back to settings when adding another group
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Joined "$_previewGroupName"!')),
            );
          } else {
            // Navigate to groups screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const GroupsScreen()),
            );
          }
        } else {
          // Show error if joining failed
          final authState = ref.read(authProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  authState.error ?? 'Failed to join group. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null) {
        final code = data!.text!.trim().toUpperCase();
        if (code.length >= 6 && code.length <= 8) {
          _inviteCodeController.text = code;
          _fetchGroupPreview(code);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Clipboard doesn\'t contain a valid invite code')),
            );
          }
        }
      }
    } catch (e) {
      // Clipboard access may fail on web without HTTPS
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Could not access clipboard. Please type the code manually.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: widget.isAddingGroup
          ? AppBar(
              title: const Text('Join Another Group'),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.isAddingGroup) const SizedBox(height: 40),

                // Header
                Text(
                  widget.isAddingGroup ? 'Join Another Group' : 'Join a Group',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your group\'s invite code to get started',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Invite Code Input
                Text(
                  'Invite Code',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _inviteCodeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'ABC123',
                          prefixIcon: Icon(Icons.link),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9]')),
                          LengthLimitingTextInputFormatter(8),
                          UpperCaseTextFormatter(),
                        ],
                        onChanged: (value) {
                          if (value.length >= 6) {
                            _fetchGroupPreview(value);
                          } else {
                            setState(() {
                              _previewGroupName = null;
                              _previewError = null;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an invite code';
                          }
                          if (value.length < 6) {
                            return 'Invite code must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _pasteFromClipboard,
                      icon: const Icon(Icons.paste),
                      tooltip: 'Paste from clipboard',
                    ),
                  ],
                ),

                // Group Preview
                const SizedBox(height: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _isLoadingPreview ||
                          _previewGroupName != null ||
                          _previewError != null
                      ? 60
                      : 0,
                  child: _isLoadingPreview
                      ? const Center(child: CircularProgressIndicator())
                      : _previewGroupName != null
                          ? Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.success
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: AppColors.success),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _previewGroupName!,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '$_previewMemberCount member${_previewMemberCount != 1 ? 's' : ''}',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _previewError != null
                              ? Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.error
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: AppColors.error),
                                      const SizedBox(width: 12),
                                      Text(
                                        _previewError!,
                                        style: const TextStyle(
                                            color: AppColors.error),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox(),
                ),

                const SizedBox(height: 32),

                // Display Name Input
                Text(
                  'Your Display Name',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    hintText: 'How should others see you?',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a display name';
                    }
                    if (value.trim().length > 50) {
                      return 'Display name must be 50 characters or less';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Color Picker
                Text(
                  'Choose Your Color',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will be your avatar color',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ColorPicker(
                    selectedColor: _selectedColor,
                    onColorSelected: (color) {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 40),

                // Error message
                if (authState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ErrorDisplay(
                      message: authState.error!,
                      compact: true,
                    ),
                  ),

                // Join Button
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleJoin,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Join Group'),
                ),

                // Only show "Create Group" option during initial onboarding
                if (!widget.isAddingGroup) ...[
                  const SizedBox(height: 24),

                  // Or divider
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: TextStyle(color: AppColors.textLight),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Create Group Button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const CreateGroupScreen()),
                      );
                    },
                    child: const Text('Create a New Group'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Text formatter to convert input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
