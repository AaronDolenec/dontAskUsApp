import 'package:flutter/foundation.dart' show kIsWeb;

/// API configuration constants
class ApiConfig {
  /// Server IP address (change this to your server's IP)
  static const String serverHost = '192.168.178.135';

  /// API port
  static const int apiPort = 8000;

  /// Base URL for the API (development)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://$serverHost:$apiPort';
    }
    return 'http://localhost:$apiPort';
  }

  /// Production base URL (change when deploying)
  static const String productionBaseUrl = 'https://api.dontaskus.com';

  /// Request timeout duration
  static const Duration timeout = Duration(seconds: 30);

  /// WebSocket base URL
  static String get wsBaseUrl => baseUrl.replaceFirst('http', 'ws');

  /// Whether to use production URL
  static bool useProduction = false;

  /// Get the current base URL based on environment
  static String get currentBaseUrl =>
      useProduction ? productionBaseUrl : baseUrl;
}
