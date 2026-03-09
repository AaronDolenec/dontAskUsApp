import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'push_notification_service.dart';

/// Handles one-time async initialization required by the app.
///
/// This is intentionally decoupled from `main()` so first frame can render
/// quickly (splash appears immediately) while setup continues in background.
class AppBootstrapService {
  static Future<void>? _bootstrapFuture;

  static Future<void> ensureInitialized() {
    _bootstrapFuture ??= _initialize();
    return _bootstrapFuture!;
  }

  static Future<void> _initialize() async {
    // Run non-dependent startup tasks concurrently.
    await Future.wait<void>([
      _loadEnvSafely(),
      PushNotificationService.initialize(),
    ]);
  }

  static Future<void> _loadEnvSafely() async {
    try {
      await dotenv.load();
    } catch (e) {
      // Continue with built-in defaults from ApiConfig if .env is unavailable.
      debugPrint('Bootstrap warning: dotenv not loaded ($e)');
    }
  }
}
