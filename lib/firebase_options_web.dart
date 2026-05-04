import 'dart:convert';

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:http/http.dart' as http;

class DefaultFirebaseOptions {
  static FirebaseOptions? _cachedConfig;

  static bool get isConfigured => _cachedConfig != null;

  static Future<FirebaseOptions?> load() async {
    if (_cachedConfig != null) {
      return _cachedConfig;
    }

    final response = await http.get(Uri.base.resolve('env.json'));
    if (response.statusCode != 200) {
      return null;
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      return null;
    }

    String? readValue(String key) {
      final dynamic value = decoded[key];
      if (value is String && value.trim().isNotEmpty && !value.startsWith('YOUR_')) {
        return value;
      }
      return null;
    }

    final apiKey = readValue('FIREBASE_API_KEY');
    final authDomain = readValue('FIREBASE_AUTH_DOMAIN');
    final projectId = readValue('FIREBASE_PROJECT_ID');
    final storageBucket = readValue('FIREBASE_STORAGE_BUCKET');
    final messagingSenderId = readValue('FIREBASE_MESSAGING_SENDER_ID');
    final appId = readValue('FIREBASE_APP_ID');
    final measurementId = readValue('FIREBASE_MEASUREMENT_ID') ?? '';

    if (apiKey == null ||
        authDomain == null ||
        projectId == null ||
        storageBucket == null ||
        messagingSenderId == null ||
        appId == null) {
      return null;
    }

    _cachedConfig = FirebaseOptions(
      apiKey: apiKey,
      authDomain: authDomain,
      projectId: projectId,
      storageBucket: storageBucket,
      messagingSenderId: messagingSenderId,
      appId: appId,
      measurementId: measurementId,
    );

    return _cachedConfig;
  }

  static FirebaseOptions get currentPlatform {
    final config = _cachedConfig;
    if (config != null) {
      return config;
    }

    throw StateError(
      'Firebase web config has not been loaded yet. Call DefaultFirebaseOptions.load() first.',
    );
  }
}
