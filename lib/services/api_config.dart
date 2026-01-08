import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// ============================================================================
/// API CONFIGURATION
/// ============================================================================
///
/// Configuration is loaded from the `.env` file in the project root.
///
/// ## Quick Setup:
/// 1. Copy `.env.example` to `.env`: `cp .env.example .env`
/// 2. Edit `.env` with your settings
/// 3. Run the app
///
/// ## Environment Variables:
/// - `USE_PRODUCTION` - Set to "production" or "development"
/// - `PRODUCTION_API_URL` - Your production API URL (e.g., https://api.yourdomain.com)
/// - `DEV_SERVER_HOST` - Local dev server IP (e.g., 192.168.1.100)
/// - `DEV_SERVER_PORT` - Local dev server port (e.g., 8000)
///
/// See `.env.example` for full documentation.
/// ============================================================================
class ApiConfig {
  // ==========================================================================
  // ENVIRONMENT VARIABLES (loaded from .env file)
  // ==========================================================================

  /// Whether to use production server (from USE_PRODUCTION env var)
  static bool get useProduction =>
      dotenv.env['USE_PRODUCTION']?.toLowerCase() == 'production';

  /// Production API URL (from PRODUCTION_API_URL env var)
  static String get productionBaseUrl =>
      dotenv.env['PRODUCTION_API_URL'] ?? 'https://api.example.com';

  /// Development server host (from DEV_SERVER_HOST env var)
  static String get devServerHost =>
      dotenv.env['DEV_SERVER_HOST'] ?? 'localhost';

  /// Development server port (from DEV_SERVER_PORT env var)
  static int get devServerPort =>
      int.tryParse(dotenv.env['DEV_SERVER_PORT'] ?? '8000') ?? 8000;

  // ==========================================================================
  // INTERNAL - You typically don't need to modify below this line
  // ==========================================================================

  /// Request timeout duration
  static Duration get timeout {
    final seconds = int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30') ?? 30;
    return Duration(seconds: seconds);
  }

  /// Development base URL (constructed from host and port)
  static String get _devBaseUrl {
    if (kIsWeb) {
      // Web apps need the full IP since 'localhost' refers to the user's device
      return 'http://$devServerHost:$devServerPort';
    }
    // Mobile emulators can use localhost (refers to the dev machine)
    return 'http://localhost:$devServerPort';
  }

  /// Current base URL based on [useProduction] setting
  static String get currentBaseUrl =>
      useProduction ? productionBaseUrl : _devBaseUrl;

  /// WebSocket URL (automatically derived from [currentBaseUrl])
  /// Converts http→ws and https→wss
  static String get wsBaseUrl =>
      currentBaseUrl.replaceFirst('https', 'wss').replaceFirst('http', 'ws');

  // Legacy getters for backwards compatibility
  @Deprecated('Use currentBaseUrl instead')
  static String get baseUrl => _devBaseUrl;
}
