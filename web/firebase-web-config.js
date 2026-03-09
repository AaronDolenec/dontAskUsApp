// Firebase Web config used by both index page and messaging service worker.
// Replace placeholder values with your actual Firebase project values.
(function (global) {
  global.FIREBASE_WEB_CONFIG = {
    apiKey: 'YOUR_API_KEY',
    authDomain: 'YOUR_AUTH_DOMAIN',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    appId: 'YOUR_APP_ID',
    measurementId: 'YOUR_MEASUREMENT_ID',
  };
})(typeof self !== 'undefined' ? self : this);
