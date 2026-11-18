# LeSgo workspace

Monorepo: `RIDERSIDE/` (Flutter, rider + merchant app, bundle `com.lesgo.rider`, package `lezgo_rider`),
`FRONTEND/` (Flutter customer app, package `lesgo`), `BACKEND/lesgo-api/` (Laravel 12 API),
`Lesgo-Admin-Panel/` (separate Laravel admin app).

## Backend ships from a different repo
- Deploys come from `carlkelvin8/Lesgo-API`, branch `feature/auth` (auto-deploys on Laravel Cloud, runs migrations).
- That repo has diverged from `BACKEND/lesgo-api/`. Never copy the folder over it: clone it, apply only your
  changes as a patch, test there, then push. Use the `backend-push` skill. Push straight to `feature/auth`, no new branch.
- Lesgo-API's suite is fully green (574 tests, 2026-11-18). Test it in a clone with a copied `vendor` + `composer
  dump-autoload`, never a symlinked one (that runs the monorepo's code and fakes ~15 failures).
- Pushing to production needs the user's explicit OK in the same turn; the harness blocks it otherwise.

## Commands
- Flutter (run inside `RIDERSIDE/` or `FRONTEND/`): `flutter analyze`, `flutter test`.
  All 369 RIDERSIDE tests passed on 2026-11-18 (the old "rejected refresh token (401)" failure is gone).
- Laravel (inside `BACKEND/lesgo-api/`): `php artisan test` (sqlite in memory, ~10 s, 534 tests).
- `RIDERSIDE/build` is a symlink to a temp dir that can disappear: `mkdir -p "$(readlink build)"` before flutter test/build.
- Never run two `flutter test` at once in one app. Local e2e/simulator setup: see memory `local-e2e-test-setup`.
- `Lesgo-Admin-Panel/` tests need `composer install`, a `.env` (copy `.env.example`, quote `PAYMONGO_WALLET_ACCOUNT_NAME`),
  `php artisan key:generate` and `npm ci && npm run build` (pages fail with a Vite manifest error otherwise). 97 tests, ~3 s.
- A PostToolUse hook (`.claude/hooks/check-edit.sh`) runs `dart analyze` / `php -l` after every edit and reports errors.

## Releasing the rider app (TestFlight)
Use the `ship-testflight` skill. Bump `RIDERSIDE/pubspec.yaml` `version: 1.1.8+N` first; TestFlight rejects a repeated build number.
The App Store submission of 1.1.7 (34) was rejected (2.1.0) and is on hold; TestFlight only for now. The 1.1.7 train is
closed (altool error 90186), so TestFlight builds are 1.1.8+ (43 uploaded 2026-11-18, delivery dbb93c8e).
`xcodebuild -exportArchive` fails with "requires a provisioning profile with the Push Notifications feature" unless the
ExportOptions.plist is manual: `signingStyle manual`, `signingCertificate "Apple Distribution"`,
`provisioningProfiles {com.lesgo.rider: "LeSgo Rider App Store"}` (installed locally, includes aps-environment production).

## Releasing the customer app (TestFlight)
Bump `FRONTEND/pubspec.yaml` `version: 1.1.8+N` (28 uploaded 2026-11-18, delivery f81c3909; 1.1.8 is "Waiting for Review").
From `FRONTEND/`: `mkdir -p "$(readlink build)"` then `flutter build ipa --release --dart-define-from-file=secrets.json`
(production values; never build with a define file that sets `API_BASE_URL`: that is the local-sandbox override).
It signs automatically and also writes `build/ios/ipa/LeSgo.ipa`; upload with
`xcrun altool --upload-app --type ios -f build/ios/ipa/LeSgo.ipa --apiKey Z346X95BXU --apiIssuer c83c8489-37ab-49af-a0e6-5d1c09aa5f32`.
A release archive needs about 8 GB free; with less it dies with "No space left on device". After "Processing" finishes
(10-30 min), assign the build to TestFlight groups "LeSgo Team" (internal) and "LeSgo Customer Public" (external, needs Beta App Review).
Simulator testing of the customer app: see memory `local-e2e-test-setup` (the prebuilt simulator app points at production unless built with the local define).

## Conventions that bit us
- Dark mode: never hardcode `Colors.white` / dark text in screens. Use `context.surf/bg/txt/sub/acc/brd(<light colour>)`
  from `lib/core/utils/dark_aware_colors.dart` (returns the light colour unchanged in light mode).
- Merchant/rider strings: `context.tr('English text')` (English is the key; Filipino in
  `lib/core/utils/merchant_translations.dart`). Missing translation falls back to English.
- Errors shown to users: `ApiErrorMapper.message(e)`; never `'$e'` or `e.toString()`.
- Riverpod: in form/edit providers do NOT `ref.watch` the source providers; it rebuilds the notifier and wipes what the
  user typed. Use `ref.read` + `ref.listen`.
- Maps: no dashed/dotted polylines on long routes (iOS kills the app), validate coordinates before giving them to GoogleMap.
- Login must send a per-install `device_name`; the server revokes tokens by device name on refresh.
- Fares: always go through `FareCalculatorService` (admin per-km rate, no free km except LesRide's 3 km).
- Money code (wallet debit/credit, refunds, withdrawals): inside a transaction with `lockForUpdate`, idempotent, and refund
  the recorded amount, never a recomputed one.

## Push notifications
- kreait/firebase-php is v8: build messages with `CloudMessage::new()->toToken($t)`. `withTarget()` does not exist; it threw
  inside `FcmService::sendToToken`'s catch, so no push was ever sent until 2026-11-18. Watch the logs for `FCM send failed`.
- iOS plays no sound unless `aps.sound` is set; `FcmService` sets it. Order alerts (`new_order_available`,
  `new_merchant_order`, `order.assigned`) target the Android channel `lezgo_orders` (created in `FcmService._initLocalNotifications`
  with `res/raw/order_bell.wav`). Channel sound is immutable once created: use a new channel id to change it.
- `assets/sounds/*.wav` are generated tones (the old `.mp3` placeholders were 0 bytes, so the in-app alarm was silent).
- Needs the queue worker for `notifications` and the scheduler (renewal reminder 09:00, renewals hourly) running in production.

## Accounts
Demo/test logins live in the seeders (`database/seeders/TestMerchantSeeder.php`) and `RIDERSIDE/create_test_rider.sh`.
Do not paste them into chat unless asked; production state of those accounts is unknown.
