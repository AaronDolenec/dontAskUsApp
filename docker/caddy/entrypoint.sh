#!/usr/bin/env sh
set -e

# Generate a minimal env.json from environment variables so the web app can fetch runtime configuration.
# This lets you keep secrets in docker-compose env and avoid baking them into the build.

FIREBASE_CONFIG_FILE=/srv/app/firebase-web-config.js

ENV_FILE=/srv/app/env.json

cat > "$ENV_FILE" <<EOF
{
  "API_BASE_URL": "${API_BASE_URL:-http://localhost:8000}",
  "FCM_PROJECT_ID": "${FCM_PROJECT_ID:-}",
  "FIREBASE_API_KEY": "${FIREBASE_API_KEY:-YOUR_FIREBASE_API_KEY}",
  "FIREBASE_AUTH_DOMAIN": "${FIREBASE_AUTH_DOMAIN:-YOUR_FIREBASE_AUTH_DOMAIN}",
  "FIREBASE_PROJECT_ID": "${FIREBASE_PROJECT_ID:-YOUR_FIREBASE_PROJECT_ID}",
  "FIREBASE_STORAGE_BUCKET": "${FIREBASE_STORAGE_BUCKET:-YOUR_FIREBASE_STORAGE_BUCKET}",
  "FIREBASE_MESSAGING_SENDER_ID": "${FIREBASE_MESSAGING_SENDER_ID:-YOUR_FIREBASE_MESSAGING_SENDER_ID}",
  "FIREBASE_APP_ID": "${FIREBASE_APP_ID:-YOUR_FIREBASE_APP_ID}",
  "FIREBASE_MEASUREMENT_ID": "${FIREBASE_MEASUREMENT_ID:-}",
  "OTHER_PUBLIC_CONFIG": "${OTHER_PUBLIC_CONFIG:-}"
}
EOF

cat > "$FIREBASE_CONFIG_FILE" <<EOF
// Firebase Web config used by both index page and messaging service worker.
// This file is generated at container start from docker-compose environment variables.
(function (global) {
  global.FIREBASE_WEB_CONFIG = {
    apiKey: '${FIREBASE_API_KEY:-YOUR_FIREBASE_API_KEY}',
    authDomain: '${FIREBASE_AUTH_DOMAIN:-YOUR_FIREBASE_AUTH_DOMAIN}',
    projectId: '${FIREBASE_PROJECT_ID:-YOUR_FIREBASE_PROJECT_ID}',
    storageBucket: '${FIREBASE_STORAGE_BUCKET:-YOUR_FIREBASE_STORAGE_BUCKET}',
    messagingSenderId: '${FIREBASE_MESSAGING_SENDER_ID:-YOUR_FIREBASE_MESSAGING_SENDER_ID}',
    appId: '${FIREBASE_APP_ID:-YOUR_FIREBASE_APP_ID}',
    measurementId: '${FIREBASE_MEASUREMENT_ID:-}',
  };
})(typeof self !== 'undefined' ? self : this);
EOF

echo "Wrote runtime env to $ENV_FILE"
echo "Wrote Firebase web config to $FIREBASE_CONFIG_FILE"

# Start caddy (caddy will serve /srv/app)
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
