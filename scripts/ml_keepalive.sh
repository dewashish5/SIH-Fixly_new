#!/usr/bin/env bash
# Local keepalive if GitHub Actions secret not set yet.
# Usage: ML_KEEPALIVE_URLS='https://a/health,https://b/health' ./scripts/ml_keepalive.sh
# Cron example (every 5 min): */5 * * * * ML_KEEPALIVE_URLS='...' /path/to/scripts/ml_keepalive.sh >>/tmp/ml-keepalive.log 2>&1
set -euo pipefail
: "${ML_KEEPALIVE_URLS:?set ML_KEEPALIVE_URLS to comma-separated health URLs}"
IFS=',' read -ra URLS <<< "$ML_KEEPALIVE_URLS"
for url in "${URLS[@]}"; do
  url="$(echo "$url" | xargs)"
  [ -z "$url" ] && continue
  code=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 90 "$url" || echo "000")
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $url -> $code"
done
