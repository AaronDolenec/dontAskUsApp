import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';

class CreateQuestionScreen extends ConsumerStatefulWidget {
  const CreateQuestionScreen({super.key});

  @override
  ConsumerState<CreateQuestionScreen> createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends ConsumerState<CreateQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionsControllers = <TextEditingController>[];
  
  QuestionType _selectedType = QuestionType.binaryVote;
  bool _allowMultiple = false;
  bool _isLoading = false;
  String? _errorMessage;
  int? _selectedQuestionSetId;

  @override
  void initState() {
    super.initState();
    // Initialize with 2 options for single_choice
    _optionsControllers.add(TextEditingController());
    _optionsControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionsControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionsControllers.length > 2) {
      setState(() {
        _optionsControllers[index].dispose();
        _optionsControllers.removeAt(index);
      });
    }
  }

  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authProvider);
      if (authState == null) {
        throw Exception('Not authenticated');
      }

      final apiClient = ref.read(apiClientProvider);
      
      // Build options based on question type
      List<String>? options;
      if (_selectedType == QuestionType.binaryVote) {
        options = ['Yes', 'No'];
      } else if (_selectedType == QuestionType.singleChoice) {
        options = _optionsControllers
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList();
        if (options.length < 2) {
          throw Exception('At least 2 options are required');
        }
      }

      final body = {
        'question_text': _questionController.text.trim(),
        'question_type': _selectedType.value,
        if (options != null) 'options': options,
        if (_selectedType == QuestionType.singleChoice) 'allow_multiple': _allowMultiple,
        if (_selectedQuestionSetId != null) 'question_set_id': _selectedQuestionSetId,
      };

      await apiClient.post(
        '/groups/${authState.groupId}/questions/today',
        body: body,
        adminToken: authState.adminToken,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Question'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Question Type Selector
            Text(
              'Question Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<QuestionType>(
              value: _selectedType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: QuestionType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 20),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Question Text
            Text(
              'Question',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(
                hintText: 'Enter your question...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a question';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Options (for single_choice type)
            if (_selectedType == QuestionType.singleChoice) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Options',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Option'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(_optionsControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _optionsControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Option ${index + 1}',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_optionsControllers.length > 2)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: Colors.red,
                          onPressed: () => _removeOption(index),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Allow Multiple Selections'),
                subtitle: const Text('Users can select more than one option'),
                value: _allowMultiple,
                onChanged: (value) {
                  setState(() {
                    _allowMultiple = value;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],

            // Binary Vote Info
            if (_selectedType == QuestionType.binaryVote) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Binary vote will have "Yes" and "No" options.',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Member Choice Info
            if (_selectedType == QuestionType.memberChoice) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.secondary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Users will vote for a group member.',
                        style: TextStyle(color: AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Duo Choice Info
            if (_selectedType == QuestionType.duoChoice) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.accent),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Users will vote for a pair of group members.',
                        style: TextStyle(color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Free Text Info
            if (_selectedType == QuestionType.freeText) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.purple),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Users will enter a free text answer.',
                        style: TextStyle(color: Colors.purple),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Error Message
            if (_errorMessage != null) ...[
              ErrorDisplay(
                message: _errorMessage!,
                onRetry: _submitQuestion,
              ),
              const SizedBox(height: 16),
            ],

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitQuestion,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Question'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
