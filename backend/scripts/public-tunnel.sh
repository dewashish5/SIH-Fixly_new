#!/usr/bin/env bash
# Quick Cloudflare tunnel → local Fixly API (:8000). Prints public base URL.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${PORT:-8000}"
OUT="$ROOT/PUBLIC_URL"

if ! curl -sf "http://127.0.0.1:${PORT}/" >/dev/null; then
  echo "Backend not up on :${PORT}. Start: cd bakend-master && npm start" >&2
  exit 1
fi

if ! command -v cloudflared >/dev/null; then
  echo "cloudflared missing. Install: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/" >&2
  exit 1
fi

echo "Starting tunnel → http://127.0.0.1:${PORT} ..."
# Stream logs; capture first trycloudflare URL
cloudflared tunnel --url "http://127.0.0.1:${PORT}" --no-autoupdate 2>&1 | while IFS= read -r line; do
  echo "$line"
  if [[ "$line" =~ (https://[a-zA-Z0-9-]+\.trycloudflare\.com) ]]; then
    url="${BASH_REMATCH[1]}"
    echo "$url" >"$OUT"
    echo ""
    echo "==== PUBLIC API BASE URL ===="
    echo "$url"
    echo "Swagger: $url/api-docs"
    echo "(saved to bakend-master/PUBLIC_URL)"
    echo "============================="
  fi
done
