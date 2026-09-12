#!/usr/bin/env bash
while true; do
  if adb get-state 2>/dev/null | grep -q "device"; then
    adb reverse tcp:8005 tcp:8005 >/dev/null 2>&1
    adb reverse tcp:8000 tcp:8005 >/dev/null 2>&1
  fi
  sleep 4
done
