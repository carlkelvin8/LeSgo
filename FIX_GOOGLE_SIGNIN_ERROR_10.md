# Fix: Google Sign-In "ApiException: 10" (DEVELOPER_ERROR)

## ✅ Magandang balita
Ang error na `ApiException: 10` ay nangangahulugang **TAMA NA ang code at config**. Wala nang "not configured" error. Nakalampas na sa lahat ng code checks.

## ❌ Ano ang kulang
Kailangan i-register ang Android app sa **Google Cloud Console**. Chine-check ni Google ang package name + app signature (SHA-1). Kapag walang match, `ApiException: 10` ang lalabas.

**Hindi ito pwedeng ayusin sa code** — required ang console setup para sa Google native sign-in.

---

## 🔧 SOLUSYON (5 minutes sa Google Cloud Console)

### Kailangan mong i-register (2 values lang):
| Field | Value |
|-------|-------|
| **Package name** | `com.lesgo_customer` |
| **SHA-1 (Debug/testing)** | `0C:D4:C1:53:68:73:C5:EB:8F:32:98:3D:AF:B7:8A:E9:BC:C6:3A:2F` |
| **SHA-1 (Release/production)** | `E1:08:3F:68:C5:50:8B:C7:17:D5:E0:63:84:4E:ED:F0:52:1E:69:83` |

> 💡 **I-add mo pareho** ang debug at release SHA-1 (pwede sa iisang Android OAuth client, o gumawa ng dalawa). Ganito, gagana sa emulator/testing AT sa release APK na ipapamigay.

**SHA-256 (Release)** — kung kailanganin ng ibang setup:
`93:0F:07:1E:E1:4F:6A:2A:F4:B8:1D:C9:E9:C0:9D:B6:4E:EB:69:8C:19:BD:81:D1:B5:08:E6:44:94:1F:CD:DE`

### Steps:

1. Pumunta sa https://console.cloud.google.com
2. Piliin ang project (yung parehong project ng Web Client ID: `410330550746-...`)
3. **APIs & Services** → **Credentials**
4. Click **+ Create Credentials** → **OAuth client ID**
5. Application type: **Android**
6. Name: `LesGo Android Customer`
7. **Package name**: `com.lesgo_customer`
8. **SHA-1 certificate fingerprint**: `0C:D4:C1:53:68:73:C5:EB:8F:32:98:3D:AF:B7:8A:E9:BC:C6:3A:2F`
9. Click **Create**

### Tapos din i-check:
- **OAuth Consent Screen** dapat naka-setup (External + naka-add ang test email mo, o Published)

---

## ⏱️ Importante
Pagkatapos i-create ang Android OAuth client, **maghintay ng 5 minutes** (minsan hanggang 1 hour) bago mag-propagate ang changes ni Google. Tapos i-restart ang app at subukan ulit.

---

## 📝 SHA-1 Fingerprints (para sa reference)

### Debug Key (testing/emulator)
`0C:D4:C1:53:68:73:C5:EB:8F:32:98:3D:AF:B7:8A:E9:BC:C6:3A:2F`

Kunin ulit:
```
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### Release Key (production APK/AAB)
`E1:08:3F:68:C5:50:8B:C7:17:D5:E0:63:84:4E:ED:F0:52:1E:69:83`

Kunin ulit:
```
keytool -list -v -keystore "FRONTEND\android\lesgo-customer-release.jks" -alias lesgo-customer -storepass "<from FRONTEND/android/key.properties - never commit it>"
```

⚠️ **I-add ang PAREHONG SHA-1** (debug + release) sa Google Cloud Console para gumana sa testing AT production.

---

## ✅ Checklist para gumana ang Google Sign-In

- [x] Web Client ID sa `secrets.json` — TAPOS
- [x] Web Client ID sa backend `.env` — TAPOS
- [x] Web Client ID sa `google-services.json` — TAPOS
- [x] App na-build with `--dart-define-from-file=secrets.json` — TAPOS
- [ ] **Android OAuth Client (package + SHA-1) sa Google Cloud Console** ← KAILANGAN MO GAWIN
- [ ] OAuth Consent Screen naka-setup ← I-verify

---

## Summary (para sa client)

> Ang Google Sign-In code ay 100% tapos na. Ang natitira lang ay i-register ang Android app sa Google Cloud Console gamit ang:
> - **Package**: `com.lesgo_customer`
> - **SHA-1 (Debug)**: `0C:D4:C1:53:68:73:C5:EB:8F:32:98:3D:AF:B7:8A:E9:BC:C6:3A:2F`
> - **SHA-1 (Release)**: `E1:08:3F:68:C5:50:8B:C7:17:D5:E0:63:84:4E:ED:F0:52:1E:69:83`
>
> I-add ang parehong SHA-1. Isang beses lang gagawin. Pagkatapos, gagana na ang Google Sign-Up at Sign-In sa testing at production. Free at walang code changes na kailangan.
