import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/utils.dart';

class InviteCodeInput extends StatefulWidget {
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? errorText;
  final bool enabled;
  final bool autofocus;

  const InviteCodeInput({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
  });

  @override
  State<InviteCodeInput> createState() => _InviteCodeInputState();
}

class _InviteCodeInputState extends State<InviteCodeInput> {
  late TextEditingController _controller;
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();

    // Sync individual controllers with main controller
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() {
        _updateMainController();
      });
    }

    // Initialize from main controller if it has value
    if (_controller.text.isNotEmpty) {
      _setCodeFromString(_controller.text);
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _updateMainController() {
    final code = _controllers.map((c) => c.text).join();
    _controller.text = code;
    widget.onChanged?.call(code);

    if (code.length == 6) {
      widget.onSubmitted?.call(code);
    }
  }

  void _setCodeFromString(String code) {
    for (int i = 0; i < code.length && i < 6; i++) {
      _controllers[i].text = code[i].toUpperCase();
    }
  }

  void _handleKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          _focusNodes[index - 1].requestFocus();
          _controllers[index - 1].clear();
        }
      }
    }
  }

  Future<void> _pasteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final code =
          data!.text!.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
      if (code.length >= 6) {
        _setCodeFromString(code.substring(0, 6));
        _focusNodes.last.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Container(
              width: 48,
              height: 56,
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 4,
                right: index == 5 ? 0 : 4,
                // Add gap after 3rd character
              ).copyWith(
                right: index == 2 ? 12 : (index == 5 ? 0 : 4),
              ),
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) => _handleKeyEvent(index, event),
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  enabled: widget.enabled,
                  autofocus: widget.autofocus && index == 0,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: widget.enabled
                        ? Colors.grey[50]?.withValues(alpha: 1)
                        : Colors.grey[200]?.withValues(alpha: 1),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(1),
                    UpperCaseTextFormatter(),
                  ],
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    }
                  },
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),

        // Paste button
        Center(
          child: TextButton.icon(
            onPressed: widget.enabled ? _pasteCode : null,
            icon: const Icon(Icons.paste, size: 18),
            label: const Text('Paste Code'),
          ),
        ),

        // Error text
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

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

class InviteCodeDisplay extends StatelessWidget {
  final String code;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  const InviteCodeDisplay({
    super.key,
    required this.code,
    this.onCopy,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final formattedCode = code.length == 6
        ? '${code.substring(0, 3)}-${code.substring(3)}'
        : code;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Invite Code',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            formattedCode,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onCopy != null)
                OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                ),
              if (onCopy != null && onShare != null) const SizedBox(width: 12),
              if (onShare != null)
                ElevatedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
