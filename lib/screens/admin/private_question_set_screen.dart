import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_exception.dart';
import '../../utils/app_colors.dart';

/// A question entry in a private set being edited.
class _QuestionEntry {
  final TextEditingController textController;
  String questionType;
  final List<TextEditingController> optionControllers;

  _QuestionEntry({
    String? text,
    this.questionType = 'binary_vote',
    List<String>? options,
  })  : textController = TextEditingController(text: text),
        optionControllers = (options ?? ['Yes', 'No'])
            .map((o) => TextEditingController(text: o))
            .toList();

  void dispose() {
    textController.dispose();
    for (final c in optionControllers) {
      c.dispose();
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'text': textController.text.trim(),
      'question_type': questionType,
    };
    if (_needsOptions) {
      map['options'] = optionControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }
    return map;
  }

  bool get _needsOptions => questionType != 'free_text';
}

/// Screen to create or edit a private question set for a group.
///
/// Uses:
///   POST /api/groups/{group_id}/question-sets/private  (create)
///   PUT  /api/groups/{group_id}/question-sets/{set_id} (update)
class PrivateQuestionSetScreen extends ConsumerStatefulWidget {
  /// Pass an existing set id + name + questions to edit. `null` → create mode.
  final int? existingSetId;
  final String? existingName;
  final String? existingDescription;
  final List<Map<String, dynamic>>? existingQuestions;

  const PrivateQuestionSetScreen({
    super.key,
    this.existingSetId,
    this.existingName,
    this.existingDescription,
    this.existingQuestions,
  });

  bool get isEditing => existingSetId != null;

  @override
  ConsumerState<PrivateQuestionSetScreen> createState() =>
      _PrivateQuestionSetScreenState();
}

class _PrivateQuestionSetScreenState
    extends ConsumerState<PrivateQuestionSetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_QuestionEntry> _questions = [];
  bool _isLoading = false;

  static const _questionTypes = <String, String>{
    'binary_vote': 'Yes / No',
    'single_choice': 'Single Choice',
    'member_choice': 'Member Vote',
    'duo_choice': 'Duo Vote',
    'free_text': 'Free Text',
  };

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _nameController.text = widget.existingName ?? '';
      _descriptionController.text = widget.existingDescription ?? '';
      for (final q in widget.existingQuestions ?? []) {
        _questions.add(_QuestionEntry(
          text: q['text'] as String? ?? q['question_text'] as String? ?? '',
          questionType: q['question_type'] as String? ?? 'binary_vote',
          options: (q['options'] as List?)?.cast<String>(),
        ));
      }
    }
    if (_questions.isEmpty) {
      _questions.add(_QuestionEntry());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionEntry());
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) return;
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
    });
  }

  void _addOption(int questionIndex) {
    setState(() {
      _questions[questionIndex].optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int questionIndex, int optionIndex) {
    final q = _questions[questionIndex];
    if (q.optionControllers.length <= 2) return;
    setState(() {
      q.optionControllers[optionIndex].dispose();
      q.optionControllers.removeAt(optionIndex);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate questions
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.textController.text.trim().isEmpty) {
        _showError('Question ${i + 1} text cannot be empty.');
        return;
      }
      if (q._needsOptions) {
        final opts = q.optionControllers
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList();
        if (opts.length < 2) {
          _showError('Question ${i + 1} needs at least 2 options.');
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      if (!authState.hasGroup || authState.groupId == null) {
        _showError('No group selected.');
        return;
      }

      final accessToken = await ref.read(accessTokenProvider.future);
      if (accessToken == null) {
        _showError('Not authenticated.');
        return;
      }

      final api = ref.read(apiClientProvider);
      final body = <String, dynamic>{
        'name': _nameController.text.trim(),
        if (_descriptionController.text.trim().isNotEmpty)
          'description': _descriptionController.text.trim(),
        'questions': _questions.map((q) => q.toJson()).toList(),
      };

      final String endpoint;
      final Future<dynamic> Function() request;

      if (widget.isEditing) {
        endpoint =
            '/api/groups/${authState.groupId}/question-sets/${widget.existingSetId}';
        request = () => api.put(endpoint, body, accessToken: accessToken);
      } else {
        endpoint = '/api/groups/${authState.groupId}/question-sets/private';
        request = () => api.post(endpoint, body, accessToken: accessToken);
      }

      final response = await request();

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEditing
                  ? 'Question set updated'
                  : 'Question set created'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true); // signal success
        }
      } else {
        final exception = ApiException.fromResponse(response);
        _showError(exception.userFriendlyMessage);
      }
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.isEditing ? 'Edit Question Set' : 'New Question Set'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Set Name *',
                hintText: 'e.g. Fun Icebreakers',
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 3) return 'At least 3 characters';
                if (v.trim().length > 200) return 'Maximum 200 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // {member} placeholder info card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Include {member} in any question to feature a random group member! '
                      'E.g. "Do you think {member} could survive a zombie apocalypse?"',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF92400E),
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Questions header
            Row(
              children: [
                Text(
                  'Questions (${_questions.length}/100)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                if (_questions.length < 100)
                  TextButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Question cards
            ..._questions.asMap().entries.map((entry) {
              final idx = entry.key;
              final q = entry.value;
              return _buildQuestionCard(idx, q);
            }),

            const SizedBox(height: 24),

            // Submit
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(widget.isEditing ? Icons.save : Icons.add_circle),
              label: Text(widget.isEditing ? 'Save Changes' : 'Create Set'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, _QuestionEntry q) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Question ${index + 1}',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (_questions.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error, size: 20),
                    onPressed: () => _removeQuestion(index),
                    tooltip: 'Remove question',
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Question text
            TextFormField(
              controller: q.textController,
              decoration: InputDecoration(
                labelText: 'Question text',
                hintText: 'e.g. Who is the funniest?',
                border: const OutlineInputBorder(),
                isDense: true,
                helperText:
                    'Use {member} to insert a random group member\'s name',
                helperMaxLines: 2,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.person_add_alt_1, size: 20),
                  tooltip: 'Insert {member} placeholder',
                  onPressed: () {
                    final ctrl = q.textController;
                    final text = ctrl.text;
                    final selection = ctrl.selection;
                    final newText = text.replaceRange(
                      selection.start,
                      selection.end,
                      '{member}',
                    );
                    ctrl.text = newText;
                    ctrl.selection = TextSelection.collapsed(
                      offset: selection.start + '{member}'.length,
                    );
                  },
                ),
              ),
              maxLines: 2,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Question text is required'
                  : null,
            ),
            const SizedBox(height: 12),

            // Question type
            DropdownButtonFormField<String>(
              initialValue: q.questionType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _questionTypes.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  q.questionType = v;
                  // Reset options for free_text
                  if (v == 'free_text') {
                    for (final c in q.optionControllers) {
                      c.dispose();
                    }
                    q.optionControllers.clear();
                  } else if (q.optionControllers.isEmpty) {
                    q.optionControllers.addAll([
                      TextEditingController(text: 'Yes'),
                      TextEditingController(text: 'No'),
                    ]);
                  }
                });
              },
            ),

            // Options (if not free_text)
            if (q._needsOptions) ...[
              const SizedBox(height: 12),
              Text(
                'Options',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              ...q.optionControllers.asMap().entries.map((optEntry) {
                final optIdx = optEntry.key;
                final optCtrl = optEntry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: optCtrl,
                          decoration: InputDecoration(
                            hintText: 'Option ${optIdx + 1}',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                      if (q.optionControllers.length > 2)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 20, color: AppColors.error),
                          onPressed: () => _removeOption(index, optIdx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => _addOption(index),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add option'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
