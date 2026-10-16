# Versions.md — Toolchain & Dependency Baseline

**Last checked: 10 Oct 2026** (web search of pub.dev / Flutter blog). Versions move fast — this file is the single source of truth. When you add or upgrade a package: run `flutter pub add <pkg>` (resolves the latest compatible), then **update the table** and commit `pubspec.lock`.

> ## ⚠️ Toolchain status — READ THIS FIRST
>
> ### Update (16 Oct 2026): the toolchain runs locally — the blocker was the proxy, not pipes
>
> `flutter analyze`, `flutter test` and `flutter gen-l10n` **all work on this box now**. The
> failure was never the pipe ceiling: the shell exports `http_proxy` / `https_proxy` /
> `HTTP_PROXY` / `HTTPS_PROXY`, and `flutter test` talks to each `flutter_tester` over a
> **localhost WebSocket**. The Dart HTTP client honours those variables, so the upgrade request
> went to the proxy instead of the test isolate and *every* file died identically with
> `WebSocketException: Invalid WebSocket upgrade request` — which reads like a Flutter bug and is
> not one. (`flutter analyze` and `gen-l10n` were failing for the same reason; they also open
> localhost connections.)
>
> ```sh
> # what works — unset the proxy for the tool process only
> env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY flutter test
> env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY flutter analyze
> env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY flutter gen-l10n
> ```
>
> This matters because **golden tests can only be driven through `flutter test`** —
> `tool/run_test.sh` compiles a single file to a kernel and cannot do golden comparison, so
> before this the golden suite had never actually run locally. It has now: 1413 tests green on
> Windows, goldens included.
>
> `tool/run_test.sh` and `tool/typecheck.sh` are still the fallback if the pipe problem below
> reappears; they are no longer the *only* way to run anything. **CI is no longer the only
> oracle** — treat the local run as the first check and CI as the cross-platform confirmation.
>
> ---
>
> The pipe analysis below is still accurate for `Process.start` in general, and still explains why
> `build_runner` cannot run here.
>
> **The toolchain is correct. `pub get` succeeds.** The one thing that does not work in the
> agent's sandbox is *spawning child processes* (`dart:io` `Process.start` cannot create pipes).
>
> The Flutter SDK lives at `C:\sdks\flutter_windows_3.38.2-stable\flutter` — **the folder name
> is stale**; the contents are **Flutter 3.47.7 / Dart 3.13.5**. Confirmed by both
> `bin/cache/flutter.version.json` (`frameworkVersion 3.47.7`, `dartSdkVersion 3.13.5`,
> `frameworkRevision abaf9c5237`, `engineRevision deb287481e`) and
> `git -C <sdk> describe --tags` → `3.47.7`. **Do not judge this SDK by its directory name.**
>
> `pubspec.yaml`'s `flutter: ">=3.47.0"` / `sdk: ^3.13.0` are therefore satisfied. Resolving
> works when the bundled Dart is used directly:
>
> ```sh
> export FLUTTER_ROOT="C:/sdks/flutter_windows_3.38.2-stable/flutter"
> "C:/sdks/flutter_windows_3.38.2-stable/flutter/bin/cache/dart-sdk/bin/dart.exe" pub get
> # → Changed 84 dependencies!  (.dart_tool/package_config.json: 28 → 106 packages)
> ```
>
> **What fails, and exactly why.** Any Dart `Process.start` dies with
> `CreateFile failed 231 (All pipe instances are busy. … process_win.cc:744)`. A minimal
> `Process.run(cmd.exe, ['/c', 'echo', 'hello'])` reproduces it with **no packages involved**, so
> this is not a project problem.
>
> **Root cause (proved, not guessed).** Dart's Windows process launcher creates a *named* pipe
> per stdio stream via `CreateNamedPipeW`. Bisecting each argument in isolation shows:
>
> | Call | Result |
> |---|---|
> | `CreateNamedPipeW(..., nMaxInstances = -1, ...)` | **fails, `ERROR_INVALID_PARAMETER` (87)** |
> | `CreateNamedPipeW(..., nMaxInstances = 1 or 255, ...)` | succeeds |
> | `CreatePipe` (anonymous, what CPython uses) | succeeds |
> | `Process.start` from Dart | **always fails** |
> | `subprocess.run(..., capture_output=True)` from Python | **always succeeds** |
>
> So the sandbox's restricted token rejects `nMaxInstances = -1`, which is the value Dart passes.
> The `231 (ERROR_PIPE_BUSY)` text in the message is the follow-on symptom when a stale pipe name
> is already taken. **Named pipes are not globally blocked** — only this specific combination is.
> Everything in Dart that shells out is therefore blocked:
>
> | Command | Blocked because it spawns |
> |---|---|
> | `dart analyze` | `analysis_server_aot.dart.snapshot` |
> | `dart run build_runner build` | `frontend_server_aot.dart.snapshot` (pub precompile) |
> | `build_runner` via its direct `bin/` path | got to `compiling builders/aot`, then `dart compile aot-snapshot` |
> | `dart compile exe` / `aot-snapshot` | a child `dart.exe` |
> | `flutter` bash/batch launcher | `git` |
>
> **One useful exception:** `flutter gen-l10n` can be driven by invoking the tools snapshot
> directly — it reaches the generator, writes all four files, and only trips over the pipe wall at
> its final `dart format` pass, which is cosmetic and can be run separately:
>
> ```sh
> export FLUTTER_ROOT="C:/sdks/flutter_windows_3.38.2-stable/flutter"
> "$FLUTTER_ROOT/bin/cache/dart-sdk/bin/dart.exe" \
>   "$FLUTTER_ROOT/bin/cache/flutter_tools.snapshot" --no-version-check gen-l10n
> # → writes lib/l10n/generated/app_localizations{,_en,_ja,_my}.dart
> # → then errors on `dart format`; ignore and format afterwards
> ```
>
> So **`build_runner`, `flutter analyze` and `flutter test` must be run from a normal terminal or
> CI** — for reasons that have nothing to do with the SDK being old or missing.
>
> **Usable locally:** `dart format`, `dart <file>.dart` JIT-running any script that does not spawn
> a subprocess, and the direct-snapshot `gen-l10n` above. That is how the domain/presentation test
> suite and the localizations are verified here.
>
> **CI is the verification channel.** GitHub Actions runs on Flutter 3.47.1 / Dart 3.13.1 and
> *does* execute `pub get`, `analyze` and `test` successfully. `docs/Versions.md` §3 is therefore
> populated from **CI-resolved versions**, not from local runs.
>
> **On a working machine:** no FVM install is required for local work — the installed SDK already
> *is* 3.47.7, which satisfies `flutter: ">=3.47.0"`. Run `flutter pub get`, then
> `dart run build_runner build --delete-conflicting-outputs`. FVM is only worth adding to pin the
> version for CI parity (`.fvmrc` already records `3.47.1`).

## 1. Toolchain
| Item | Baseline | Status |
|---|---|---|
| Flutter | **3.47.7** (stable, 8 Oct 2026) | ✅ installed at `C:\sdks\flutter_windows_3.38.2-stable\flutter` — **folder name is stale**, contents are 3.47.7 |
| Dart | **3.13.5** | ✅ installed (bundled with that Flutter, `bin/cache/dart-sdk`) |
| Pin with | **FVM** (`.fvmrc` = `3.47.1`), CI uses `FLUTTER_VERSION: 3.47.1` | ✅ `.fvmrc` created · local SDK is 3.47.7 — close enough for a patch-level pin; CI stays on 3.47.1 |
| `pubspec.yaml` | `environment: sdk: ^3.13.0` · `flutter: ">=3.47.0"` | ✅ applied |
| iOS | Xcode with iOS 26 SDK; app minimum iOS 15 (required by `adaptive_platform_ui`). UIScene lifecycle + Swift Package Manager are the default direction | ✅ configured |
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
| `drift` | **2.32.0** | with `drift_dev` 2.32.0 (same minor) and `drift_flutter` **0.3.0**; `uuid` 4.6.0. Resolved via CI on 11 Oct 2026 |
| `go_router` | **^17.x** (17.0.0 confirmed; resolve latest 17.x+) | breaks APIs between majors — read changelog; keep `go_router_builder` on matching major |
| `freezed` / `freezed_annotation` | **freezed 3.2.5** (Feb 2026; may be newer) | 3.x syntax: classes are `sealed`/`abstract` with mixin; **don't use 4.0 dev prerelease**. Pair with `build_runner`, `json_serializable` |
| `material_ui`, `cupertino_ui` | **1.0** | see §2 |

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
| `adaptive_platform_ui` | **1.0.2** | `^1.0.2` | Native iOS 26 tab bar, Cupertino fallback, and Material navigation; requires iOS 15 |
| `flutter_riverpod` | **3.4.3** | `^3.4.3` | Presentation state (Riverpod 3 — see §4) |
| `go_router` | **17.5.0** | `^17.5.0` | Routing |
| `get_it` | **9.3.0** | `^9.3.0` | DI for data/domain |
| `intl` | **0.20.3** | `^0.20.3` | Date/number formatting |
| `flutter_svg` | **2.3.0** | `^2.3.0` | Avatar v2 vector rendering (`docs/Avatar.md` §5; Apache 2.0; supports iOS/Android/web) |
| `flutter_lints` | template default | `^6.0.0` | Dev dependency |

Gotcha worth recording: **`cupertino_ui` re-exports `package:flutter/widgets.dart`**, and both
`material_ui` and `cupertino_ui` export `dart:ui`'s text primitives transitively (via
`flutter/painting` → `basic_types.dart`). That means `FontFeature`, `FontWeight`, `Color`,
`Offset`, etc. are available from `package:material_ui/material_ui.dart` alone — an explicit
`import 'dart:ui'` is flagged `unnecessary_import`. Do **not** add one.

`drift`, `freezed`, `dio` and the rest of §3 are **deliberately not declared yet** — they belong
to the roadmap items that use them, and adding them here would put an unused dependency in
the build for no reason. Add each one in the PR that first needs it (`Agent.md` §3.14).

### Drift layer — **declared 11 Oct 2026** (Phase 1 blocker cleared)

`drift` + `drift_dev` + `drift_flutter` + `uuid` are now real dependencies (the Drift database
layer, `docs/DataModel.md`, is implemented). Everything below is a **build-behaviour fact**, not
a version note — it was established by reading drift 2.32.0 / drift_dev 2.32.0 source, because
this machine cannot run `build_runner`.

- **Codegen runs in *monolithic* mode by default.** `DriftGenerationMode.monolithicSharedPart`
  emits `.drift.g.part`, which `source_gen:combining_builder` turns into a `.g.dart` **for the
  input file**. A file is only processed if it contains a `@DriftDatabase` or `@DriftAccessor`;
  `drift_builder.dart` bails early otherwise.
  **Consequence:** `drift_dev` generates exactly four files here — `app_database.g.dart` and the
  three `daos/*_dao.g.dart`. There are **no** `tables/*.g.dart` files, and the table files
  correctly carry no `part` directive. The `$XTable`, `X` (row) and `XCompanion` classes are all
  written **into `app_database.g.dart`**, because `DatabaseWriter.write()` walks
  `resolvedAccessor.availableElements` and emits each `DriftTable` into the *database's* part.
  A table `.dart` file is therefore a plain library, imported for its `Table` subclass only.
- **Aggregate calls must be annotated.** `ArithmeticAggregates<DT extends num> on Expression<DT>`
  declares `Expression<DT> sum({Expression<bool>? filter})`. `drift_dev` emits a plain integer
  column as `late final GeneratedColumn<int>`, and `int` does *not* pin `DT` tightly enough —
  inference can settle on `num`, which then will not fit an `int` target. Write
  `final Expression<int> total = transactions.amountMinor.sum();` in the DAO. See
  `TransactionsDao.watchMonthDailyTotals` for the failure this caused.
- **`isNotNull` collides.** `package:drift` exports a SQL `isNotNull` operator as well as the
  `flutter_test` matcher of the same name. A test that uses both needs
  `import 'package:drift/drift.dart' hide isNotNull;`.
- **No `update`/`insert` names on a DAO.** `DatabaseAccessor` already declares public
  `update<Tbl, R>(TableInfo<Tbl, R>)` and `into<T, D>(TableInfo<T, D>)`, so a DAO method named
  `update(String id, …)` is a compile error, not an overload. Use `updateById`.
- **`CommonColumns` must be a `mixin`, not an `extension`.** An `extension on Table` is not
  mixin-able, so `class Foo extends Table with CommonColumns` cannot refer to one.

Run `./scripts/codegen.sh` after any change under `lib/core/database/`. Generated files are
**committed**.

### Avatar art source — **verified 12 Oct 2026** (Avatar v2 step 1 spike)

Not a package (no runtime dependency) — the art is extracted at build time and committed
(`docs/Avatar.md`). Recorded here because §1 requires the license be verified at implementation
time with the date.

- **Source definition:** `dicebear/styles/src/open-peeps.json` (`@dicebear/schema@2.0.1`),
  downloaded 12 Oct 2026. Also available as the `dicebear_styles` pub package (`open_peeps`).
- **License: `CC0 1.0`** — confirmed both in the definition's `meta.license` and on
  `dicebear.com/licenses` (12 Oct 2026), where Open Peeps is listed under "CC0 1.0" as a
  *"Remix of Open Peeps by Pablo Stanley"*. Original work: Open Peeps, Pablo Stanley.
  CC0 requires no attribution; we credit anyway (Settings → Credits, Avatar v2 step 5).
- **Canvas 704 × 704; groups `head`(48) · `expression`(30) · `facialHair`(16) ·
  `accessories`(8) · `mask`(2); color groups `skin`(5) · `clothing`(7) · `headContrast`(10) ·
  `ink`(1).** Full report in `docs/Avatar.md` §9.
- **`flutter_svg` is still NOT declared** — it is added in the PR that first needs it (step 3,
  the composer); per §3/§"Phase 0", no premature dependency.



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
