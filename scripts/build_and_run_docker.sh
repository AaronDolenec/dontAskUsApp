#!/usr/bin/env bash
set -euo pipefail

# Build an optimized Flutter web release and run it in a lightweight nginx container.
# Requires: flutter, docker

echo "Building Flutter web (release) with PWA offline-first strategy..."
# Use offline-first service worker so subsequent loads are cached and near-instant
flutter build web --release --pwa-strategy=offline-first

# Pre-compress static assets (gzip + brotli if available) to improve transfer times
./scripts/precompress_build.sh || true

echo "Building Docker image..."
docker build -t dontaskus-web:latest -f docker/Dockerfile .

echo "Running Docker container on http://localhost:8080"
docker run --rm -p 8080:80 dontaskus-web:latest
