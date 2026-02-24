#!/usr/bin/env sh
set -e

# Generate a minimal env.json from environment variables so the web app can fetch runtime configuration.
# This lets you keep secrets in docker-compose env and avoid baking them into the build.

ENV_FILE=/srv/app/env.json

cat > "$ENV_FILE" <<'JSON'
{
  "API_BASE_URL": "${API_BASE_URL:-http://localhost:8000}",
  "FCM_PROJECT_ID": "${FCM_PROJECT_ID:-}",
  "OTHER_PUBLIC_CONFIG": "${OTHER_PUBLIC_CONFIG:-}"
}
JSON

echo "Wrote runtime env to $ENV_FILE"

# Start caddy (caddy will serve /srv/app)
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
