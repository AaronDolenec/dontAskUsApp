#!/usr/bin/env bash
set -euo pipefail

# Create gzipped and brotli-compressed versions of files in build/web
# Requires: brotli (optional), gzip (available)

BUILD_DIR="build/web"

if [ ! -d "$BUILD_DIR" ]; then
  echo "No build directory found at $BUILD_DIR. Run 'flutter build web' first." >&2
  exit 1
fi

echo "Precompressing files in $BUILD_DIR"

# Find relevant files (js, css, html, json, svg)
find "$BUILD_DIR" -type f \( -iname "*.js" -o -iname "*.css" -o -iname "*.html" -o -iname "*.json" -o -iname "*.svg" \) | while read -r f; do
  echo "Compressing: $f"
  # gzip (keep original, create .gz)
  gzip -kf "$f" || true
  # brotli (create .br) if available
  if command -v brotli >/dev/null 2>&1; then
    brotli -f -q 11 -o "$f.br" "$f" || true
  fi
done

echo "Precompression complete. Note: nginx must be configured to serve .gz/.br variants or use gzip on-the-fly." 
