// This file is required for Firebase initialization on web.
// Replace the below config with your actual Firebase project config.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static bool get isConfigured {
    bool hasRealValue(String value) => value.trim().isNotEmpty && !value.startsWith('YOUR_');

    return hasRealValue(web.apiKey) &&
        hasRealValue(web.projectId) &&
        hasRealValue(web.messagingSenderId) &&
        hasRealValue(web.appId);
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA6MIrdOnqw2zSAgthx6chWxp0fCDydRP4',
    authDomain: 'dontaskus-753ab.firebaseapp.com',
    projectId: 'dontaskus-753ab',
    storageBucket: 'dontaskus-753ab.firebasestorage.app',
    messagingSenderId: '216907158422',
    appId: '1:216907158422:web:f67d76e3884ba8d785c3b7',
    measurementId: '',
  );
}
