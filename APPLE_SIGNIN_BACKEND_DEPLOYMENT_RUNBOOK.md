# Sign in with Apple — Backend Deployment Runbook (Laravel Cloud)

Scope: ship the Sign in with Apple backend changes in `BACKEND/lesgo-api` to the **existing** LeSGo Laravel Cloud application. No new app, database, or environment is created.

Nothing in this document has been executed against production. Everything below was verified locally only (SQLite, PHPUnit).

---

## 1. What changes in production

| Area | Change | Risk to existing users |
|------|--------|------------------------|
| Route | `POST /api/v1/auth/apple` (inside the existing `throttle:auth` group) | New route only |
| Migration | `2026_10_12_000001_add_apple_id_to_users_table` adds nullable, unique `users.apple_id` | Additive; existing rows get `NULL` |
| Auth | `AppleAuthController`, `AppleIdentityService` (new files) | Isolated from Google/email flows |
| Account deactivate / delete | Accept `apple_id_token` + `apple_nonce` (+ `apple_authorization_code` on delete) in addition to `password` / `google_id_token` | Password and Google paths unchanged |
| `AccountDeletionService` | Clears `apple_id` **only if the column exists** | Safe before and after migration |
| `User` model | `apple_id` fillable and hidden (never serialized) | None |
| Config | `services.apple.*` | Defaults work with no env changes |

Not touched: Android app, Google Sign-In endpoint, email/password login, registration, tokens, Sanctum, orders, payments.

## 2. Verification performed (local)

| Check | Result |
|-------|--------|
| `php -l` on every changed PHP file | Clean |
| `AppleSignInTest` (12 tests: login, signup, linking, private relay, bad aud/iss/nonce/expiry/garbage, takeover attempt, inactive, delete, stale token, deactivate, revocation skipped, apple_id hidden, migration idempotent) | 12/12 pass |
| `AccountDeletionAndGoogleAuthTest`, `AuthTest`, `AuthenticationTest` | Pass |
| Full suite (`php -d memory_limit=2G vendor/bin/phpunit`) | 372 / 373 pass. The single failure, `PaymentHardeningTest::test_wallet_topup_ignores_untrusted_wallet_amount_metadata` (502), **fails identically on a clean checkout**; it is unrelated |
| Migration against a DB with legacy rows | `up()` twice (idempotent), rows preserved, all `apple_id` NULL, unique enforced, `down()` works |
| Generated PostgreSQL SQL | `alter table "users" add column "apple_id" varchar(255) null` then `add constraint "users_apple_id_unique" unique ("apple_id")` |

**Not verified:** a real PostgreSQL run, a real Apple token, Apple's revocation endpoint, and the live Laravel Cloud dashboard configuration.

Note: the default PHP `memory_limit` of 128M exhausts on the full suite; use `-d memory_limit=2G`.

## 3. Migration safety (PostgreSQL 15)

- `ADD COLUMN ... NULL` with no default is a metadata-only change (instant).
- `ADD CONSTRAINT UNIQUE` builds an index and briefly takes an exclusive lock on `users`. For a table of thousands to low hundreds of thousands of rows this is milliseconds to seconds. Deploy outside peak hours anyway.
- Multiple `NULL`s are allowed by a unique constraint, so existing users are not affected.
- Idempotent: guarded by `Schema::hasColumn`.
- Rollback of the migration drops the column and any Apple links created since; leaving the column in place is harmless (see §8).

## 4. Security audit

| Topic | Status |
|-------|--------|
| Signature | RS256 verified against Apple JWKS (`https://appleid.apple.com/auth/keys`), key chosen by `kid`; `alg` comes from the JWK, not the token (no algorithm confusion) |
| Claims | `iss` = `https://appleid.apple.com`, `aud` = `APPLE_CLIENT_ID` (`com.lesgo.app`), `exp` enforced with 30 s leeway, `sub` required |
| Nonce | **Required** on sign-in, deactivate, and delete. Server compares `sha256(raw nonce)` to the token's `nonce` claim |
| Replay | Tokens are short-lived (~10 min) and nonce-bound. They are **not** single-use: the 2FA flow legitimately re-submits the same token and nonce. Nonce is client-generated, so it binds a token to one client session but is not a server-issued challenge |
| Fresh re-auth | Deactivate and delete require `iat` within 300 s |
| Key rotation | One forced JWKS refresh on verification failure, rate-limited to once per minute so bad tokens cannot hammer Apple |
| Account linking | Matches by `apple_id` first; otherwise by **verified** email, then links. An email already linked to a *different* Apple ID is rejected (401). Same policy as the existing Google flow |
| Private relay | Returning users match on `apple_id`, so relay addresses work. A first-time login with a relay address that matches no account returns 404 and tells the user to sign up |
| Login vs signup | `login` never creates accounts (default); `signup` does and then enters the existing identity-verification flow |
| 2FA / inactive | Honors existing TOTP/backup-code 2FA and `is_active = false` (403) |
| Rate limiting | Inherits `throttle:auth` |
| Data exposure | `apple_id` is in `$hidden` and absent from API responses |
| Revocation | Implemented best-effort on delete (exchange `authorization_code`, revoke refresh token). **Skipped, never blocking deletion, unless `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` are set.** Untested against Apple |
| Existing issue found | `cloud.yml` and `app.json` commit a real-looking `APP_KEY`. If that is the production key, treat it as exposed and rotate it (planned, with session/token impact in mind). I did not touch it |

## 5. Environment variables (Laravel Cloud → Environment → Variables)

| Variable | Required? | Value |
|----------|-----------|-------|
| `APPLE_CLIENT_ID` | No (defaults to `com.lesgo.app`) | iOS bundle ID. Set it only to override |
| `APPLE_TEAM_ID` | For revocation only | Apple Developer Team ID (10 chars) |
| `APPLE_KEY_ID` | For revocation only | Key ID of a "Sign in with Apple" key |
| `APPLE_PRIVATE_KEY` | For revocation only | Contents of the `.p8`, newlines written as `\n` |

Sign-in works without the last three. Add them before the iOS app goes public, since Apple expects token revocation on account deletion.

## 6. Apple credentials still needed

1. Apple Developer account owner enables **Sign in with Apple** on App ID `com.lesgo.app` (Certificates, Identifiers & Profiles).
2. Create a **Sign in with Apple key** (Keys → +). Download the `.p8` once; record the Key ID and Team ID. Per your policy I did not create or rotate any credential.
3. APNs `.p8` upload to Firebase (separate, for push).

## 7. Deployment procedure

Do these in order. Steps marked **[approval]** need your explicit go-ahead.

### Before
1. Confirm in the Laravel Cloud dashboard which **branch** the environment tracks and whether deploy hooks run `php artisan migrate --force`. The repo's `cloud.yml` says it does, `FORCE_DEPLOY.md` mentions `feature/auth`, and local git only has `main`; I could not verify the dashboard.
2. Take a database backup/snapshot (Cloud → Database → Backups) and note the current deployment ID (for rollback).
3. Merge/push the backend changes to the tracked branch **[approval]**. Files:
   - `BACKEND/lesgo-api/app/Http/Controllers/Api/Auth/AppleAuthController.php` (new)
   - `BACKEND/lesgo-api/app/Services/AppleIdentityService.php` (new)
   - `BACKEND/lesgo-api/database/migrations/2026_10_12_000001_add_apple_id_to_users_table.php` (new)
   - `BACKEND/lesgo-api/tests/Feature/AppleSignInTest.php` (new)
   - `AuthController.php`, `AccountDeletionService.php`, `User.php`, `config/services.php`, `routes/api.php` (modified)
4. Set env vars from §5 (if you have the Apple key) **[approval]**.

### Deploy
5. Trigger/allow the Cloud deployment. If migrations do not run automatically, run in the Cloud command console **[approval]**:
   ```bash
   php artisan migrate --force
   ```
   Expected output: only `2026_10_12_000001_add_apple_id_to_users_table ... DONE`.
6. Clear config cache if Cloud does not do it: `php artisan config:clear && php artisan config:cache`.

### Smoke tests (replace `$API` with the production base URL)
```bash
# 1. Route exists and rejects garbage (expect 401, JSON "Invalid Apple token")
curl -s -o /dev/null -w "%{http_code}\n" -X POST $API/api/v1/auth/apple \
  -H 'Content-Type: application/json' \
  -d '{"id_token":"x.y.z","nonce":"0123456789abcdef0123","auth_mode":"login"}'

# 2. Nonce is enforced (expect 422)
curl -s -o /dev/null -w "%{http_code}\n" -X POST $API/api/v1/auth/apple \
  -H 'Content-Type: application/json' -d '{"id_token":"x.y.z"}'

# 3. Google flow unchanged (expect 401)
curl -s -o /dev/null -w "%{http_code}\n" -X POST $API/api/v1/auth/google \
  -H 'Content-Type: application/json' -d '{"id_token":"x"}'

# 4. Email login unchanged: log in with a real test account (expect 200 + token)
# 5. Health endpoint still green
curl -s $API/api/v1/health
```
In the Cloud console confirm the column:
```bash
php artisan tinker --execute='echo \Illuminate\Support\Facades\Schema::hasColumn("users","apple_id") ? "ok" : "MISSING";'
```
Then from a TestFlight build: Sign in with Apple (existing test user by email, new signup, delete test account).

### After
7. Watch logs for `Apple token verification failed` / `Apple account creation failed` for the first hour.
8. Only then release or promote the iOS build.

## 8. Rollback

| Situation | Action |
|-----------|--------|
| Apple endpoint misbehaves, rest of app fine | Redeploy the previous deployment in Cloud. **Leave the `apple_id` column**; the old code ignores it. This is the recommended rollback |
| Need to remove the column (rarely necessary) | `php artisan migrate:rollback --step=1 --force`. Drops `apple_id` and any Apple links created since |
| Migration failed mid-way | It is idempotent (`hasColumn` guard); fix and re-run `migrate --force`. Restore the backup only if the table is damaged |
| Revocation misbehaving | Unset `APPLE_PRIVATE_KEY`; deletion continues without revocation |
| Old code deployed but column present | Safe: nothing selects `apple_id`; deletion payload is column-guarded |

Order matters in one direction only: deploying **new code before the migration** is safe for existing flows (guarded), and Apple sign-in returns a 500 with `APPLE_ACCOUNT_CREATE_FAILED` until the column exists. Deploying the **iOS app before the backend** makes the Apple button fail, so release iOS last.

## 9. Known limitations

- Nonce is client-generated (see §4 Replay).
- First-time Apple users who hide their email get a relay address; the app displays it as their email.
- Revocation is untested against Apple and depends on §5/§6 credentials.
- Apple's `authorization_code` is single-use and expires in ~5 minutes, so revocation only works at the moment of deletion (the app sends a fresh one).

---

## Addendum: merchant account deletion (same backend release)

- **No migration and no new env vars.** Changes: `AccountDeletionService` (`permanentlyDeleteMerchantOwner`, `permanentlyDeleteMerchantStaff`), `AccountPersonalDataPurger` (document-retaining purge), `AuthController::deleteAccount` (routes `partner_admin` / `partner_staff`), `PartnerController::show` ("Closed store").
- **Behavior change in production:** `POST /api/v1/auth/account/delete` previously returned 403 for merchants; it now deletes them (subject to the blocking rules). Rollback = redeploy the previous release; accounts already deleted stay anonymized (not reversible).
- **Smoke test (staging/test merchant only, never a real merchant):** owner with an active order → 422; owner with a pending payout → 422; owner with zero balance and no active orders → 200, store absent from `GET /api/v1/partners`, `GET /api/v1/partners/{id}` returns name `Closed store`, staff user still exists with no store.
- **Tests:** `tests/Feature/MerchantAccountDeletionTest.php` (11 tests).
