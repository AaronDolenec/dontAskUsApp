Project security checklist and runtime configuration
===============================================

Summary
-------
This document lists security-relevant files and explains how to keep secrets out of the public repo while enabling a reproducible developer and CI workflow. The repo already ignores `.env` and several secret files; below are extra steps and the recommended docker-compose approach.

Sensitive locations found in this repository
- `.env` (development server config) — currently present in the repo root; ensure it contains no production secrets before making the repo public.
- `android/key.properties.example` and `android/key.properties` (keystore info). The example is safe; keep `android/key.properties` out of source control (already in `.gitignore`).
- `ios/fastlane` and `android/fastlane` references — CI secrets often referenced here (MATCH_GIT_URL etc.). Do not commit real credentials.
- `COMPLETE_API_DOCUMENTATION.md` contains environment variable names (e.g., `SECRET_KEY`, `ADMIN_JWT_SECRET`, `FCM_SERVICE_ACCOUNT_JSON`) — these are documentation-only but indicate required runtime secrets.
- `secrets/` (if present) — `.gitignore` prevents committing this folder; keep it excluded.

What I added
- `docker/docker-compose.example.yml` — an example compose file with placeholders for all runtime variables. This file is safe to commit and does not contain secrets.
- `.gitignore` updated to exclude `docker-compose.yml` and `docker-compose.override.yml` so your private compose file containing secrets stays local.
- `docker/caddy/` — Caddy-based static server (brotli + gzip) and an `entrypoint.sh` that emits a runtime `env.json` from compose environment variables. This keeps secret values in compose and out of the built static files.

How to use (recommended) — local testing
1. Build the Flutter web release locally:
   ```bash
   flutter build web --release --pwa-strategy=offline-first
   ```
2. Copy `docker/docker-compose.example.yml` to `docker/docker-compose.yml` (this file is ignored by git) and fill in your secrets and configuration:
   - `API_BASE_URL` — the API endpoint the web app should talk to
   - `FCM_PROJECT_ID`, `FCM_SERVICE_ACCOUNT_JSON` — for push notifications (optional)
   - `SECRET_KEY`, etc. — any secrets your server requires. For the web client only public config should be provided here; keep private server-only secrets in the server's compose or secret management system.
3. Start the service:
   ```bash
   cd docker
   docker compose up --build
   ```

Notes about runtime configuration vs build-time configuration
- Flutter web often uses a build-time `.env` (via `flutter_dotenv`). That is baked into the JS at build time and therefore cannot safely contain production secrets in a public repo. Instead:
  - Use `.env` (local) for developer convenience — ensure `.env` is in `.gitignore` (it is).
  - For runtime secrets and public runtime configuration, use the `env.json` approach implemented in the Caddy image: Compose passes variables to the container which writes `/srv/app/env.json` that the web app can fetch at runtime.

Preparing for a public GitHub repo
1. Remove any real secrets from the repo. Search for strings like `SECRET_KEY`, `API_KEY`, `private_key`, or any JSON-looking credentials. Replace with examples or placeholders.
2. Ensure `.env` (and `.env.*`) are in `.gitignore`. They already are.
3. Ensure `android/key.properties` (the real keystore) and any keystores are not in source control. They are ignored already.
4. Use `docker-compose.yml` (private) to store runtime secrets locally or in CI secrets (GitHub Actions secrets). Commit only `docker-compose.example.yml`.

Mobile builds
- Mobile builds (Android/iOS) commonly require keystore files (`.jks`) and platform-specific service account files for Firebase (e.g., `google-services.json`, `GoogleService-Info.plist`). These must never be committed to a public repo. Keep examples like `android/key.properties.example` in the repo and provide instructions for developers to create their own `key.properties` and place the keystore locally.
- For mobile runtime configuration, prefer build-time injection via a local `.env` (ignored by git) or use CI to inject secrets during the build step (use GitHub Actions secrets). The `env.json` approach is only applicable to web and will not affect mobile builds.

CI & publishing notes
- The GitHub Actions workflow added earlier uses the repository's `GITHUB_TOKEN` to publish the Docker image to GHCR. For production secrets in CI, use repository or organization secrets (Settings → Secrets) and avoid embedding secrets in workflows. For mobile build publishing (Play Store / App Store), use Fastlane match or secure CI secrets as needed; `docs/BUILD_IPA.md` already lists required secrets.

If you want, I can:
- Add a small runtime check that fails CI if certain sensitive files are accidentally committed (a pre-commit or a GitHub Action that scans for private key headers or base64 PEM blobs).
- Add a script to validate that `build/web/env.json` contains no secret-like values before we package and publish.
