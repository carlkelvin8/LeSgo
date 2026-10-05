# Customer flow fixes — 27 September 2026

## Implemented

- Payment callbacks select and lock the payment by provider and reference. Duplicate events are ignored, paid cannot regress to failed, and refunded is terminal. The related order's payment status is updated consistently.
- First payment confirmation publishes eligible orders through the existing OrderDispatchService. Dispatch occurs after commit and respects schedule, cancellation, assignment, manual assignment, and the auto-assignment setting. Notification errors do not roll back confirmed payments.
- Booking accepts scheduled_delivery_time; future bookings remain scheduled. Tests verify no early dispatch and a single dispatch when the scheduled-order command runs after the due time.
- Google login and sensitive account actions share server-side token verification. Configured audience, verified email, and Google subject must match; existing linked identities cannot be replaced by another subject.
- Delete/deactivate supports Google verification or the existing password verification. Wrong identities and audiences are rejected before mutation.
- The customer app retains the server-issued OTP proof, sends it on registration, and invalidates it on phone changes or resend. The backend consumes it atomically and marks phone_verified_at, allowing referral completion. Expired, mismatched and reused proofs are rejected.

## Verification

- Full customer Flutter suite: 156 passed.
- Targeted backend suite: 100 passed, 441 assertions (orders, webhooks, account deletion, Google identity, registration, 2FA and password reset).
- Analysis of changed Dart code and tests: no issues.
- Full backend suite: 339 tests; 13 failures and 2 errors remain outside these fixes. Baseline before this work: 330 tests, 20 failures and 2 errors.

Remaining full-suite failures cover legacy auth response/token expectations, the combined logout flow, SQLite's missing acos in an order test, mission payout/retry flows, payout reversal and PayMongo payout/checkout contracts, XSS test expectations, an invalid postJson test call, and driver wallet permissions. See BACKEND/lesgo-api/customer-fix-tests.txt for exact failures. These require separate diagnosis; not every failed test proves a production bug.

## Rollout and limits

Deploy BACKEND/lesgo-api and rebuild/install FRONTEND. Keep queue workers and the existing orders:process-scheduled scheduler running. No schema migration was introduced by these fixes; registration_phone_proofs must already exist (it is used by existing partner registration).

Tests used local databases and mocked provider responses. Live Google/device and payment-provider sandbox verification, production deployment, and APK installation were not performed. Existing customer phone verification is not backfilled: accounts without a valid server proof remain unverified. Older clients can still register without a proof, but will not be marked phone-verified.
