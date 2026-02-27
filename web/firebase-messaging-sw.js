// Firebase Messaging service worker
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

// Note: Replace the config below with your Firebase project config if necessary.
// When using flutterfire, the generated firebase config should be available
// in the compiled JS, so you may not need to repeat it here.

firebase.initializeApp({
  // default config can be empty; flutter build will include real config
});

const messaging = firebase.messaging();

// Optional: handle background messages
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification?.title || 'Notification';
  const notificationOptions = {
    body: payload.notification?.body,
    icon: '/icons/Icon-192.png',
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
