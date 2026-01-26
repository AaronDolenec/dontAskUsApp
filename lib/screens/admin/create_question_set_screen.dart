import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

import '../../services/services.dart';
import '../../providers/providers.dart';

class CreateQuestionSetScreen extends ConsumerStatefulWidget {
  const CreateQuestionSetScreen({super.key});

  @override
  ConsumerState<CreateQuestionSetScreen> createState() =>
      _CreateQuestionSetScreenState();
}

class _CreateQuestionSetScreenState
    extends ConsumerState<CreateQuestionSetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = true;
  bool _addToGroup = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final adminToken = await ref.read(adminTokenProvider.future);
      final api = ref.read(apiClientProvider);

      final body = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'is_public': _isPublic,
      };

      final response =
          await api.post('/api/question-sets', body, adminToken: adminToken);

      if (response.statusCode == 200) {
        final parsed = response.body.isNotEmpty
            ? (dataFromJson(response.body) as Map<String, dynamic>)
            : null;
        // Optionally add to group
        if (_addToGroup) {
          final authState = ref.read(authProvider);
          if (authState.groupId != null) {
            final setId = parsed?['set_id'] as String?;
            if (setId != null) {
              await api.post(
                  '/api/groups/${authState.groupId}/question-sets',
                  {
                    'question_set_ids': [setId],
                    'replace': false,
                  },
                  adminToken: adminToken);
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question set created')),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        final exception = ApiException.fromResponse(response);
        throw exception;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to create set: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Question Set')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Set name'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter a name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Public set'),
                  subtitle: const Text('Visible to all groups'),
                  value: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Add to my group'),
                  subtitle: const Text(
                      'Assign this set to your group rotation after creating'),
                  value: _addToGroup,
                  onChanged: (v) => setState(() => _addToGroup = v),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Set'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Simple helper to parse json without importing jsondecode everywhere
dynamic dataFromJson(String s) => s.isEmpty ? null : jsonDecode(s);
