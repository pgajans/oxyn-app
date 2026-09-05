#!/usr/bin/env bash
# iOS Simulator: StoreKit + gerçek App Store public key.
#   cp .env.ios.example .env.ios   # appl_ anahtarını yaz
#   ./scripts/run_ios.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -f "$ROOT/.env.ios" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env.ios"
  set +a
fi

KEY="${REVENUECAT_IOS_KEY:-}"
if [[ -z "$KEY" || "$KEY" == test_* || "$KEY" != appl_* ]]; then
  echo "REVENUECAT_IOS_KEY appl_ olmalı. .env.ios oluştur (bkz. .env.ios.example)."
  exit 1
fi

DEVICE="${1:-}"
if [[ -z "$DEVICE" ]]; then
  flutter run --dart-define="REVENUECAT_IOS_KEY=$KEY"
else
  flutter run -d "$DEVICE" --dart-define="REVENUECAT_IOS_KEY=$KEY"
fi
