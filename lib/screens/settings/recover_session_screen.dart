import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../utils/app_colors.dart';

class RecoverSessionScreen extends ConsumerStatefulWidget {
  const RecoverSessionScreen({super.key});

  @override
  ConsumerState<RecoverSessionScreen> createState() =>
      _RecoverSessionScreenState();
}

class _RecoverSessionScreenState extends ConsumerState<RecoverSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tokenController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isProcessing = true);

    final token = _tokenController.text.trim();
    final success =
        await ref.read(authProvider.notifier).recoverWithToken(token);

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account recovered successfully')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.of(context).pushReplacementNamed('/main');
    } else {
      final authState = ref.read(authProvider);
      final err =
          authState.error ?? 'Failed to recover account. Check the token.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recover Account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Enter the session token provided by an admin to recover your account.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'Session Token',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a token'
                    : null,
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator()
                      : const Text('Recover'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
