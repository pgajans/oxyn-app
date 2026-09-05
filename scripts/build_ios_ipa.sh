#!/usr/bin/env bash
# App Store IPA. Release'te test_ anahtarı IAP'yi kapatır; appl_ zorunlu.
#
#   export REVENUECAT_IOS_KEY=appl_...
#   ./scripts/build_ios_ipa.sh
#
# İsteğe bağlı: proje kökünde .env.ios (gitignore) → REVENUECAT_IOS_KEY=appl_...

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

if [[ -z "$KEY" ]]; then
  echo "REVENUECAT_IOS_KEY boş. .env.ios dosyası oluştur veya export et."
  echo "Örnek: echo 'REVENUECAT_IOS_KEY=appl_xxx' > .env.ios"
  exit 1
fi

if [[ "$KEY" == test_* ]]; then
  echo "test_ anahtarı release IPA'da kullanılamaz. appl_ (App Store) anahtarı gerekli."
  exit 1
fi

if [[ "$KEY" != appl_* ]]; then
  echo "Anahtar appl_ ile başlamalı (RevenueCat App Store public key)."
  exit 1
fi

echo "==> flutter clean"
flutter clean

echo "==> DerivedData (Runner) siliniyor — simulator slice kirliliğini önler"
rm -rf "$HOME/Library/Developer/Xcode/DerivedData/Runner-"*

echo "==> flutter pub get"
flutter pub get

echo "==> flutter build ipa --release"
flutter build ipa --release \
  --export-options-plist=ios/ExportOptions.plist \
  --dart-define="REVENUECAT_IOS_KEY=$KEY"

IPA="$ROOT/build/ios/ipa/oxyn.ipa"
if [[ ! -f "$IPA" ]]; then
  # Flutter sometimes names the IPA after the display name.
  IPA="$(find "$ROOT/build/ios/ipa" -name '*.ipa' | head -n 1 || true)"
fi

if [[ -z "${IPA:-}" || ! -f "$IPA" ]]; then
  echo "IPA bulunamadı: build/ios/ipa/"
  exit 1
fi

echo "Hazır: $IPA"
echo "Transporter ile App Store Connect'e yükle. Sonra yeni sürüm numarası seç."
