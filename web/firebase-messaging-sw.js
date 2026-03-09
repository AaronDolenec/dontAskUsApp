// Firebase Messaging service worker
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');
importScripts('./firebase-web-config.js');

function hasRealValue(value) {
  if (typeof value !== 'string') return false;
  if (!value.trim()) return false;
  return !value.startsWith('YOUR_');
}

function isValidFirebaseConfig(config) {
  if (!config || typeof config !== 'object') return false;
  return (
    hasRealValue(config.apiKey) &&
    hasRealValue(config.projectId) &&
    hasRealValue(config.messagingSenderId) &&
    hasRealValue(config.appId)
  );
}

const firebaseConfig = self.FIREBASE_WEB_CONFIG || null;

if (isValidFirebaseConfig(firebaseConfig)) {
  try {
    firebase.initializeApp(firebaseConfig);
    const messaging = firebase.messaging();

    // Optional: handle background messages
    messaging.onBackgroundMessage(function (payload) {
      console.log('[firebase-messaging-sw.js] Received background message ', payload);
      const notificationTitle = payload.notification?.title || 'Notification';
      const notificationOptions = {
        body: payload.notification?.body,
        icon: '/icons/Icon-192.png',
      };

      self.registration.showNotification(notificationTitle, notificationOptions);
    });
  } catch (err) {
    console.warn('[firebase-messaging-sw.js] Firebase messaging disabled:', err);
  }
} else {
  console.info(
    '[firebase-messaging-sw.js] Firebase config missing; messaging SW initialization skipped.',
  );
}
