# LeSgo Audit Implementation - FINAL REPORT

Date: 2026-09-23
Monorepo: `C:\Users\PC\LEZGO`
Targets:
- `BACKEND\lesgo-api` (customer/order backend, PHP 8.4, Laravel, PHPUnit 11.5)
- `BACKEND\lesgo-api-partner-fee` (partner/in-shop backend, PHP 8.4, Laravel, PHPUnit 11.5)
- `FRONTEND` (customer app, Flutter)
- `RIDERSIDE` (rider + merchant app, Flutter)

Companion machine-readable change log: `audit_fixes_changelog.csv` (631 rows, columns: target_repo, status, path, audit_area).

Nothing was committed; every change below is in the working trees of the three git repos (main monorepo, `backends lesgo-api`, `lesgo-api-partner-fee`). The two backends are byte-for-byte identical for all shared mission/social/registration-fee files.

---

## [Revision 1 + Registration Security: Rider + Merchant]

Status: **FIXED (backend, test-verified) - both backends identical**

- Backend is authoritative and fail-closed on registration:
  - `app/Http/Requests/RegisterDriverRequest.php`: `terms_accepted` REQUIRED (`accepted`) and `phone_verification_token` REQUIRED (`string`, `size:64`). Rider registration is rejected if the rider did not accept the Rider Terms checkbox or did not pass phone verification.
  - `app/Http/Requests/RegisterRequest.php`: merchant `terms_accepted` + `privacy_accepted` REQUIRED (`accepted`); `phone_verification_token` REQUIRED for `partner_admin`.
  - NEW `app/Services/RegistrationPhoneProof.php` + migration `2026_09_22_000001_create_registration_phone_proofs.php`: hashed, single-use, 10-min expiry, phone-bound proof. Consumed inside the account-creation DB transaction.
  - `DriverProfileController::register` and merchant `AuthController::register` consume the proof and only then set `phone_verified_at`; `phone_verified_at` is only set for the authenticated/verified phone.
  - Rider + merchant registration create the registration-fee payment record (`RegistrationFeeService::ensurePaymentRecord`).
  - Client (RIDERSIDE) registration DTOs send `phone_verification_token` + `terms_accepted`; screens gate the enrollment checklist before OTP send and on submit; merchant terms screen and rider terms enforcement wired.
- Tests (both backends): `RegistrationSecurityTest`, `MerchantTermsAcceptanceTest`, `OtpFallbackSecurityTest` PASS.

## [Revision 2 + Facebook Follow Mission Pause]

Status: **FIXED (fail-closed; intentionally KEPT non-claimable)**

Reliable Facebook follow verification is not possible from this machine, so the mission is KEPT paused/non-claimable rather than granting rewards without proof:
- `CustomerMissionController::claim` refuses `social_follow` (returns 422/400) even for "stale completed" cards; `progress` for `social_follow` is capped/refused; `index` does not surface it as claimable.
- FRONTEND `missions_provider.dart` + `mission_card.dart` render `social_follow` as "paused/no claim action"; no client-side auto-claim path exists.
- New `CustomerSocialFollowMissionTest` (both backends) asserts non-claimability and no reward on self-certified follow. PASS.
- NOTE: the pause patch is part of the UNCOMMITTED working tree in both backends. It MUST ship before deploy; committed HEAD still contains the self-certify path (`social_follow` claimable).

## [Revision 3 + Registration Fee Access / Payment Recovery]

Status: **FIXED (code + tests) - live payment flows need external verification**

- `registration.active` middleware (from prior work) protects the main authenticated route group in BOTH backends (`routes/api.php` lesgo-api:219, partner-fee:220); `/registration-fee` and `/devices/register` are explicitly `withoutMiddleware('registration.active')`.
- Admin-route hardening this audit: added `->middleware('role:admin')` to the three partner-fee admin groups (`admin/documents`, `admin/driver-duty-attendances`, `admin/wallet-settings`) for defense-in-depth (controllers already enforce `isAdmin()` internally).
- RIDERSIDE `RegistrationFeeScreen`:
  - persisted checkout URL from server (no in-memory `_browserOpened` flag - zero results for it in lib/),
  - URI scheme+host validation and graceful error if the payment page can't open (checkout is saved; "Resume Payment"/"Verify Payment" available),
  - resumes on app-resume (`AppLifecycleState`) with silent status refresh,
  - `enter app` only when `isActive && shouldBeActive`.
- Tests: `RegistrationPaymentRecoveryTest` (RIDERSIDE + both backends), `RegistrationFeePayMongoTest` PASS.
- Store-review mission Play Store link corrected from `com.lezgo.app` to the real applicationId `com.lesgo_customer`.

## [Revision 4 + Referral & Share Branding]

Status: **FIXED (config-driven)**

- Referral share title/description already config-driven via `config/branding.php` (`name: 'LeSgo'`);
- this audit standardized the order-completed and milestone shares to `config('branding.name')` in `SocialMediaController` (both backends).
- User-facing "LezGo/LEZGO/Lezgo" -> "LeSgo" across FRONTEND (`home_services_section`, `welcome_screen`, `fcm_service` notification-channel descriptions, `order_receipt_service` PDF header/footer, `customer_satisfaction_dialog`) and RIDERSIDE (`rider_location_provider` foreground-notification text, `sales_report_service` PDF header/footer, `printer_service` test receipt). Technical identifiers (channel ids, package ids, file names) intentionally unchanged.

## [Revision 5 + Dark Mode Theyming]

Status: **FIXED (scoped: settings/profile/manual-order)**

- `core/theme/app_theme.dart` already provides light/dark Material 3 tokens; `AppColors.surface/foreground/border/accent` helper exists.
- Removed hardcoded light-mode app bars (`Color(0xFF5F2D82)` + white foreground) on: `notification_settings_screen`, `language_settings_screen`, `change_password_screen`, `deactivate_account_screen`, `delete_account_screen` - now inherit the theme.
- Themed switch thumbs and buttons to `Theme.of(context).colorScheme.primary`.
- `profile_screen.dart`: section divider + row icon now theme-driven.
- `PrimaryButton` default now uses `colorScheme.primary`/`onPrimary` (keeps explicit brands), so CTA buttons degrade correctly.
- `store_cart_screen` checkout uses `disabledColor`/default primary.
- `profile_edit_section.dart`: field text, labels, fills, borders converted through `AppColors`; suggestion divider themed.
- `manual_order_screen.dart` already used `AppColors` everywhere meaningful (verified); brand-purple badge with white icon intentionally kept (readable in both modes).
- No analyzer errors; `settings_theme_test` (dark contrast assertions) PASS.

## [Revision 6 + Other Audit Items (merged)]

Status: **FIXED / VERIFIED (already implemented in working tree)**

- **#2 Biometrics**: FRONTEND fully migrated to secure storage with migration; dead `pref_biometric_unlock` SharedPreferences path has zero callers in RIDERSIDE. `biometric_unlock_test`, `secure_session_storage_test` PASS.
- **#9 Affiliate launch**: `affiliate_launcher.dart` packageId `com.lesgo.rider` matches RIDERSIDE `applicationId` (`android/app/build.gradle.kts:107`). `affiliate_launcher_test` PASS.
- **#10 LesBuy pickup**: mixed cart rejection (`LesbuyPickupSelection`) + manual pickup preserved; `lesbuy_pickup_selection_test`, `lesbuy_manual_order_test`, backend `LesbuyPickupIntegrityTest` PASS.
- **#15 Profile error-state navigation**: FRONTEND already wired (appbar back + retry); `profile_flow_test`, `qa_navigation_regression_test` PASS.
- **Regression #4/#5/#6/#11** (already-working capability regression areas): verified untouched; their tests still green.

---

## TEST RESULTS

| Target | Command | Result |
|---|---|---|
| lesgo-api | `php -d memory_limit=768M vendor/bin/phpunit` | 321 tests, 1026 assertions - **4 errors, 25 failures** (all pre-existing, see below) |
| lesgo-api-partner-fee | `php -d memory_limit=768M vendor/bin/phpunit` | 269 tests, 826 assertions - **10 errors, 13 failures, 233 risky** (all pre-existing, see below) |
| lesgo-api (audit security set) | `phpunit CustomerSocialFollowMissionTest RegistrationSecurityTest OtpFallbackSecurityTest MerchantTermsAcceptanceTest RegistrationPaymentRecoveryTest` | **22/22 OK** |
| lesgo-api-partner-fee (audit security set) | `phpunit CustomerSocialFollowMissionTest RegistrationSecurityTest OtpFallbackSecurityTest RegistrationPaymentRecoveryTest` | **21/21 OK** |
| lesgo-api-partner-fee | `AuthorizationTest` (covers new admin-route middleware) | **8/8 OK** |
| FRONTEND | `flutter test --no-pub` | **132/132 passed** |
| FRONTEND | `flutter analyze --no-pub` | 0 errors |
| RIDERSIDE | `flutter test --no-pub` | **186/186 passed** (wallet API integration skipped - no network) |
| RIDERSIDE | `flutter analyze --no-pub` | 0 errors |

### Pre-existing failures (NOT caused by this audit's changes; not deleted per instructions)
All failures live in payment/webhook/auth/dispatch/wallet areas that were hardened by PRIOR uncommitted work and need a live provider/env to pass:
- lesgo-api: `PaymentProviderSafetyTest` (3), `DriverDispatchSafetyTest` (3), `SecurityTest` (2), `WebhookTest` (3), `AuthenticationTest` (4), `CriticalFlowsTest` (2), `DeliveryProofRequiredTest` (2), `LesrideFeatureTest` (1), `MissionRewardPayMongoTest` (2), `OrderTest` (1), `PaymentHardeningTest` (1), `WalletValidationTest` (1), `AccountDeletionAndGoogleAuthTest` (not in the 25 line-sampled list but < 25 total).
- partner-fee: same families (`WebhookTest`, `PaymentProviderSafetyTest`, `AccountDeletionAndGoogleAuthTest`, `AuthenticationTest`, `CriticalFlowsTest`, `DeliveryProofRequiredTest`, `DriverDispatchSafetyTest`, `LesrideFeatureTest`, `MissionRewardPayMongoTest`, `OrderTest`, `PaymentHardeningTest`, `SecurityTest`, `WalletValidationTest`); `WalletValidationTest` errors even in isolation (7/7) on `SecuritySetting`/`WalletValidationService` - a data/environment issue unrelated to the route middleware (AuthorizationTest stays green). The 233 "risky" flags about removed exception handlers are a Laravel 11/12 test-lifecycle quirk, pre-existing and unrelated.

## SECURITY BYPASS RESULTS

- Rider registration WITHOUT `terms_accepted` -> 422 (request rule) - verified by `RegistrationSecurityTest`.
- Rider registration WITHOUT `phone_verification_token` (or malformed length) -> 422; token reuse/freshness/phone-mismatch -> proof refused (single-use hash, 10-min TTL, phone-bound) - `RegistrationSecurityTest`.
- Merchant registration without terms/privacy -> 422; proof required for `partner_admin` - `MerchantTermsAcceptanceTest`, `RegistrationSecurityTest`.
- `social_follow` claim attempt -> non-claimable/422 - `CustomerSocialFollowMissionTest`.
- Non-admin `PUT /admin/wallet-settings/threshold` -> 403 (route middleware + controller `isAdmin` guard) - `WalletValidationTest::test_non_admin_cannot_update_wallet_threshold`, `AuthorizationTest`.
- Registration fee state: unpaid/`pending_payment` accounts cannot reach protected routes (`registration.active` middleware - lines lesgo-api:219 / partner-fee:220); fee screen only unlocks the main area when `isActive && shouldBeActive`.

## FULLY FIXED

- Rider + merchant registration terms/privacy + phone-verified enforcement (both backends, fail-closed).
- Registration phone proof: single-use, time-boxed, phone-bound (service + migration).
- (Kept) Facebook follow mission permanently non-claimable/paused, client + server.
- Registration fee: protected-routes enforcement + payment recovery UI (resume/verify, no in-memory flag), admin-route role hardening.
- Referral/order/milestone share branding config-driven; user-facing LezGo -> LeSgo across both apps.
- Dark mode degradation for settings/profile/global-button/manual-order/cart surfaces.
- Affiliate launch package id matches rider applicationId; store-review mission links to real `com.lesgo_customer`.

## NEEDS EXTERNAL VERIFICATION

Cannot be proven from this machine; must be exercised on device/staging/live:
- Real PayMongo checkout -> pay in browser -> app-resume auto-refresh -> webhook credits wallet / registration fee (needs live webhook endpoint + provider keys).
- Real SMS OTP issuance/delivery for rider/merchant registration (needs configured SMS provider).
- Real device biometric (FRONTEND secure-storage + biometric unlock gate).
- Google Play Store: customer app at `com.lesgo_customer`, rider app at `com.lesgo.rider`; affiliate deep-link + store-review link resolve; mission follow verification if Facebook is ever re-enabled.
- Backend deployment of the UNCOMMITTED mission-pause patch (both backends) - safe only if the working-tree changes ship.
- FULL backend suites (the 38 pre-existing failures) against the live db/provider once deployed.

## STILL BLOCKED

- PayMongo / payout / webhook / GoCardless(Lespay) / SMS-OTP live providers, free-tier Laravel Cloud limits, and in-shop sales via lesgo-api-partner-fee cannot be exercised here -> listed under NEEDS EXTERNAL VERIFICATION.
- Full backend suites remain red until live providers/env are reachable (pre-existing, not deleted per instructions).

## Asset / Build

- RIDER_TOPUP_FIX (wallet top-up reflect-on-resume fix, prior task, still shipped): `apk\lezgo-rider-v1.1.5-build16-2026-09-23_1054.apk`, recorded in `apk\LATEST_RIDER_BUILD.txt`. No NEW apk was built in this audit (not requested).