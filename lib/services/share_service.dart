import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../utils/utils.dart';
// Conditional import: web implementation uses `dart:html` APIs; non-web stub
// provides a no-op implementation to keep imports safe on non-web targets.
import 'web_clipboard_stub.dart'
    if (dart.library.html) 'web_clipboard_html.dart' as web_clipboard;

/// Service for sharing invite codes and deep links
class ShareService {
  /// Share invite code via system share sheet
  static Future<void> shareInviteCode(String inviteCode,
      {String? groupName}) async {
    final message = groupName != null
        ? 'Join my group "$groupName" on dontAskUs!\n\nInvite code: $inviteCode\n\nDownload the app and use this code to join!'
        : 'Join my group on dontAskUs!\n\nInvite code: $inviteCode';

    await Share.share(
      message,
      subject: 'Join my dontAskUs group!',
    );
  }

  /// Copy invite code to clipboard with web fallback
  /// Returns true if successful, false otherwise
  static Future<bool> copyInviteCode(String inviteCode) async {
    // Try Flutter's Clipboard first (works on mobile and secure web origins)
    try {
      await Clipboard.setData(ClipboardData(text: inviteCode));
      return true;
    } catch (_) {
      // If we're on web, try the JS DOM clipboard APIs as a fallback.
      if (kIsWeb) {
        try {
          return await web_clipboard.writeTextToClipboard(inviteCode);
        } catch (_) {
          return false;
        }
      }

      return false;
    }
  }

  /// Generic copy helper for arbitrary text values. Uses the same web
  /// fallback as `copyInviteCode` so that copy works on non-HTTPS web
  /// contexts and on mobile/desktop platforms.
  static Future<bool> copyText(String text) async {
    if (text.isEmpty) return false;
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (_) {
      if (kIsWeb) {
        try {
          return await web_clipboard.writeTextToClipboard(text);
        } catch (_) {
          return false;
        }
      }
      return false;
    }
  }

  /// Show a snackbar with copy result
  static void showCopyResult(BuildContext context, bool success, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Copied to clipboard!' : 'Could not copy. Code: $text',
        ),
        action: success
            ? null
            : SnackBarAction(
                label: 'OK',
                onPressed: () {},
              ),
        duration: Duration(seconds: success ? 2 : 5),
      ),
    );
  }

  /// Generate deep link for invite code
  static String generateDeepLink(String inviteCode) {
    return 'dontaskus://join/$inviteCode';
  }
}

/// Widget that displays a QR code for an invite code
class InviteQrCode extends StatelessWidget {
  final String inviteCode;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const InviteQrCode({
    super.key,
    required this.inviteCode,
    this.size = 200,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: ShareService.generateDeepLink(inviteCode),
            size: size,
            backgroundColor: Colors.white,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: foregroundColor ?? AppColors.primary,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: foregroundColor ?? AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            inviteCode,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: isDark ? Colors.black87 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for sharing invite code
class ShareInviteBottomSheet extends StatelessWidget {
  final String inviteCode;
  final String? groupName;

  const ShareInviteBottomSheet({
    super.key,
    required this.inviteCode,
    this.groupName,
  });

  static Future<void> show(
    BuildContext context, {
    required String inviteCode,
    String? groupName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareInviteBottomSheet(
        inviteCode: inviteCode,
        groupName: groupName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Share Invite Code',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (groupName != null) ...[
                const SizedBox(height: 4),
                Text(
                  groupName!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                ),
              ],
              const SizedBox(height: 24),
              InviteQrCode(
                inviteCode: inviteCode,
                size: 180,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final success = await ShareService.copyInviteCode(
                          inviteCode,
                        );
                        if (context.mounted) {
                          ShareService.showCopyResult(
                            context,
                            success,
                            inviteCode,
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ShareService.shareInviteCode(
                          inviteCode,
                          groupName: groupName,
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
