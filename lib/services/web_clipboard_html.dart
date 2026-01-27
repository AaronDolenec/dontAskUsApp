// Web implementation using native Clipboard API with a textarea fallback.
// This file intentionally imports `dart:html` and is only used on web via
// conditional imports.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Attempt to write [text] to the clipboard using modern API first, then
/// fall back to a textarea + execCommand('copy') for older browsers / insecure
/// contexts.
Future<bool> writeTextToClipboard(String text) async {
  try {
    final nav = html.window.navigator;
    if (nav.clipboard != null) {
      await nav.clipboard!.writeText(text);
      return true;
    }
  } catch (_) {
    // ignore and try fallback
  }

  try {
    final textarea = html.TextAreaElement();
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.left = '-9999px';
    html.document.body?.append(textarea);
    textarea.select();
    final success = html.document.execCommand('copy');
    textarea.remove();
    return success;
  } catch (_) {
    return false;
  }
}
