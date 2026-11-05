# Rider app audit (1.1.7, after build 30)

Scope: the rider side of RIDERSIDE (`com.lesgo.rider`). Method: five parallel code audits (every button checked for a real handler, an existing endpoint, correct field names, tolerant parsing, error handling), plus a Simulator pass and an API lifecycle script against a local, network-sandboxed API.

Fixes are in the working tree of `RIDERSIDE`, NOT yet committed and NOT in TestFlight (build 30 only contains the History fix).

## Results

- `flutter analyze lib`: 0 errors.
- `flutter test`: all pass except 2 golden tests in `merchant_orders_layout_test.dart` (failing before this work; font-weight differences).
- Local API lifecycle script: login, pool, `?mine=1`, accept, arrived, in progress, picked up (no pickup photo), complete needs drop-off proof, rider cancel: all pass.

## Bugs fixed

### Login / auth (12)
1. Email validator rejected `+` aliases, long TLDs, trailing space (also affected forgot password and merchant login).
2. Sign-in required password length 6; API only needs non-empty.
3. Rider field said "Email/Phone" but API accepts email only; now "Email".
4. Accounts with 2FA got "Invalid response from server" forever; code dialog added.
5. `expires_in` strict `as int` cast.
6. Staff permissions parsing threw on map / 0-1 values.
7. 429 without a JSON body showed a generic error; clear message added.
8. A 429 / offline / 5xx on token refresh logged the rider out; now only a real rejection does.
9. Restore from remember-me sent partner staff to the rider shell.
10. Forgot-password errors showed raw `DioException` text.
11. Phone OTP threw on non-JSON error bodies (spinner stuck); duty errors showed raw text.
12. Denied camera permission crashed the duty toggle.

### Bookings / order flow (7)
1. Any action error hid the whole bookings list.
2. Swipe-to-accept stayed stuck on "Accepted" after a failed accept.
3. "Fetch latest status" was a no-op while handling a status change.
4. Cancel reason had no 255 limit; controller disposed too early.
5. Navigation/call buttons: no feedback on missing coordinates or failed launch; phone number formatting.
6. Camera error in the duty toggle.
7. History kept an old error after a later successful load.
Also fixed earlier this session: blank History tab (unbounded ListView), history paging (`?mine=1`), pickup photo gate removed.

### Wallet / money (8)
Trip Analytics, Performance and Best Hour called routes that 404; payout balance never loaded (Withdraw button never showed); withdrawal dialog stuck after failure and lacked limits; wallet history could not be retried and mis-formatted string amounts; Missions load failed on string/0-1 values and hid the server reason; My Rating and `withdraw()` strict casts.

### Profile (3)
Edit Profile could blank phone and address; vehicle/plate update errors were swallowed; document submit did nothing on invalid input.

### Inbox / chat (8)
Admin Support claimed "sent" without sending (now creates a real support ticket and shows the ticket number); dev "GEMINI_API_KEY" banner shown to riders (debug only now); Retry did nothing; polling and websocket kept running after leaving a chat; realtime release bug; raw exception text; Inbox error state was a dead end; notification taps lost while a chat was open.

## Verified in the Simulator (local API)
Login (Email field), History (3 deliveries), Wallet balance, wallet history empty state, Profile, Inbox, Admin Support sending a ticket (`POST /v1/support/tickets` accepted), My Earnings.

## Not verified
- Going on duty (needs a camera; Simulator has none).
- Photo upload (S3), push notifications (FCM), GPS/navigation, real payments (PayMongo), live websocket.
- Map view, booking detail screen visuals, Missions / My Rating / Insights screens on device (verified by tests and code only).
- Anything on a real iPhone with iOS 27.2.
- Gemini AI replies (no key).

## Backend gaps (not fixable from the app)
- `POST /v1/support/tickets` returns `"id": 0` along with a valid `ticket_number` (the app now shows the ticket number).
- No `/v1/wallets/my/scheduled-payout` route; scheduled payout stays local only.
- No distance, acceptance-rate, on-time-rate or late-arrival data for analytics.
- `first_item_proof` for LesBuy manual orders is sent but never read by the backend.
- Names with `ñ` or `.` (e.g. "Jr.") are rejected by `UpdateProfileRequest`.
- Auth throttle is 10/min per IP and covers all `/v1/auth/*` calls; shared Wi-Fi can trigger 429.

## Product decisions for you
- Notification settings toggles are local only and stop no push; consider hiding the screen before App Review.
- No Help/FAQ, Terms or Privacy link on the rider Profile tab (`RiderFaqsScreen` exists but nothing opens it).
- Payout, Trip Analytics and Performance screens are unreachable from the UI.

## About "cannot log in"
No code path rejects a valid rider by role. Most likely causes: the email validator bugs above (now fixed), the 2FA dead end (fixed), the 10/min IP throttle, a wrong password, or an account that is deactivated, locked, or not yet approved. We need the exact message the tester sees.

## Addendum: second Simulator pass (local API)

Tested OK: Register (rider) terms gate (needs scroll + agree, then Continue), registration form opens; Forgot Password (Send OTP reaches API, Verify OTP screen); Login (Email field); Bookings Map view (Google Maps renders, location prompt); Earnings Insights (uses /drivers/me/earnings, no 404); Missions (empty state); My Rating (empty state); Profile; Edit Profile.

Bug found and fixed: Edit Profile always sent `name`, and the API only accepts letters, spaces, hyphens and apostrophes, so any rider whose saved name has a digit, a period ("Jr.") or an accent ("ñ") got "The name field format is invalid" and could not save phone, address or vehicle. The app now sends `name` only when it was edited. Verified: "Profile updated successfully!" and the vehicle PATCH went through. Backend recommendation: allow `\p{L}`, `.` in the name rule.

Minor UX notes (not changed): Continue on the terms screen does nothing without feedback until the terms are scrolled and accepted; a stale "Please enter your password" error stays after typing until the next submit.

Still not verifiable here: on-duty toggle (camera), photo upload, push, GPS, payments, Settings subpages (Security/Documents/Change password/Notification settings), Quick Stats, Package payment, real iPhone.
