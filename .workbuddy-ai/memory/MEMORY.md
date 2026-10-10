# Ledgerly — Project Memory

Flutter personal budget manager. Clean Architecture, feature-first. See `docs/Agent.md` first.

## Environment (critical)
- **`flutter` CLI does not work on this machine.** Any invocation fails with
  `ProcessException: All pipe instances are busy (process_win.cc:742)` — it cannot spawn
  child processes at all. Consequently `flutter pub get / add / analyze / test / gen-l10n`
  have never run, and **no Dart code in this repo is compile-verified**.
- Installed SDK: **Flutter 3.38.2 / Dart 3.12.2**. Documented target: **Flutter 3.47.1 /
  Dart 3.13.1** (pinned in `.fvmrc`).
- `material_ui` / `cupertino_ui` require Flutter 3.47+. They are Flutter 3.47 packages and
  **cannot resolve on 3.38.2**. Install FVM + 3.47.1 before trusting any build.
- Docs live in `docs/` (moved there 2026-10-10). `docs/Design.md` was authored from scratch —
  it is the mandatory spec for all UI work.

## Conventions that are easy to get wrong
- Import `package:material_ui/...` / `package:cupertino_ui/...`. **Never**
  `package:flutter/material.dart` or `cupertino.dart`. Enforced by the CI `banned-imports` job.
- No legacy Riverpod (`legacy.dart`, `StateProvider`, `StateNotifierProvider`,
  `ChangeNotifierProvider`). Use `Notifier` / `AsyncNotifier` / `StreamNotifier` only.
- **Money is an `int` in minor units + `CurrencyCode`.** Never `double`. Use `Money`,
  `Money.minor` / `fromMajor` / `tryParse`; render only through `MoneyFormatter` / `AmountText`.
- Money colors: **out = expense = red (coral), in = income = green (sage)**. Universal,
  not configurable. Documented in `docs/Design.md` §2.4.
- All amounts use **tabular figures** (`AppTypography.tabularFigures`).
- No hardcoded colors/spacing/radii/strings — use `app/theme` tokens and ARB keys.
- Layer rule: `domain/` is pure Dart. `presentation` calls use cases only, never repositories.
- Tests named `should_<expected>_when_<condition>`.

## Architecture anchors
- `lib/app/theme/` — design tokens. Widgets read colors via `AppThemeColors.of(context)`
  (returns an `AppColors`), not `Theme.of(context).colorScheme`.
- `lib/core/platform/` — `AppPlatform`, `WindowSizeClass`, `AdaptiveStyle`. **Only
  `core/widgets` branches on platform**; pages never do.
- `lib/core/result/` — sealed `Result<T>` (`Success`/`Err`) + sealed `Failure` (8 cases).
- `lib/core/money/` — `Money`, `CurrencyCode`, `MoneyFormatter`.
- `lib/app/di/injection.dart` — get_it; feature modules register via `registerXModule(getIt)`.
  Riverpod providers bridge to it: `Provider((_) => getIt<AddTransaction>())`.

## Pending / known gaps
- iOS flavors not configured (`ios/Runner.xcodeproj` still `com.yk.dev.ledgerly`).
- `lib/l10n/generated/` is empty — bindings not generated; `MaterialApp` has no
  `localizationsDelegates` yet.
- Fonts (Inter, Noto Sans Myanmar, Noto Sans JP) not bundled in `pubspec.yaml`.
- `pubspec.lock` is stale (predates the pubspec rewrite).
- Design-system widgets (`core/widgets/*`) not built — specs are in `docs/Design.md` §5.
