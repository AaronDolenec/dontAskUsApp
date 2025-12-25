/// API configuration constants
class ApiConfig {
  /// Base URL for the API (development)
  static const String baseUrl = 'http://localhost:8000';
  
  /// Production base URL (change when deploying)
  static const String productionBaseUrl = 'https://api.dontaskus.com';
  
  /// Request timeout duration
  static const Duration timeout = Duration(seconds: 30);
  
  /// WebSocket base URL
  static String get wsBaseUrl => baseUrl.replaceFirst('http', 'ws');
  
  /// Whether to use production URL
  static bool useProduction = false;
  
  /// Get the current base URL based on environment
  static String get currentBaseUrl => useProduction ? productionBaseUrl : baseUrl;
}
