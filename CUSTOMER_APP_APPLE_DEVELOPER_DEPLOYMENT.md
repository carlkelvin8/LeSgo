# LeSgo Customer App — Apple Developer Account Deployment (iOS)

App: `FRONTEND/` (Flutter, name `lesgo`, display name **Lesgo**)
Current version: `1.1.8+24` (from `FRONTEND/pubspec.yaml`)
Target: App Store Connect → TestFlight → App Store

---

## 0. Blockers found in the repo

**Status (applied in `FRONTEND/ios/`):** 1, 2, 3, 4, 5 (config side) and 8 are done. Still open: the Firebase plist re-download (5), Sign in with Apple (6) and account deletion (7). Also open: `GOOGLE_APP_ID` in `GoogleService-Info.plist` (`...ios:64b325eaf4541ac6a18fe6`) differs from `lib/firebase_options.dart` (`...ios:aeeb640407f03bcba18fe6`). Confirm which is registered for `com.lesgo.app` in Firebase.

Local setup: copy `ios/Flutter/Secrets.xcconfig.example` to `Secrets.xcconfig` and fill `APPLE_TEAM_ID`, `GOOGLE_MAPS_API_KEY`, `GOOGLE_REVERSED_CLIENT_ID`.

| # | Issue | Where | Fix |
|---|-------|-------|-----|
| 1 | Xcode bundle ID is `com.example.lesgo`, but Firebase iOS app is registered as `com.lesgo.app`. Apple rejects `com.example.*` and Firebase will not match. | `ios/Runner.xcodeproj/project.pbxproj` (`PRODUCT_BUNDLE_IDENTIFIER`), `lib/firebase_options.dart:66`, `ios/Runner/GoogleService-Info.plist` | Set Runner to `com.lesgo.app` (RunnerTests → `com.lesgo.app.RunnerTests`). |
| 2 | No signing team set; only `CODE_SIGN_STYLE = Automatic`. | Xcode → Runner → Signing & Capabilities | Select the customer's Apple Developer Team. |
| 3 | `IPHONEOS_DEPLOYMENT_TARGET = 12.0`; `firebase_messaging ^16` / current Firebase pods need a newer iOS (15+). | `project.pbxproj`, `ios/Podfile` | Raise to iOS 15.0 and run `pod install --repo-update`. |
| 4 | No push-notification entitlement (`Runner.entitlements` missing) although the app uses `firebase_messaging`. | `ios/Runner/` | Add Push Notifications + Background Modes (Remote notifications) capabilities. |
| 5 | Google Sign-In on iOS needs `REVERSED_CLIENT_ID` in `GoogleService-Info.plist` and a matching `CFBundleURLTypes` entry in `Info.plist`; neither is present. | `GoogleService-Info.plist`, `Info.plist` | Re-download plist from Firebase after enabling Google provider; add URL scheme. |
| 6 | App Store guideline 4.8: apps offering Google login must also offer an equivalent privacy-preserving login (Sign in with Apple). | `lib/` auth flow | Add Sign in with Apple, or confirm another compliant option. |
| 7 | Account deletion in-app is mandatory (guideline 5.1.1(v)) since the app creates accounts. | Profile / settings | Confirm a delete-account flow exists. |
| 8 | Location "Always" string is declared but the app only needs when-in-use. Reviewers question unused "Always" permission. | `Info.plist` `NSLocationAlwaysUsageDescription` | Remove unless background location is truly used. |

---

## 1. Apple Developer account prerequisites (customer side)

1. Enroll at <https://developer.apple.com/programs/enroll/> (USD 99/yr).
   - Individual: instant-ish. Organization: needs a D-U-N-S number and legal entity verification (days to weeks).
   - The seller name shown on the App Store is the account's legal name.
2. Account Holder invites the developer: **App Store Connect → Users and Access → Invite**, role **App Manager** (or Admin) + **Access to Certificates, Identifiers & Profiles**.
3. Accept the **Paid Applications Agreement** (Agreements, Tax, and Banking) if the app will ever take Apple IAP. Physical goods/services (food, rides, delivery) use external payment and do not need IAP.
4. Enable two-factor authentication on every Apple ID involved.

---

## 2. Create the identifiers and app record

### App ID
Developer portal → Certificates, Identifiers & Profiles → Identifiers → **+** → App IDs → App
- Bundle ID (Explicit): `com.lesgo.app`
- Capabilities: Push Notifications, Sign in with Apple, Associated Domains (only if deep links are used)

### APNs key (for Firebase Cloud Messaging)
Keys → **+** → Apple Push Notifications service (APNs) → download `.p8` (one-time download).
Upload in Firebase Console → Project settings → Cloud Messaging → Apple app configuration → APNs Authentication Key (Key ID + Team ID).

### App Store Connect record
App Store Connect → Apps → **+** → New App
- Platform: iOS
- Name: `LeSgo` (must be unique store-wide; have a fallback)
- Primary language: English
- Bundle ID: `com.lesgo.app`
- SKU: `lesgo-customer-ios`

---

## 3. Project configuration (local Mac)

```bash
cd FRONTEND
flutter clean && flutter pub get
open ios/Runner.xcworkspace
```

In Xcode, select **Runner** target:
1. General → Display Name `Lesgo`, Bundle Identifier `com.lesgo.app`, Minimum Deployments `15.0`.
2. Signing & Capabilities → Automatically manage signing ✔, Team = customer's team.
3. Add capabilities: **Push Notifications**, **Background Modes → Remote notifications**, **Sign in with Apple**.
4. Confirm `GoogleService-Info.plist` is in the Runner target and its `BUNDLE_ID` is `com.lesgo.app`.
5. Info.plist → add the Google URL scheme:
   ```xml
   <key>CFBundleURLTypes</key>
   <array><dict>
     <key>CFBundleURLSchemes</key>
     <array><string>REVERSED_CLIENT_ID_FROM_PLIST</string></array>
   </dict></array>
   ```
6. App icon: `ios/Runner/Assets.xcassets/AppIcon.appiconset` must include the 1024×1024 marketing icon with **no alpha channel**.

Then:
```bash
cd ios && pod install --repo-update && cd ..
```

---

## 4. Build and upload

Bump the build number for every upload (`+24` → `+25`; the version `1.1.8` can stay for TestFlight iterations).

```bash
cd FRONTEND
flutter build ipa --release --obfuscate --split-debug-info=build/symbols \
  --build-name=1.1.8 --build-number=25
# Output: build/ios/ipa/*.ipa
```

Upload with any one of:
- **Transporter** app (drag the `.ipa`), or
- ```bash
  xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa \
    --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
  ```
  (App Store Connect → Users and Access → Integrations → App Store Connect API)
- Xcode → Product → Archive → Distribute App → App Store Connect.

Keep `build/symbols` — it is required to de-obfuscate crash reports.

---

## 5. TestFlight

1. App Store Connect → TestFlight → wait for processing (10–30 min) → answer export-compliance (the app uses only standard HTTPS: "No" for proprietary encryption; add `ITSAppUsesNonExemptEncryption = false` to Info.plist to skip the prompt).
2. Internal testers: add users (up to 100), no review needed.
3. External testers: create a group, add the build, fill Beta App Information (a **demo account** is required if login is needed). First external build goes through Beta App Review (~1 day).

Smoke test on a real device: signup/login (email, Google, Apple), push notification receipt, location prompt, camera/selfie KYC, all five services (LesRide, LesEat, LesBuy, LesGo, LesPay), order tracking, chat, logout.

---

## 6. App Store listing (required metadata)

| Field | Value / notes |
|-------|---------------|
| Subtitle | ≤30 chars |
| Description, keywords | ≤4000 / ≤100 chars |
| Support URL | Required, live page |
| Privacy Policy URL | Required, live page |
| Category | Food & Drink (primary), Travel or Shopping (secondary) |
| Age rating | Complete questionnaire |
| Screenshots | 6.9" (1320×2868) required; 6.5" and iPad only if iPad is supported |
| App Review notes | Demo customer credentials, how to trigger an order, note that rider/merchant are separate apps |
| App Privacy ("nutrition labels") | Declare: contact info, location (precise), identifiers, photos/ID (KYC), purchases/financial info, usage data |

**Permission strings** in `Info.plist` already exist for camera, photo library, location, and Face ID. Make sure each is specific and truthful (reviewers compare them to behavior).

---

## 7. Submit for review and release

1. Select the processed build in the version page → **Add for Review**.
2. Choose release mode: manual / automatic / phased (recommended: phased for first public release).
3. Typical review: 24–48 h. Common rejections for this app type: 4.8 (Sign in with Apple), 5.1.1 (account deletion, privacy policy), 2.1 (crashes / missing demo account), 5.1.2 (KYC data use not disclosed).

---

## 8. Post-release

- Monitor Crashes in Xcode Organizer and Firebase Crashlytics (upload dSYMs from `build/ios/archive/*.xcarchive/dSYMs`).
- Update backend CORS / API allowlists if any iOS-specific user agent filtering exists.
- Next release: bump `pubspec.yaml` version, repeat sections 4–7.

---

## Quick checklist

- [ ] Customer enrolled and paid; developer invited
- [ ] Bundle ID unified to `com.lesgo.app` (Xcode, Firebase, App Store Connect)
- [ ] Deployment target ≥ 15.0, `pod install` clean
- [ ] Push + Sign in with Apple + Background Modes capabilities added
- [ ] APNs `.p8` uploaded to Firebase
- [ ] `REVERSED_CLIENT_ID` URL scheme added
- [ ] Account deletion + privacy policy URL verified
- [ ] `flutter build ipa` succeeds, build number incremented
- [ ] Build uploaded, TestFlight smoke test passed
- [ ] Metadata, screenshots, privacy labels, demo account completed
- [ ] Submitted for review

---

## Addendum: Sign in with Apple (implemented, needs backend deploy)

- App: `lib/core/services/apple_auth_service.dart`, `lib/core/utils/apple_auth_helper.dart`, `lib/presentation/widgets/auth/apple_auth_button.dart` (iOS only; shown on login and all signup entry points). Delete-account re-verification offers Apple or Google on iOS.
- Backend: `POST /api/v1/auth/apple` (`AppleAuthController`, `AppleIdentityService`), migration `2026_10_12_000001_add_apple_id_to_users_table.php`, `APPLE_CLIENT_ID` (defaults to `com.lesgo.app`). Run `php artisan migrate` and deploy **before** submitting the iOS build.
- Apple portal: enable **Sign in with Apple** on the `com.lesgo.app` App ID before archiving (the entitlement is already in `Runner.entitlements`).
- Not yet done: Apple token revocation on account deletion (needs a Sign in with Apple private key).
