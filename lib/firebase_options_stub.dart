import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static bool get isConfigured => false;

  static Future<FirebaseOptions?> load() async => null;

  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'DefaultFirebaseOptions are only available on web in this build.',
    );
  }
}
