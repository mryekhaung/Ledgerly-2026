# Conventions.md

## 1. Naming & style
- Files `snake_case.dart`; classes `UpperCamelCase`; one public class per file where reasonable.
- Suffixes: `*Page`, `*Widget` (only if needed), `*Notifier`, `*Provider`, `*UseCase` (verb-first class: `AddTransaction`), `*Repository`, `*RepositoryImpl`, `*LocalDataSource`, `*RemoteDataSource`, `*Model` (data DTO), entities have no suffix.
- Lints: `very_good_analysis` or `flutter_lints` (latest, see `Versions.md`) + extras; **zero analyzer warnings**.
- **Imports:** `package:material_ui/...` and `package:cupertino_ui/...` (Flutter 3.47+); never `package:flutter/material.dart` / `cupertino.dart`. Platform-specific code only inside `core/widgets` adaptive components.
- **Dart 3.13:** use records/patterns/sealed/dot-shorthands freely; abbreviated constructors (`new()`) are **not** adopted unless the team decides (don't mix styles).
- **Web-safe code:** no `dart:html`, `dart:js`, or unguarded `dart:io`; use `package:web`, conditional imports.
- **Riverpod 3:** only `Notifier`/`AsyncNotifier`/`StreamNotifier`; legacy providers forbidden (`flutter_riverpod/legacy.dart`).
- Prefer `final`, `const`, sealed classes, pattern matching; avoid `dynamic`, `!` (null-bang) and `late` without justification.
- Max ~200 lines per widget file; extract widgets as **classes** (not helper methods returning Widget).
- Absolute `package:` imports; no relative imports across features.

## 2. Layer import rules (enforce with `import_lint`/custom lint)
| From | May import |
|---|---|
| `domain` | `dart:*`, `core/result`, `core/money`, `core/usecase` only |
| `data` | `domain`, `core/*`, vendor packages |
| `presentation` | `domain`, `core/widgets`, `app/theme`, Flutter, Riverpod |
| `features/a` → `features/b` | Only via `b/domain` public API; never `b/data` or `b/presentation` |

## 3. Memory & performance rules
**Disposal**
- Every `StreamSubscription`, `TextEditingController`, `FocusNode`, `ScrollController`, `AnimationController`, `Timer`, `PageController` → disposed in `dispose()` (or `ref.onDispose`).
- Riverpod: `autoDispose` for screen-scoped providers; use `ref.keepAlive()` deliberately and document why.
- Cancel in-flight work on dispose (`CancelToken` for Dio, `StreamSubscription.cancel`).
- Never hold `BuildContext`/`WidgetRef` in long-lived objects.

**Rendering**
- `const` constructors everywhere possible; split widgets to narrow rebuild scope.
- Lists: `ListView.builder` / `SliverList.builder`, `itemExtent`/`prototypeItem` when row height fixed, `AutomaticKeepAlive` only when needed.
- `RepaintBoundary` around heavy independent paints (charts, calendar grid).
- Avoid `Opacity`/`ClipRRect`/`saveLayer`-heavy trees in scrolling lists; prefer `ColoredBox`, `DecoratedBox`, alpha colors.
- Use `select` to rebuild on the minimal slice of state.

**Data**
- Paginate transactions (page size 50); never load "all" into memory.
- Aggregate in SQL; stream only what the screen shows.
- Parse/export/import big files in an **isolate** (`Isolate.run`/`compute`).
- Cache SVG/icons via const maps; no per-frame allocations in `build`/`paint`.
- Images (avatars/receipts): downscale at decode (`cacheWidth`), compress before storing.

**Verification**
- Profile in `--profile` on a real low-end device with DevTools: check rebuild counts, jank, memory growth after 10× open/close of each screen (no growth = no leak).
- `leak_tracker` enabled in debug/tests.

## 4. Error & logging
- `AppLogger` abstraction (debug → console; release → crash reporter optional). No `print`.
- User-facing errors are localized & actionable; technical details only in logs.

## 5. Localization
- All strings in ARB (`en`, `my`, `ja`); no string concatenation for sentences (use ICU placeholders/plurals).
- Dates/numbers via `intl` with active locale. Test Burmese rendering (Unicode, not Zawgyi).

## 6. Testing rules
- Arrange-Act-Assert; name: `should_<expected>_when_<condition>`.
- Fakes over mocks for repositories in presentation tests; `mocktail` for isolated unit tests.
- Golden tests for design-system widgets in light/dark + text scale 1.0/2.0.
- CI must pass: format → analyze → test → (optional) build.

## 7. Git & CI
- Repository: `https://github.com/mryekhaung/Ledgerly-2026.git`
- **Branch model — three long-lived branches:**

  | Branch | Purpose | Receives |
  |---|---|---|
  | `dev` | **Default working branch.** All day-to-day work lands here. | `feat/*`, `fix/*` via PR |
  | `main` | Stable, reviewable integration line. Nothing is released from here directly. | PR from `dev` when a milestone is ready |
  | `prod` | **Production release branch — push/tag here = ship to stores.** | PR from `main` only, at release time |

  Short-lived branches: `feat/<name>`, `fix/<name>` — cut from `dev`, merged back into `dev`.
  Flow: `feat/* → dev → main → prod`. Never commit directly to `main` or `prod`.
- **Conventional Commits:** `feat(calendar): add day capsule intensity`.
- PRs small & focused; checklist = Definition of Done (`Agent.md`).
- GitHub Actions: format check, analyze, test with coverage, build APK/IPA artifacts on tags.
- Flavors: `dev` / `prod` (different bundle ids, remote adapters).
  - ⚠ CI currently runs on `main` / `develop` pushes — **update the trigger list to `dev` / `main` / `prod`**
    now that the branches are renamed (`docs/Roadmap.md` Phase 0 follow-up).


## 8. Security basics
- No secrets in git. Obfuscate release builds (`--obfuscate --split-debug-info`).
- Validate all imported data; treat files as untrusted.
- Biometric lock via `local_auth` (v0.4).
