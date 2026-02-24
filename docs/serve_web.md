Why the web app is slow when exposed via pangolin or VS Code web-server
---------------------------------------------------------------

Root cause:
- When you run the app from VS Code using `flutter run -d web-server` (or the default debug/profile run), Flutter serves an unoptimized development build. That build includes large, unminified artifacts, source maps, and debugging scaffolding — resulting in a very large JavaScript payload (main.dart.js and others).
- Tunneling tools (pangolin/ngrok) forward all network traffic over a single encrypted tunnel. Downloading multi-megabyte debug artifacts over the tunnel is slow and exacerbates latency.

What to do instead (short answer):
1. Build a release-optimized web app: `flutter build web --release`.
2. Serve the generated `build/web/` folder with a static web server that enables gzip/brotli compression (nginx, Caddy, or an optimized static server). Use the provided Docker + nginx setup for easy testing.

Why this fixes it:
- The release build is minified, tree-shaken, and much smaller.
- Serving with gzip/brotli compresses transfer size further, reducing download time dramatically.
- A production static server sets long cache headers for hashed assets, so repeat visits are instant.

Quick steps for testing locally
1) Using Docker (recommended if you have docker installed):

   ./scripts/build_and_run_docker.sh

   Then open http://localhost:8080 (or expose that port in pangolin).

2) Quick fallback (no docker):

   ./scripts/serve_release_python.sh

   This serves the built files at http://localhost:8080 (no compression).

Notes and tips
- If you have a tunnel (pangolin/ngrok), point it at the container or port 8080 instead of exposing the VS Code web-server port; the release build will be much faster to download.
- For production-like testing, use the Docker/nginx option — it enables gzip and proper cache headers.
- If you need brotli compression, use Caddy or a custom nginx build with brotli support.
