#!/usr/bin/env bash
# Watch frontend/lib for Dart changes → sync (if VPS up) → hot restart Flutter.
set -euo pipefail
APP="${1:-/home/dewashish-hatekar/projects/SIH-Fixly/frontend}"
FIFO="${FIXLY_FLUTTER_FIFO:-/tmp/fixly-flutter-stdin}"
STAMP_FILE=/tmp/fixly-flutter-watch.stamp

fingerprint() {
  find "$APP/lib" -type f -name '*.dart' -printf '%p %T@\n' 2>/dev/null | sort | md5sum | awk '{print $1}'
}

echo "[watch] monitoring $APP/lib — hot restart on change"
LAST="$(fingerprint)"
echo "$LAST" >"$STAMP_FILE"

while true; do
  sleep 2
  NOW="$(fingerprint)"
  if [[ "$NOW" != "$LAST" ]]; then
    LAST="$NOW"
    echo "$LAST" >"$STAMP_FILE"
    echo "[watch] change detected $(date +%H:%M:%S)"
    if flutter-vps-sync push-fast "$APP" >/tmp/fixly-watch-sync.log 2>&1; then
      echo "[watch] synced → VPS"
    else
      echo "[watch] VPS sync skip/fail (local run OK)"
    fi
    if [[ -p "$FIFO" ]]; then
      # R = hot restart
      printf 'R\n' >"$FIFO" || true
      echo "[watch] sent hot restart (R)"
    else
      echo "[watch] no FIFO $FIFO — flutter run not attached"
    fi
  fi
done
