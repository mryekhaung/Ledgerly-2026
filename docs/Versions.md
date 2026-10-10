# Versions.md — Toolchain & Dependency Baseline

**Last checked: 10 Oct 2026** (web search of pub.dev / Flutter blog). Versions move fast — this file is the single source of truth. When you add or upgrade a package: run `flutter pub add <pkg>` (resolves the latest compatible), then **update the table** and commit `pubspec.lock`.

> ## ⚠️ Phase 0 status — READ THIS FIRST
>
> **The development machine in this session cannot run `flutter`.** Every invocation of the
> Flutter tool dies with
> `ProcessException: All pipe instances are busy (at ../../runtime/bin/process_win.cc:742)`
> — it cannot spawn *any* child process (`git`, `cmd`, `where`, `adb` all fail the same way).
> Consequences for local work only:
>
> - `flutter create`, `flutter pub get`, `flutter pub add`, `flutter analyze`, `flutter test`
>   and `flutter gen-l10n` cannot be run **on this machine**.
> - The installed SDK here is **Flutter 3.38.2 / Dart 3.12.2**, older than the 3.47.1 / 3.13.1
>   this project targets. `material_ui` / `cupertino_ui` do not resolve on 3.38.2.
> - A standalone **Dart 3.13.5 SDK** *is* usable here (installed at
>   `~/.workbuddy-ai/binaries/dart/versions/3.13.5/dart-sdk/bin/dart.exe`), which is enough for
>   `dart format` and `dart analyze` once packages resolve. `dart pub get` alone cannot resolve
>   Flutter SDK dependencies, so a full local analyze still requires CI.
>
> **CI is the verification channel.** GitHub Actions runs on Flutter 3.47.1 / Dart 3.13.1 and
> *does* execute `pub get`, `analyze` and `test` successfully. `docs/Versions.md` §3 is therefore
> populated from **CI-resolved versions**, not from local runs.
>
> **On a working machine:** install FVM, `fvm use 3.47.1`, then `fvm flutter pub get`. Commit
> `pubspec.lock` — it is not generated here.

## 1. Toolchain
| Item | Baseline | Status |
|---|---|---|
| Flutter | **3.47.1** (stable, 19 Aug 2026) | 📌 pinned in `.fvmrc` — ⚠ **not installed on this machine** (3.38.2 present) |
| Dart | **3.13.1** | 📌 enforced by `pubspec.yaml` `sdk: ^3.13.0` — ⚠ **not installed** (3.12.2 present) |
| Pin with | **FVM** (`.fvmrc` = `3.47.1`), CI uses the same version | ✅ `.fvmrc` created · CI uses `FLUTTER_VERSION: 3.47.1` |
| `pubspec.yaml` | `environment: sdk: ^3.13.0` · `flutter: ">=3.47.0"` | ✅ applied |
| iOS | Xcode with iOS 26 SDK (Liquid Glass on rebuild); Flutter 3.47 raised min iOS (reported 15) — check `Platform.md`/release notes. UIScene lifecycle + Swift Package Manager are the default direction | ⚠ confirm in release notes |
| Android | AGP 9 supported since 3.41; set `targetSdk` per current Play requirement; check 16 KB page-size compliance for native libs | ⚠ confirm at release time. Flavors `dev`/`prod` configured in `android/app/build.gradle.kts`; app label now reads `@string/app_name` |
| Web | Wasm build: `flutter build web --release --wasm` (Wasm deferred loading is experimental); use `package:web`, never `dart:html` | ✅ per 3.47 notes |


## 2. What changed in Flutter 3.47 that affects us
1. **Material and Cupertino are now standalone packages: `material_ui` and `cupertino_ui` (1.0).** They release independently (weekly), so Liquid Glass / M3 Expressive updates can land without a Flutter SDK upgrade. Localization delegates moved into those packages.
   - **New project rule:** import `package:material_ui/…` and `package:cupertino_ui/…`, **not** `package:flutter/material.dart` / `cupertino.dart` (old imports still work for now, but are the legacy path). Run `dart fix --apply` to migrate if any template code uses the old imports.
2. Impeller is now default on desktop too; Widget Previews are stable (use them for design-system components).
3. Dart 3.13 adds abbreviated constructor syntax (`new()`); Dart 3.10+ has dot shorthands. **Optional** — don't mix styles; decide once in `Conventions.md` before adopting.

## 3. Dependencies
### Verified in this session
| Package | Baseline | Notes |
|---|---|---|
| `flutter_riverpod` | **^3.4.1** (26 Jul 2026) | Riverpod **3.x**: see §4 |
| `drift` | **^2.35.0** (needs Dart ≥ 3.10) | with `drift_dev` (same minor) and **`drift_flutter` ^0.3.1** |
| `go_router` | **^17.x** (17.0.0 confirmed; resolve latest 17.x+) | breaks APIs between majors — read changelog; keep `go_router_builder` on matching major |
| `freezed` / `freezed_annotation` | **freezed 3.2.5** (Feb 2026; may be newer) | 3.x syntax: classes are `sealed`/`abstract` with mixin; **don't use 4.0 dev prerelease**. Pair with `build_runner`, `json_serializable` |
| `material_ui`, `cupertino_ui` | **1.0** | see §2 |
| `cupertino_native_better` | **^1.3.8** (community) | native iOS 26 Liquid Glass widgets via platform views — see `Platform.md` §4 |
| `liquid_glass_renderer` | **0.2.0-dev.4** (prerelease, **experimental**) | needs Impeller; heavy on GPU — **not a default dependency** |

### Not verified yet — resolve with `flutter pub add`, then record here
`get_it`, `dio`, `pretty_dio_logger`, `fl_chart`, `intl`, `flutter_svg`, `dynamic_color`, `file_picker`, `share_plus`, `csv`, `path_provider`, `shared_preferences`, `flutter_secure_storage`, `local_auth`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`, `sign_in_with_apple`, `mocktail`, `leak_tracker`, `very_good_analysis`/`flutter_lints`.
For each: confirm **iOS + Android + web** support (or wrap behind an interface with a stub), maintenance in the last 12 months, license, and Wasm compatibility (no `dart:html`/`dart:js`).

### Phase 0 dependencies — **resolved and pinned (10 Oct 2026)**

These are **real resolved versions**, taken from CI (`flutter pub get` on Flutter 3.47.1 /
Dart 3.13.1, GitHub Actions run `38047092523`). `pubspec.yaml` now carries the caret
constraints below rather than `any`.

| Package | Resolved | Pinned as | Role |
|---|---|---|---|
| `material_ui` | **1.6.0** | `^1.6.0` | Material 3 widgets — replaces `package:flutter/material.dart` |
| `cupertino_ui` | **1.1.2** | `^1.1.2` | Cupertino widgets — replaces `package:flutter/cupertino.dart`; also supplies `CupertinoPageTransitionsBuilder` |
| `flutter_riverpod` | **3.4.3** | `^3.4.3` | Presentation state (Riverpod 3 — see §4) |
| `go_router` | **17.5.0** | `^17.5.0` | Routing |
| `get_it` | **9.3.0** | `^9.3.0` | DI for data/domain |
| `intl` | **0.20.3** | `^0.20.3` | Date/number formatting |
| `flutter_lints` | template default | `^6.0.0` | Dev dependency |

Gotcha worth recording: **`cupertino_ui` re-exports `package:flutter/widgets.dart`**, and both
`material_ui` and `cupertino_ui` export `dart:ui`'s text primitives transitively (via
`flutter/painting` → `basic_types.dart`). That means `FontFeature`, `FontWeight`, `Color`,
`Offset`, etc. are available from `package:material_ui/material_ui.dart` alone — an explicit
`import 'dart:ui'` is flagged `unnecessary_import`. Do **not** add one.

`drift`, `freezed`, `dio` and the rest of §3 are **deliberately not declared yet** — they belong
to the roadmap items that use them, and adding them here would put an unused dependency in
the build for no reason. Add each one in the PR that first needs it (`Agent.md` §3.14).


## 4. Riverpod 3 rules (we start on 3.x, never 2.x)
- `StateProvider` / `StateNotifierProvider` / `ChangeNotifierProvider` moved to `package:flutter_riverpod/legacy.dart`. **Do not use them** — use `Notifier`, `AsyncNotifier`, `StreamNotifier`.
- Riverpod 3 also unifies the `AutoDispose*` variants into the base classes, adds automatic retry for failed providers, and pauses off-screen listeners. **Confirm exact behavior in `riverpod.dev/docs/whats_new`** before writing providers, and set `retry` explicitly for providers that return `Result`/failures (we usually don't want blind retries on validation errors).
- `riverpod_annotation`/generator is optional; if adopted, adopt for **all** providers (no mixing).
- `Notifier.ref.mounted` / `ref.onDispose` for cleanup.

## 5. Upgrade policy
- Monthly: `flutter pub outdated` → upgrade minors in one PR; majors one package per PR with changelog notes.
- Flutter upgrades: wait for `.1` patch, run full test + golden suite, then bump FVM + CI together.
- Never use prerelease (`-dev`, `-beta`) packages in `main` unless wrapped behind an interface and listed here with an exit plan.
- Renovate/Dependabot weekly PRs enabled.
