#!/usr/bin/env bash
# Drives the seeded test merchant + rider through the RIDERSIDE app on a
# booted iOS simulator (or any device id passed as $1).
#   scripts/e2e-emulator.sh [device-id]
# Seed first (once per environment):
#   php artisan db:seed --class=E2ETestAccountsSeeder
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST="auth_login_smoke_test"
if [ "${1:-}" = "full" ]; then TEST="full_flow_test"; shift; fi
DEVICE="${1:-$(xcrun simctl list devices booted | grep -Eo '[0-9A-F-]{36}' | head -1)}"
[ -n "$DEVICE" ] || { echo "No booted simulator; boot one or pass a device id"; exit 1; }

cd "$ROOT/RIDERSIDE"
flutter test integration_test/${TEST}.dart -d "$DEVICE" \
  --dart-define=LES_GO_TEST_MERCHANT_EMAIL="${MERCHANT_EMAIL:-merchant@test.com}" \
  --dart-define=LES_GO_TEST_MERCHANT_PASSWORD="${MERCHANT_PASSWORD:-Password123!}" \
  --dart-define=LES_GO_TEST_RIDER_EMAIL="${RIDER_EMAIL:-testrider@lesgo.com}" \
  --dart-define=LES_GO_TEST_RIDER_PASSWORD="${RIDER_PASSWORD:-TestRider123!}" \
  ${DART_DEFINE_FROM_FILE:+--dart-define-from-file="$DART_DEFINE_FROM_FILE"}
