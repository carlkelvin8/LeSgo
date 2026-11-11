---
name: ship-testflight
description: Bump the rider app build number, build the iOS IPA, export it, upload to App Store Connect/TestFlight and optionally add it to the external group. Use when the user says "upload to testflight", "new build", or "ship build N".
---

# Ship a rider build to TestFlight

Run from `RIDERSIDE/`. Ask before step 5 (it submits the build to Apple Beta App Review).

1. **Pre-flight**: `flutter analyze` has no errors; `flutter test` (only the known 401 test may fail); `git status` clean for `lib/`.
2. **Bump** `version: 1.1.7+N` to `+N+1` in `pubspec.yaml`; commit `chore(rider): build N+1` with the Co-Authored-By line.
3. **Build**: `mkdir -p "$(readlink build)"` then `flutter build ipa --release`. It always ends with
   `requires a provisioning profile with the Push Notifications feature`; that is expected, the archive at
   `build/ios/archive/Runner.xcarchive` is still produced. Run it in the background (about 2-3 min) and wait for it to finish.
4. **Export + upload** (team `4L5ZY884RB`, API key `Z346X95BXU`, issuer `c83c8489-37ab-49af-a0e6-5d1c09aa5f32`, key file in `~/.appstoreconnect/private_keys`):
   ```bash
   xcodebuild -exportArchive -archivePath build/ios/archive/Runner.xcarchive \
     -exportOptionsPlist <ExportOptions.plist: method app-store-connect, teamID 4L5ZY884RB, destination export> \
     -exportPath build/ios/ipaN -allowProvisioningUpdates
   xcrun altool --upload-app --type ios -f "build/ios/ipaN/LeSgo Affiliates.ipa" --apiKey Z346X95BXU --apiIssuer c83c8489-37ab-49af-a0e6-5d1c09aa5f32
   ```
   "UPLOAD SUCCEEDED" is the success line (a transient `-19241` server error that then succeeds is fine).
   Never `pkill -f "flutter build ipa"` from a shell whose own command line contains that text; it kills itself.
5. **Add to external testers** (only with the user's OK): App Store Connect -> TestFlight -> build N -> Groups `+` ->
   External "LeSgo Affiliates Testers" -> Next -> fill "What to Test" -> Submit for Review. The build must be out of
   "Processing" first (10-30 min). Internal testers get it automatically.
6. `git push origin <current branch>` (existing branch only). Report: build number, delivery UUID, what is in the build,
   and what is NOT verified on a device.
