#!/usr/bin/env bash
set -euo pipefail

# Quick local test server for built release. No gzip, but useful if docker isn't available.
# Requires: flutter, python3

echo "Building Flutter web (release) with offline-first PWA..."
flutter build web --release --pwa-strategy=offline-first

echo "Precompressing assets (gzip + brotli if available)..."
./scripts/precompress_build.sh || true

echo "Serving build/web on http://localhost:8080"
python3 -m http.server 8080 --directory build/web
