# AppStore.md — iOS App Store Release Checklist

**Target:** App Store (iPhone + iPad) via Codemagic CI/CD.  
**Bundle ID:** `com.yk.ledgerly` (unified across Debug, Profile, and Release).  
**Version:** Dynamic from `pubspec.yaml` (build number auto-incremented by Codemagic).  
**Policies verified:** Apple App Store Review Guidelines, iOS 26 SDK requirement (mandatory April 28 2026), iOS 13 minimum (mandatory September 9 2026).

Legend: ☐ todo · ☑ done · ⚠️ owner action required

---

## Part 1 — Code changes (configured in repo)

- ☑ **`ios/Runner/PrivacyInfo.xcprivacy`** — Privacy manifest (mandatory since spring 2024).
  - Wired into `ios/Runner.xcodeproj/project.pbxproj` (`PBXResourcesBuildPhase`, `PBXBuildFile`, `PBXFileReference`, `Runner` group) so it is copied into the `Runner.app/` root.
  - `NSPrivacyTracking: false` — no cross-app tracking.
  - `NSPrivacyCollectedDataTypes: []` — no data collected or sent off-device.
  - Required-reason APIs: `FileTimestamp` (DDA9.1), `UserDefaults` (CA92.1), `DiskSpace` (E174.1).
- ☑ **Entitlements file omitted** — Standard iOS apps without extra capabilities need no `.entitlements` file. Ledgerly v1.0 is 100% local-first: no remote push (`aps-environment`), no iCloud, no App Groups, and no third-party social logins (SIWA not required under Guideline 4.8). Omitting the file prevents code-signing mismatch errors when the provisioning profile has no special capabilities enabled. (Phase 4 will add `Runner.entitlements` when Supabase / SIWA is integrated.)
- ☑ **`ios/Runner/Info.plist`** — Updated:
  - `CFBundleName` → `Ledgerly`.
  - `CFBundleDisplayName` → `Ledgerly`.
  - `CFBundleLocalizations` → `[en, my, ja]`.
  - `ITSAppUsesNonExemptEncryption: false` — exempt from US export compliance (no proprietary encryption).
  - Removed `UIUserInterfaceStyle` — app fully supports both light and dark modes.
  - ProMotion / 120 Hz enabled (`CADisableMinimumFrameDurationOnPhone: true`).
- ☑ **`ios/ExportOptions.plist`** — Export options for `flutter build ipa`. Method: `app-store`. Team ID configured: `29T87PGHWL`.
- ☑ **`codemagic.yaml`** — Two automated workflows:
  - `ios-test`: Triggers on PRs and `feature/*` branches. Runs `flutter pub get`, Drift codegen, `flutter gen-l10n`, `flutter analyze --fatal-infos`, and `flutter test --coverage`.
  - `ios-release`: Triggers on push to `dev`, `main`, and `prod`. Runs tests, configures signing via `xcode-project use-profiles`, auto-increments build number via `app-store-connect get-latest-app-store-build-number` using App ID `6823720064` and API integration `Ye Khaung`, builds release IPA, and publishes to TestFlight.
- ☑ **`ios/Runner.xcodeproj/project.pbxproj`** — Configured:
  - `PRODUCT_BUNDLE_IDENTIFIER` set to `com.yk.ledgerly` for Runner (Debug, Profile, Release) and `com.yk.ledgerly.RunnerTests`.
  - `DEVELOPMENT_TEAM` and `TargetAttributes.DevelopmentTeam` set to `29T87PGHWL`.
  - `PrivacyInfo.xcprivacy` registered in the project hierarchy and bundled into `PBXResourcesBuildPhase`.

---

## Part 2 — Apple Developer Portal ⚠️ Owner required

### 2.1 App ID & capabilities
- ☐ Register App ID `com.yk.ledgerly` in **Certificates, IDs & Profiles**.
  - No extra capabilities required for v1.0 (local-only app).
- ☐ Create a **Distribution Certificate** (Apple Distribution / iPhone Distribution).
- ☐ Create an **App Store Provisioning Profile** for `com.yk.ledgerly`.

### 2.2 App Store Connect — Create the app record
- ☑ **My Apps → New App**: Platform iOS, Bundle ID `com.yk.ledgerly`, Primary language English.
- ☑ Numeric Apple ID: `6823720064` (configured in `codemagic.yaml` `APP_STORE_APPLE_ID`).
- ☑ Apple Developer Team ID: `29T87PGHWL` (configured in `ios/ExportOptions.plist` & `project.pbxproj`).

### 2.3 App Store Connect API Key (for Codemagic)
- ☐ **Users and Access → Integrations → App Store Connect API → Generate API Key** (role: App Manager or Admin).
- ☐ Download the `.p8` file (one-time download).
- ☐ In Codemagic UI → Integrations → App Store Connect: enter Key ID, Issuer ID, `.p8` content. Name it `codemagic`.

### 2.4 Codemagic iOS signing
- ☐ Codemagic UI → Settings / Environment groups → configure App Store code signing with the created certificate and profile.

---

## Part 3 — App Store metadata ⚠️ Owner required

### 3.1 App Information
- ☐ **Name:** Ledgerly — Budget & Finance Tracker *(max 30 chars)*
- ☐ **Subtitle:** Personal Budget Manager *(max 30 chars)*
- ☐ **Primary category:** Finance · **Secondary:** Productivity
- ☐ **Content rights:** No third-party content. Confirm in App Store Connect.

### 3.2 Age rating (new system, mandatory January 2026)
All questions → **None / No**. Expected rating: **4+**.

| Question | Answer |
|---|---|
| Violence, sexual content, mature themes | None |
| User-generated content | None (data is private, local-only) |
| Unrestricted web access | No |
| Gambling / contests | No |

### 3.3 Privacy — App Privacy "Nutrition Labels"
Ledgerly collects **no data**. Every category: **Not collected**.
- ☐ Data Linked to You: Not collected
- ☐ Data Used to Track You: Not collected
- ☐ Data Not Linked to You: Not collected

Rationale: all data stays on-device in SQLite (Drift). `PrivacyInfo.xcprivacy` confirms at OS level.

### 3.4 Privacy Policy URL
- ☐ Host a Privacy Policy page and link it in App Store Connect.
  - Required sections: what data is stored (on-device only), no third-party sharing, account deletion, contact email.
  - **Account deletion:** "Settings → Delete Account clears all local data." Also link from Privacy Policy.

### 3.5 Description & keywords
- ☐ **Description** (max 4000 chars): Local-first, works offline, no subscription. Cover: budget tracking, transactions, categories, goals, recurring, CSV/JSON import-export, MMK/JPY/USD, calendar view.
- ☐ **Promotional text** (max 170 chars): e.g. `Track spending across MMK, JPY and USD — fully offline, no subscription.`
- ☐ **Keywords** (max 100 chars): `budget,finance,money,expense,tracker,မြန်မာ,家計,ledger,savings,goals`

### 3.6 Screenshots (required)
| Device | Size | Status |
|---|---|---|
| iPhone 6.9" (iPhone 16 Pro Max) | 1320×2868 | ☐ Required |
| iPad Pro 13" (M4) | 2064×2752 | ☐ Required if iPad supported |

Minimum 5 screenshots per device. Recommended screens: Calendar, Transactions, Budgets, Goals, Insights.

---

## Part 4 — 2026 Apple Policy Compliance Verification

### 4.1 Bundle ID alignment ✅
`ios/Runner.xcodeproj/project.pbxproj` and `codemagic.yaml` both use `com.yk.ledgerly`. Verified.

### 4.2 SDK requirement ✅
`codemagic.yaml` uses `xcode: latest` (Xcode 26 / iOS 26 SDK). Mandatory since April 28, 2026. ✅  
`IPHONEOS_DEPLOYMENT_TARGET = 13.0` satisfies iOS 13+ minimum requirement. ✅

### 4.3 Privacy manifest ✅
`PrivacyInfo.xcprivacy` is registered in `project.pbxproj` (`PBXResourcesBuildPhase`). Xcode bundles it into `Runner.app/PrivacyInfo.xcprivacy`. Required reasons for `FileTimestamp` (DDA9.1), `UserDefaults` (CA92.1), and `DiskSpace` (E174.1) are declared. ✅

### 4.4 Entitlements ✅
No special capabilities declared in v1.0. No `.entitlements` file required. Code signing will succeed without provisioning profile capability mismatches. ✅

### 4.5 Sign in with Apple
Ledgerly v1.0 has **no third-party login** (uses a local mock auth) → SIWA is **not mandatory** for v1.0 (App Store Review Guideline 4.8). If Phase 4 adds Google or other third-party social login, SIWA will be added alongside it.

### 4.6 In-app data reset / deletion
Settings provides full local database reset. Meets Apple's account deletion / data removal guideline for local-first apps. ✅

### 4.7 Encryption exemption ✅
`ITSAppUsesNonExemptEncryption = false` declared in `Info.plist`. The app uses only OS-level SQLite and HTTPS; no proprietary cryptography. Exempt from US export compliance documentation (no ERN needed). ✅

### 4.8 Zero tracking / No ATT ✅
No advertising SDKs or tracking frameworks. `AppTrackingTransparency` is not linked. ✅

---

## Part 5 — Codemagic first-run checklist

1. ☐ Connect repository to Codemagic.
2. ☐ Add App Store Connect API Key integration named `codemagic` (or set `appstore_credentials` env group).
3. ☑ `APP_STORE_APPLE_ID` configured in `codemagic.yaml` (`6823720064`).
4. ☑ `teamID` configured in `ios/ExportOptions.plist` (`29T87PGHWL`).
5. ☐ Push to `dev` → verify `ios-test` workflow passes `analyze` and `test`.
6. ☐ Push/merge to `main` → verify `ios-release` builds the `.ipa` and uploads to TestFlight.
7. ☐ In TestFlight, invite internal testers and verify build on real hardware.
8. ☐ Complete metadata in App Store Connect and submit for App Review.

---

## Part 6 — After first approval

- ☐ Flip `submit_to_app_store: true` in `codemagic.yaml` if automatic submission is desired for subsequent releases.
- ☐ Update `docs/Roadmap.md` to record completion of App Store distribution readiness.
- ☐ Monitor crash reports and feedback in TestFlight / App Store Connect.
