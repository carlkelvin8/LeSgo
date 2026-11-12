# LeSgo workspace

Monorepo: `RIDERSIDE/` (Flutter, rider + merchant app, bundle `com.lesgo.rider`, package `lezgo_rider`),
`FRONTEND/` (Flutter customer app, package `lesgo`), `BACKEND/lesgo-api/` (Laravel 12 API),
`Lesgo-Admin-Panel/` (separate Laravel admin app).

## Backend ships from a different repo
- Deploys come from `carlkelvin8/Lesgo-API`, branch `feature/auth` (auto-deploys on Laravel Cloud, runs migrations).
- That repo has diverged from `BACKEND/lesgo-api/`. Never copy the folder over it: clone it, apply only your
  changes as a patch, test there, then push. Use the `backend-push` skill. Push straight to `feature/auth`, no new branch.
- About 14 tests already fail in Lesgo-API at baseline; compare before/after instead of expecting green.
- Pushing to production needs the user's explicit OK in the same turn; the harness blocks it otherwise.

## Commands
- Flutter (run inside `RIDERSIDE/` or `FRONTEND/`): `flutter analyze`, `flutter test`.
  Known failing test since before 2026-11: `rider_auth_login_fixes_test.dart` "rejected refresh token (401)".
- Laravel (inside `BACKEND/lesgo-api/`): `php artisan test` (sqlite in memory, ~10 s, 511 tests).
- `RIDERSIDE/build` is a symlink to a temp dir that can disappear: `mkdir -p "$(readlink build)"` before flutter test/build.
- Never run two `flutter test` at once in one app. Local e2e/simulator setup: see memory `local-e2e-test-setup`.
- A PostToolUse hook (`.claude/hooks/check-edit.sh`) runs `dart analyze` / `php -l` after every edit and reports errors.

## Releasing the rider app (TestFlight)
Use the `ship-testflight` skill. Bump `RIDERSIDE/pubspec.yaml` `version: 1.1.7+N` first; TestFlight rejects a repeated build number.
The App Store submission of 1.1.7 (34) was rejected (2.1.0) and is on hold; TestFlight only for now.

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

## Accounts
Demo/test logins live in the seeders (`database/seeders/TestMerchantSeeder.php`) and `RIDERSIDE/create_test_rider.sh`.
Do not paste them into chat unless asked; production state of those accounts is unknown.
