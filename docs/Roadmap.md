# Roadmap.md

Legend: ☐ todo · ◐ in progress · ☑ done. Each task = one small PR following `Agent.md` §5.

**Where we are (16 Oct 2026):** Phases 0–3.5 are **done** — the app is a working
local-first budget manager with calendar, transactions, categories, settings,
accounts, budgets, recurring, goals, insights, import/export, full backup and
a local-only auth simulator. `flutter test` is **1437 green** and `flutter analyze` is clean,
**locally as well as on CI** (`docs/Versions.md` — the proxy fix). **Phase 4
(Sync & Polish) is the only unstarted phase**, and its blocker is now cleared:
**`docs/Backend.md` has been written** (options, criteria and a recommendation
for the owner to ratify — §G.1). No Phase 4 code exists yet: `lib/features/sync/`
is 14 `.gitkeep` files and `pubspec.yaml` carries no backend package at all.
Phase 5 (Release) is unstarted.


## Phase 0 — Foundation

- ☑ **Pin toolchain** (FVM 3.47.1, Dart ^3.13, CI same); create project with `material_ui` / `cupertino_ui` imports; resolve & record all unverified packages in `docs/Versions.md`
  - ✅ `.fvmrc` = 3.47.1, `pubspec.yaml` `sdk: ^3.13.0` / `flutter: ">=3.47.0"`, CI pinned to 3.47.1
  - ✅ Every package resolved on CI with Flutter 3.47.1 and recorded in `docs/Versions.md` §3: `material_ui` 1.6.0, `cupertino_ui` 1.1.2, `flutter_riverpod` 3.4.3, `go_router` 17.5.0, `get_it` 9.3.0, `intl` 0.20.3.
  - ✅ **The installed SDK is 3.47.7 / Dart 3.13.5** — the directory name `flutter_windows_3.38.2-stable` is stale and must not be trusted. Proven from `bin/cache/flutter.version.json` and `git describe --tags`. `pub get` succeeds locally (28 → 106 packages), so the version pins are satisfied and **no FVM install is needed** for local work.
  - ✅ The only local limitation is that Dart cannot spawn child processes in the agent sandbox: `CreateNamedPipeW` with `nMaxInstances = -1` returns `ERROR_INVALID_PARAMETER` (87), which is the value Dart passes. Named pipes are *not* globally blocked (Python's `capture_output=True` works), so this is a sandbox/token interaction with Dart's launcher, not a project defect. Full analysis in `docs/Versions.md`. **CI remains the verification channel of record**; locally we can run `dart format`, JIT-run non-spawning scripts, and `gen-l10n` via the tools snapshot.
- ☑ Riverpod 3 baseline provider/notifier template + lint rule banning `legacy.dart` imports
  - ✅ CI `banned-imports` job enforces the ban on `legacy.dart`, `StateNotifierProvider`, `ChangeNotifierProvider`, and `StateProvider`.
  - ✅ Pure-architecture layer rule test (`test/core/layer_rule_test.dart`) enforces Riverpod 3 purity across `lib/`.
  - ✅ Canonical Riverpod 3 templates implemented in `lib/core/presentation/riverpod_templates.dart` covering `Notifier`, `AsyncNotifier`, `StreamNotifier`, and use-case bridge helpers; verified with full unit tests in `test/core/presentation/riverpod_templates_test.dart`.
- ☑ Create Flutter project, flavors (dev/prod), lints, CI (format/analyze/test)
  - ✅ CI green on `dev` at `8523fb7`: banned-imports, format, analyze (**0 issues**), test (**145 passing**). `dev` → `main` → `prod` all merged and pushed.
- ☑ `core/`: Result, Failure, UseCase, Money + MoneyFormatter, LocalDate (+ tests)
  - ✅ `Money` is `int` minor units + `CurrencyCode`; `showSign: false` renders the magnitude unsigned (direction is carried by colour/layout — `docs/Design.md` §2.4).
  - ✅ `Money.tryParse` is pure-integer (no `double`): a naive `double.tryParse(...) * 100` read `1.005` USD as 100¢ and lost cents on 15-digit values. Separator handling is currency-aware (`1.005` USD → 101¢, `1,234` EUR → 123¢, `1234.56` EUR → 123456¢) and rejects malformed grouping (`1.2.3`, `1,23,456`). 15-digit cap keeps intermediates inside ±2⁵³ on web too.
  - ✅ `LocalDate` (packed `yyyyMMdd`) added for transaction dates; additive, so `8523fb7` remains a valid green baseline.
- ◐ Design tokens (`app/theme`): colors light/dark, typography, spacing, radius — done; motion/elevation included. Awaiting a font-bundling pass.
  - ✅ Contrast verified against WCAG AA with the correct sRGB relative-luminance curve (`channel(v) = v ≤ 0.03928 ? v/12.92 : ((v+0.055)/1.055)^2.4`); coral and sage both clear 4.5:1.
- ◐ get_it bootstrap + Riverpod `ProviderScope` + go_router skeleton — wired; the real adaptive nav shell lands with the design-system item below
- ◐ l10n setup (en/my/ja) + font bundling — **localizations now generate and validate**; fonts not bundled.
  - ✅ All 73 keys present in en/my/ja with an ARB ↔ generated ↔ lookup parity check of **73/73/73** and `l10n_untranslated.json` = `{}`.
  - ✅ `flutter gen-l10n` runs locally via the tools snapshot (see `docs/Versions.md` for the invocation); `lib/l10n/generated/app_localizations{,_en,_ja,_my}.dart` are written and committed, so CI needs no extra step.
  - ✅ `MaterialApp` wires `GlobalMaterialLocalizations.delegates` from `material_ui`, so the framework's en/my/ja strings resolve; our `AppLocalizations` delegate joins that list.
  - ⚠ Three real ARB defects were found only once codegen ran: `synthetic-package` is deprecated, `generate: true` is required with an explicit `output-dir`, and **ARB keys must be valid Dart identifiers** — all 73 keys were renamed `navigation.calendar` → `navigationCalendar`. The 73 `@`-metadata entries were also malformed (lists, not maps).
  - ☐ Font bundling (Padauk / Noto) still todo.
- ◐ Drift database, migration test harness, seed defaults — **implemented; awaiting first real codegen run in CI**
  - ✅ `drift` / `drift_dev` / `drift_flutter` / `uuid` declared and pinned (`docs/Versions.md` §3).
  - ✅ Schema v1: `categories`, `transactions`, `accounts` + 6 `@TableIndex` hot-path indexes — spec in `docs/DataModel.md`.
  - ✅ Three DAOs (`CategoriesDao`, `TransactionsDao`, `AccountsDao`): soft-delete-filtered reads, `updateById`, `softDelete`, plus `setArchived`/`reorder`; all aggregation done in SQL (`SUM … FILTER … GROUP BY`).
  - ✅ Migration harness: `test/core/database/migration_test.dart` — cold-open `onCreate`, `PRAGMA foreign_keys` proven *enforced* not just set, index/column/nullability contract, and a seed-survives-reopen baseline for the first real upgrade test.
  - ✅ Seed defaults: `seedDefaults()` inserts the 11 starter categories (9 expense + 2 income) with dense `sortOrder` and `isDefault = true`; idempotent by physical emptiness, so a user who deletes them all does not get them back.
  - ✅ Test suite: `db_harness.dart` + per-DAO suites + `seed_test.dart` (~60 cases) over `NativeDatabase.memory()`.
  - ✅ `scripts/codegen.sh` — the committed-codegen entry point.
  - ⚠ **`build_runner` has never run.** `drift_dev` has not validated the `@TableIndex` / `@DriftDatabase` annotations, and no `.g.dart` exists yet. The DAO/table signatures were compile-checked against a hand-written replica of the generated code, and the emitted SQL was asserted textually (38 assertions); the schema was checked with 58 further assertions. **CI's first `build_runner` + `flutter test` is the real validation** — treat the first CI run as part of this item, not after it.
  - The item stays ◐ until that CI run is green; see `docs/Versions.md` §3 for the four build-behaviour facts (monolithic codegen, aggregate annotation, `isNotNull` collision, `updateById` naming) that were derived from drift's source and cost real debugging time.
- ◐ `core/platform/` (AppPlatform, WindowSizeClass, AdaptiveStyle) + `GlassSurface` spike: blur fallback first, then `cupertino_native_better` (native iOS 26 tab bar/buttons); `liquid_glass_renderer` experimental only — decide & document
  - ✅ `core/platform/` done (`app_platform.dart`, `window_size.dart`, `adaptive_style.dart` + `window_size_test.dart`); GlassSurface spike still todo, so the item stays ◐.
- ☐ Web spike: Drift (`drift_flutter` WASM) + conditional imports + fonts + `flutter build web --wasm` running
- ◐ Design-system widgets (adaptive iOS/Material impls + responsive helpers): AppScaffold, AppCard, CategoryGem, AmountText, SegmentedTabs, ListRow, buttons, fields, EmptyState, GlassDock (+ goldens)
  - 📄 Specs for all of these live in `docs/Design.md` §5
  - ✅ `AmountText`, `AppCard`, `ListRow`, `SegmentedTabs`, `AppButton`, `AppScaffold` shipped under `core/widgets/`; covered by widget tests (`amount_text_test.dart`, `design_system_widgets_test.dart`).
  - ☐ Goldens not yet scaffolded.


## Phase 1 — MVP "Log & See" (v0.1) — STARTED (data layer only)

Every `lib/features/*` folder named below exists but holds only `.gitkeep` scaffolds; there is no `lib/data/` or `lib/domain/` yet. The **persistence layer** under `lib/core/database/` is done (see the Phase 0 Drift item above) — what Phase 1 still needs is the domain layer on top of it.

- ◐ Categories: domain/data/use cases (CRUD, reorder, archive)
  - ✅ `CategoriesDao` done (persistence).
  - ✅ Domain: `Category` entity + `CategoryKind`; `CategoryValidators` (name/icon/colour, case-insensitive uniqueness); `CategoryRepository` interface; 7 use cases (`WatchCategories`, `WatchPickableCategories`, `GetCategory`, `SaveCategory`, `DeleteCategory`, `SetCategoryArchived`, `ReorderCategories`).
  - ✅ Data: `CategoryMapper`, `CategoryLocalDataSource`, `CategoryRepositoryImpl` (every call funnelled through `guardResult`).
  - ✅ DI + Riverpod bridge: `features/categories/di/categories_module.dart`, `presentation/providers/category_providers.dart`.
  - ☐ Categories pages: list + form (icon grid, color palette, live preview).
  - ✅ Tests: 24 validator + 22 use-case cases **executed** locally; 23 data cases written against a real `NativeDatabase.memory()` (execution needs `flutter test` — see the Phase 0 `build_runner` caveat above).
- ☐ Categories pages: list + form (icon grid, color palette, live preview)
- ◐ Transactions: domain/data/use cases (add/update/delete/watch by month/day)
  - ✅ `TransactionsDao` done (persistence, incl. month/day watches and SQL aggregates).
  - ✅ Domain: `Transaction` entity + `TransactionDirection`; `DailyTotal`/`CategoryTotal`/`MonthTotal`; `TransactionValidators`; `TransactionRepository` interface; 9 use cases (`WatchDayTransactions`, `WatchMonthTransactions`, `WatchMonthDailyTotals`, `WatchMonthCategoryTotals`, `WatchMonthTotal`, `GetTransaction`, `SaveTransaction`, `DeleteTransaction`, `RestoreTransaction`).
  - ✅ Data: `TransactionMapper`, `TransactionLocalDataSource`, `TransactionRepositoryImpl`. The mapper **throws** on an unknown stored currency/direction, unlike the category mapper — a wrong direction flips the sign of money in every total.
  - ✅ DI + Riverpod bridge: `features/transactions/di/transactions_module.dart`, `presentation/providers/transaction_providers.dart`.
  - ✅ Tests: 26 validator + 28 use-case cases **executed** locally; 31 data cases written (same execution caveat as above).
- ☑ Add/Edit Transaction page + AmountKeypad + Category Picker page
  - ✅ `AmountEntry` (pure Dart, 23 tests): digit/decimal/backspace rules, per-currency precision.
  - ✅ `AmountKeypad` widget: display row + numeric tray, 56 px keys, `surfaceSunken` background, `SafeArea(top:false)`.
  - ✅ `TransactionFormState` (pure Dart, 16 tests): entry buffer → `Money?` → `TransactionDraft?`; `from(Transaction)` seeds the buffer correctly for MMK/USD.
  - ✅ `TransactionFormNotifier` (Riverpod `autoDispose`): `initialise`, digit/decimal/backspace/clear, `setDirection`/`setDate`/`setCategory`/`setNote`, `save()` with `ValidationFailure` folding and `ref.mounted` guard.
  - ✅ `CategoryPickerPage`: `StreamBuilder<Result<List<Category>>>` over `watchPickableCategoriesProvider`, empty/error states, pops chosen `Category`.
  - ✅ `TransactionFormPage`: direction toggle, category row (launches picker, shows gem + name), date row (launches `MonthDayPickerPage`), note field (owning `TextEditingController`), `AmountKeypad` at thumb height, `ref.listen` pop on save.
  - ✅ `MonthDayPickerPage` + `MonthGridLayout` (pure Dart, 18 tests): Monday-first grid, month switcher with `LocalDate.addMonths`, today shortcut, blank cells at edges, leap-year Feb 29 verified.
  - ✅ `FormFieldSurface` + `FormFieldError` + `FormFieldChevron`: shared `surfaceSubtle` filled field, `warningSubtle` error treatment, `radius.md`, no Material outline boxes.
- ✅ `AppStringLookup` updated with `transaction.saved`, `transaction.deleted`, `transaction.undo`, `state.empty.title`, `state.empty.body`.
- ✅ Routes: `AppRoutes.transactionNew` → `TransactionFormPage`; `AppRoutes.transactionEditRelative` nested under it, with `_TransactionEditLoader` resolving via `FutureBuilder<Result<Transaction>>`.
- ✅ Shim suite: 164 tests passing, non-vacuous (corrupted `cellCount` → 2 failures).
- ☐ Goldens, haptics, responsive layout still todo.
- ◐ Calendar page: Day Capsules, month switcher, summary card, day list
  - ✅ `CalendarPage`: month switcher (`‹ ›` + tappable title), Monday-first weekday header, Day Capsule grid, summary card, day list, FAB → new transaction with the selected day passed as `?date=`.
  - ✅ `CalendarNotifier` + `CalendarState` (pure-Dart month/day arithmetic, month clamping via `LocalDate.addMonths`), with derived `selectedDayTransactionsProvider` / `monthDailyTotalsProvider` / `monthTotalProvider`.
  - ✅ Capsule intensity: `clamp(net / p95MonthNet, 0, 1)` quantized to 5 steps, `moneyOutSubtle` vs `moneyInSubtle` by net direction, 4 px bar at 60 % cell width (Design.md §6.2).
  - ✅ Route `/` now builds `CalendarPage` (was the Phase 0 placeholder).
  - ☐ **Summary card shows the month total, not the day total** — a day-level aggregate use case (`WatchDayTotal`) does not exist yet. Tracked below.
  - ✅ Horizontal swipe to change month (`_MonthSwipeArea`: velocity + distance threshold, one code path with the `‹ ›` buttons).
  - ✅ Tappable month/year picker (`_MonthSwitcher` title → `MonthYearPickerPage`).
  - ✅ Two-pane medium+ layout (`_WideBody`: each pane scrolls independently).
  - ✅ **Swipe-to-delete/edit on day rows** — `_TransactionRow` is a `Dismissible`: swipe left deletes (soft delete + 5 s undo snack bar, `AppFeedback.destructive`/`undoable`), swipe right edits, on top of tap-to-edit; a trailing overflow menu mirrors both actions for keyboard / screen-reader users. Covered by `calendar_page_test.dart` (delete+undo, edit-snapback, menu items).
  - ☐ `Expanded` density: a tiny amount under each capsule.
- ☑ Settings: currency, language, theme, week start
  - ✅ `app_settings` Drift table (schema **v2**, additive) + `AppSettingsDao` (`readAll`/`watchAll`/`read`/`put`/`putAll`/`remove`).
  - ✅ Domain: `AppSettings` entity (+ `AppThemeMode`, `WeekStart` pure-Dart enums with null-returning `tryParse`), `SettingsRepository` interface, 3 use cases (`LoadSettings`, `WatchSettings`, `SaveSettings`). `SaveSettings` refuses a `partial` write rather than silently doing a full one.
  - ✅ Data: `SettingsLocalDataSource` (owns the storage keys; unknown/missing/empty values decode to the field default — never throws), `SettingsRepositoryImpl` through `guardResult`/`guardResultStream`.
  - ✅ DI + providers: `settings_module.dart`; `settingsProvider` (the one `keepAlive` provider — re-reading during a route transition would flash MMK over a USD amount), plus `currencyProvider`/`weekStartProvider`/`themeModeProvider`/`localeCodeProvider`.
  - ✅ `SettingsPage`: currency (bottom sheet, 10 currencies), appearance (segmented: system/light/dark), week start (segmented: Mon/Sun), language (system/en/my/ja), About (version). No local state — the Drift stream repaints it.
  - ✅ `app.dart` is now a `ConsumerWidget`: `themeMode` + `locale` follow the stored settings; the custom `AppColors` token set is chosen from the *effective* brightness so an explicit light/dark choice recolours the whole tree, not just Material's scheme.
  - ✅ `currencyProvider`'s hardcoded `CurrencyCode.mmk` default is gone — it reads the settings stream now.
  - ✅ Week start is honoured by the calendar: `MonthGridLayout` gained a `GridWeekStart` parameter (default `monday`, so existing tests stayed valid) and `_WeekdayHeader` rotates its `narrowWeekdays` window to match. Both are settings-driven.
  - ✅ Tests: 17 entity/enum, 12 DAO, 10 datasource, 9 use-case cases; migration suite gained a real **v1→v2 upgrade** test that builds the v1 schema by hand and proves both the existing rows and the new table survive.
  - ✅ ARB: 17 new keys in en/my/ja; `l10n_untranslated.json` = `{}`.
  - ✅ **Verified on device** (`emulator-5554`): the v1→v2 upgrade was proved by planting a real v1 file (`sqlite3`, frozen v1 DDL, `user_version = 1`) into the sandbox — the app upgraded it to v2 with `idx_settings_key` present, all 11 categories and the transaction intact. All four preferences round-tripped: currency → `eur`, theme → `dark` (whole UI recoloured), locale → `ja` then `my` (entire UI switched language), week start → `sunday`.
  - ✅ `onUpgrade` now calls `m.createIndex(idxSettingsKey)` explicitly. **`Migrator.createTable` does not emit `@TableIndex` indexes** (only `createAll` does), so an upgraded database was silently missing the index that a freshly created one had. The migration test asserts it.
  - ✅ Bottom-sheet overflow fixed: the 10-currency sheet used a plain `Column`, which overflowed by 117 px on a short screen and hid the last rows. Now a `Flexible` + `shrinkWrap` `ListView`, so it scrolls.
- ✅ **Pay-cycle month — custom month start day** (`docs/DataModel.md` §8, `docs/Design.md` §6.6). A "month" becomes a `BudgetPeriod` that starts on the user's pay day (e.g. the 10th → Oct 10 – Nov 9).
  - ✅ `core/period/`: `BudgetPeriod` + `PeriodCalculator` (pure Dart, `startDay` 1–28) + `LocalDate.addDays` if missing. Tests: year boundary, leap/non-leap Feb, startDay 1 ≡ calendar month, startDay 28, `previous(next(p)) == p` ×100.
  - ✅ Settings: `monthStartDay` key in `SettingsKeys` (no migration; absent/invalid → 1), `AppSettings` field, `SettingsLocalDataSource` decode, `monthStartDayProvider`; **"Month starts on" picker page** with live "Current period: …" preview.
  - ✅ Domain/data: audit `TransactionsDao` month/day queries → take an inclusive `start..end` range; rename `WatchMonthTransactions` / `WatchMonthDailyTotals` / `WatchMonthCategoryTotals` / `WatchMonthTotal` and `MonthTotal` → `*Period*` taking a `BudgetPeriod`. Keep the existing `(date, deletedAt)` index.
  - ✅ Calendar: `CalendarState`/`CalendarNotifier` hold a `BudgetPeriod`; `MonthGridLayout` renders the period's days (padded week edges, tiny month label on each calendar-month 1st); capsule intensity uses `p95PeriodNet`; header shows `Oct 10 – Nov 9` + "Pay cycle" when `monthStartDay` ≠ 1; "today" button, swipe and picker navigate periods. `MonthDayPickerPage` (transaction date picker) stays calendar-based.
  - ✅ ARB keys (en/my/ja): month-starts-on label/description/preview strings, "Pay cycle", "This period".
  - ✅ Tests: period boundary transactions land in exactly one period; changing `monthStartDay` recomputes totals without touching rows; widget walk at 360/768/1440 × text scale 1.0/2.0 for the longer title.
- ☑ **Profile (guest) + Avatar catalog/renderer + Avatar Editor page + random generate** — built; on-device verification pending (see below).
  - ⚠ **Art direction superseded by "Avatar v2 — Open Peeps art" (next item).** On-device review showed the procedural geometric/robot-face avatar and its 5-part editor (background/backdrop/shape/eyes/mouth) do not match the intended Head · Face · Glasses · Item · Colors structure, and the editor sits **inside the app shell**, so the bottom nav covers the Save button. The domain/data plumbing below (profile storage, use cases, routes) is kept; the renderer, catalog and editor UI are replaced.
  - ✅ **Domain** (`lib/features/profile/domain/`): `AvatarConfig` (five indices encoded as `"a-b-c-d-e"`, `tryParse` returns null on anything malformed rather than throwing), `AvatarPart`, `AvatarCatalog` (static option lists — background 8, backdrop 4, shape 4, eyes 4, mouth 4 — plus `optionCount`, `optionIndices`, `random(Random)`, `paintOrder`), `UserProfile`, `UserProfileRepository`, and four use cases: `LoadUserProfile`, `WatchUserProfile`, `SaveAvatar` (rejects `!isValid` → `ValidationFailure`), `SaveDisplayName` (trims; rejects > 40 code units → `profileNameTooLong`; rejects C0/C1/DEL/line-separator characters → `profileNameInvalid`).
  - ✅ **Data**: `ProfileKeys`, `ProfileLocalDataSource` (**reuses `AppSettingsDao`** — no migration, the profile is two scalars), `UserProfileRepositoryImpl` (all through `guardResult`/`guardResultStream`), `registerProfileModule`. Decode never throws: a missing, malformed, empty or out-of-range avatar falls back to `UserProfile.initial.avatar`.
  - ✅ **Renderer**: `AvatarPalette` (9 palette slots resolved per theme — slot 8 is the ink, light/dark variants differ so dark mode is contrast-corrected), `AvatarPainter` (`CustomPainter`, **no new dependency** — `flutter_svg` is not used; every index is clamped), `Avatar` widget (`size`, optional `semanticLabel`).
  - ✅ **Art direction fix — "these look like emoji"** (post-build review): the first composition was a 56% circle centred at 52% with dot eyes and a smile, which at swatch size reads as the smiley glyph. Three changes, no catalogue reordering (the option lists are the persisted format, so only *appending* is safe):
    - The figure is now a **bust**: `AvatarPainter._paintShoulders` draws a torso arc at `shoulderY = 0.80`, clipped by the frame, so the silhouette is a person rather than a floating ball.
    - The head is **smaller and off-centre** (`headHeight = 0.44`, `headCenterY = 0.44`) so the background reads as a frame around the figure instead of a thin border. Both are public constants on `AvatarPainter` so the composition is assertable.
    - `AvatarConfig.initial` is `0-0-1-1-1` (rounded-square head, line eyes, neutral mouth) rather than all-zeros. `initial` is only the seed read before the first save, so existing profiles are unaffected — and it is no longer the one combination that renders as an emoji, which also fixes the editor's swatch grid showing twenty near-identical smileys.
    - `_paintBackdrop` now derives its tint with `AvatarPalette.headFor(colors, background)` instead of using the option's own `PaletteSlot`. That slot (1 = sky blue, 2 = violet) was unresolved against a mint head and produced the **dark grey square** visible behind the head in the iOS screenshot. The slot stays on the option — it is persisted data — but the renderer ignores it for the tint.
    - The eyes and mouth are positioned against the head box rather than the canvas, so they follow the head when it is resized.
  - ✅ **Regression tests** (`test/features/profile/presentation/avatar_painter_test.dart`, 12 cases): the composition constants are pinned (`headHeight < 0.56`, `headCenterY < 0.5`, shoulders below the head, head fully inside the canvas, head/shoulder boxes overlapping), every catalogue option paints in both schemes, out-of-range indices degrade instead of throwing, `shouldRepaint` is correct, and a **pixel probe** asserts the background is still visible on at least three margins — the direct signature of the old face-filling composition. Plus `should_not_default_to_the_smiley_glyph` in `avatar_config_test.dart` guarding `initial`.
  - ✅ **UI**: `ProfilePage` (guest badge, identity card, avatar row → editor, name row → rename dialog) and `AvatarEditorPage` (160 px preview, one horizontal swatch strip per `AvatarPart`, shuffle from `avatarRandomProvider`, save-then-pop). Entry point: an avatar row in Settings → About, routing to `/profile`.
  - ✅ **Routes**: `AppRoutes.profile` = `/profile` (inside the shell) with a nested `avatar` sub-route, so the back stack reads Profile → Avatar and the editor cannot be deep-linked with nothing to pop to. The dead `enum AppDestination` duplicate in `app_routes.dart` was removed.
  - ✅ **`AppStrings.fill(context, key, values)`** added to `lib/core/presentation/app_strings.dart` — the bridge from the key-based lookup to the two ARB keys that carry placeholders (`avatarEditorOptionLabel`, `avatarEditorPartSelected`), so no call site concatenates a sentence.
  - ✅ ARB: 26 new keys in en/my/ja with real Burmese and Japanese values; `l10n_untranslated.json` = `{}`.
  - ✅ Tests: 23 `AvatarConfig`/`AvatarCatalog` cases (including 200 seeded `random` draws all valid, and 500 draws reaching every option of every part), 20 use-case cases, 13 datasource cases, and a page suite that paints **every** option of **every** part and asserts no exception. All type-check via the kernel loop; the DB and widget suites execute on the device/CI harness.
  - ⏳ **On-device verification still to do.** The build could not run from the agent's process tree (the pipe ceiling below was still in force at the end of the session — a bare `Process.run(['cmd.exe','/c','echo','hi'])` probe still failed). Run this from your own terminal:
    ```sh
    ./tool/build_dev_apk.sh                        # build + install + launch
    # or, to land directly on the profile page:
    #   add -Pdart-defines=<base64 of INITIAL_ROUTE=/profile> to the gradlew line
    ```
    What to check: Settings → the **avatar row** opens Profile; the avatar renders at 96 px; the name row opens the rename dialog and the name **persists across a relaunch**; the avatar row opens the editor; **Shuffle** changes the preview; picking a swatch changes it live; **Save** pops back and the new avatar is on Profile; then pull the DB and confirm the two rows:
    ```sh
    adb exec-out "run-as com.yk.ledgerly.dev cat app_flutter/ledgerly.sqlite" > /tmp/l.sqlite
    sqlite3 /tmp/l.sqlite "select key, value from app_settings where key like 'profile%'"
    ```
- ☑ **Avatar v2 — Open Peeps art** (`docs/Avatar.md`; CC0 art via the DiceBear `open-peeps` definition; supersedes the procedural renderer above). Do **in order**, one PR each:
  - ☑ 0. **Layout fix:** avatar editor is a full-screen route **outside the shell** (no bottom nav); Save never covered by nav/gesture bar; preview not clipped by the header; widget test asserts Save is hit-testable at 360/768/1440 × text scale 1.0/2.0. — done: editor moved to a top-level `/profile/avatar` route out of the `ShellRoute`; Save pinned in a `_SaveBar` footer inside the page `SafeArea` (clears system gesture area); preview top spacing added (`AppSpacing.xl`) so it clears the header at text scale 2.0; `avatar_editor_layout_test.dart` asserts zero overflow + Save hit-testable across 360/768/1440 × 1.0/2.0.
  - ☑ 1. **Spike (no UI):** inspect the DiceBear `open-peeps` definition JSON; verify CC0 on `dicebear.com/licenses` (record the date in `docs/Versions.md`); fill `Avatar.md` §9 with the real component groups, counts, color groups, canvas size, whether "Top" exists as a swappable part, mask usage. — done: definition inspected (`open-peeps.json`, 704×704 canvas); **CC0 1.0 verified 12 Oct 2026** and recorded in `Versions.md`; `Avatar.md` §9 filled — real groups `head`(48) · `expression`(30, *not* "face") · `facialHair`(16) · `accessories`(8) · `mask`(2); colors `skin`(5) · `clothing`(7) · `headContrast`(=hair, 10) · `ink`(1); torso is baked into the canvas so **no "Top"/body group exists** (outfit = color only); mask kept in the manifest but not exposed as a tab.
  - ☑ 2. `tool/avatar/extract_open_peeps.dart` → committed `assets/avatar/open_peeps/**` (+ `manifest.json`, `LICENSE.txt`); deterministic; extractor tests (no missing files, no unknown color tokens). — done: extractor + committed `tool/avatar/source/open-peeps.json` produce 104 part SVGs (head 48 · expression 30 · facial_hair 16 · accessories 8 · mask 2) + `base/body.svg` + `manifest.json` (ids, per-group size/transform, layer order, colour tokens) + `LICENSE.txt` (CC0 1.0); tokens `@skin/@clothing/@hair/@ink` (unknown colours fail the tool), ids = snake_case of source keys; `test/tool/avatar/extract_open_peeps_test.dart` covers counts, orphans, XML, token purity, determinism.
  - ☑ 3. **Domain/data:** `AvatarConfig` by **ids, not indices** (JSON under the existing `profile.avatar` settings key, no migration; unknown/old `"a-b-c-d-e"` values decode to `initial`), manifest-backed `AvatarCatalog`, curated palettes, `flutter_svg` composer + LRU cache (add to `docs/Versions.md` with the resolved version and justification). — done: `AvatarColors` + `AvatarPalette` (8 backgrounds · 4 inks · 10 hairs · 7 skins · 10 outfits); `AvatarConfig` by component IDs (`headId`, `faceId`, `accessoryId`, `facialHairId`, `maskId`, `itemId`) with backward-compatible legacy decode and fallback; `AvatarCatalog` backed by the 104 extracted Open Peeps parts with weighted random generator; `AvatarSvgComposer` with ≤32 entries LRU cache + SVG string assembling; `Avatar` widget updated with `flutter_svg: ^2.3.0` and clipping; pinned in `docs/Versions.md`; 1056/1056 tests passing.
  - ☑ 4. **Editor UI:** pinned circular preview, Generate randomly, tabs Head · Face · Glasses · Item · Colors (Background / Outline / Hair / Skin tone / Outfit), responsive two-pane at medium+, empty *Item* tab ("coming soon" — no fake items), loading/error states, haptics. — done: full-screen `AvatarEditorPage` route with 160 px circular live preview + "Shuffle" button (`AppFeedback.selection`); 5-tab bar (Head 48 · Face 30 expressions + 16 facial hairs with "none" tile via CustomScrollView slivers · Glasses 8 accessories with "none" tile · Item "none" tile + "More items coming soon" empty state · Colors swatch rings for Background 8 / Outline 4 / Hair 10 / Skin tone 7 / Outfit 10); responsive branching via `TwoPaneLayout` (stacked on compact, side-by-side preview and tabs on medium+); unsaved changes discard confirmation dialog (`PopScope` + close icon); pinned `_SaveBar` in `SafeArea`; full l10n (en/my/ja); 1060/1060 tests green with zero analyzer warnings.
  - ☑ 5. Tests + goldens (circle/squircle, light/dark); **Settings → Credits** entry: "Avatar art: Open Peeps by Pablo Stanley (CC0 1.0), via DiceBear"; memory check (open/close editor ×10 in `--profile`, no growth). — done: Settings → Credits entry and dialog ("Avatar art: Open Peeps by Pablo Stanley (CC0 1.0), via DiceBear") with en/my/ja l10n; avatar golden tests in circle and squircle across light and dark themes with cross-platform tolerant comparator (`avatar_golden_test.dart`); 10x editor open/close lifecycle and bounded cache memory test (`avatar_editor_memory_test.dart`); 1066/1066 tests passing with zero analyzer warnings.
  - ☐ Later (v2.1): original item art (cat, sprout, headband…) for the *Item* tab, same color-token scheme.
- ☑ **Responsive layouts (compact/medium/expanded) for Calendar, Forms, Categories, Settings** — built; on-device verification pending (see below).
  - ✅ **Shared primitives** (`lib/features/shared/presentation/widgets/responsive_layout.dart`): `TwoPaneLayout` (stacks below medium, `Row` with a width-capped master at medium+), `ConstrainedPane` (a prose-width ceiling so a short page does not stretch to 1440 px), `ModalFormScaffold` (a real route on compact, a centred raised card over `surfaceSunken` at medium+), and `ResponsiveInsets` (`pageHorizontal` — 16 compact / 24 medium+ — plus a bottom safe-area helper).
  - ✅ **Calendar**: below medium it is one scrolling column; at medium+ `_WideBody` gives **each pane its own `ListView`** (flex 4 / 6) rather than sharing one scrollable. That distinction is the whole point — a shared scroll view would let a busy day push the month header off screen, defeating the wide layout.
  - ✅ **Categories**: a master–detail split at `usesSidebar` (`list flex 4` + `VerticalDivider` + `_DetailPane flex 6`). Tapping a row opens `CategoryFormBody` **inline in the pane** instead of pushing a route, the open row is tinted `brandSubtle` (the tint is the only cue linking row to pane, so it is a real surface change), and deleting/archiving the shown category closes the pane. The form body was extracted to a public widget so the same code renders as a route on compact and as a pane on wide — no forked form.
  - ✅ **Settings** and the **transaction form** are both wrapped in `ConstrainedPane`, so a desktop window shows a readable column instead of edge-to-edge rows.
  - ✅ ARB: `categoriesSelectHint` (the detail-pane placeholder) in en/my/ja; `l10n_untranslated.json` = `{}`.
  - ✅ Tests: `responsive_layout_test.dart` (stack-vs-row, width caps, the modal-card branch, insets) plus `category_list_page_test.dart`, `calendar_page_test.dart` and `settings_page_responsive_test.dart`, each walking **every mandated width (360/390/430/768/1024/1440)** at text scale **1.0 and 2.0** and asserting `takeException()` is null. All type-check via the kernel loop.
  - ⏳ **On-device verification still to do** — same pipe ceiling as the Profile item above. From your own terminal: `./tool/build_dev_apk.sh`, then rotate the emulator to landscape (the sidebar layout) and check Calendar shows two panes, Categories edits inline, and nothing overflows at any width.
- ☑ **Empty/loading/error states, haptics, undo** — built; on-device verification pending.
  - ✅ `StatePlaceholder` / `LoadingPlaceholder` / `ErrorBanner` (`features/shared/presentation/widgets/state_placeholder.dart`) are the single treatment for the three "nothing to show" states, wired into the calendar day list, the categories list and the pickers.
  - ✅ **`AppFeedback`** (`features/shared/presentation/feedback/app_feedback.dart`) — the one place for transient feedback. `selection`/`success`/`destructive` map to `HapticFeedback.{selectionClick,lightImpact,mediumImpact}`, so a destructive action *feels* different from a selection before the message is read. `confirm` = 2 s, `failure` = 4 s (longer — the user may have to act on it), `undoable` = **5 s** (undo is a *recovery* action: notice, decide, reach — 2 s would make it decorative). Every path clears the previous bar first, so a burst of edits shows the latest result instead of a lagging queue, and `ScaffoldMessenger.maybeOf` makes feedback outside a `Scaffold` a no-op rather than a crash.
  - ✅ **Undo is real, not a re-create.** `restore` was added through every layer — `CategoriesDao.restore` → `CategoryLocalDataSource.restore` → `CategoryRepository.restore` → `CategoryRepositoryImpl.restore` → the **`RestoreCategory`** use case → `restoreCategoryProvider` → DI. The original id and `createdAt` survive, so transactions that referenced the category still resolve; a re-create would mint a new id and orphan that history. `restore` is deliberately **not** scoped by `deletedAt IS NOT NULL` — restoring a live row writes the same value, so a double-tap on Undo cannot corrupt anything.
  - ✅ Wired into categories (delete → destructive haptic → undoable bar → restore), the transaction form (success haptic + confirmation on the **transition** into `saved`, guarded with `!(previous?.saved ?? false)` so a re-layout cannot buzz twice) and Settings.
  - ✅ ARB: `categoriesDeleted` in en/my/ja; `l10n_untranslated.json` = `{}`.
  - ✅ Tests: `app_feedback_test.dart` (replace-don't-queue, the three durations, the no-messenger no-op, and haptics captured through a mock `SystemChannels.platform` handler — a fire-and-forget platform call is otherwise indistinguishable from a no-op), a `RestoreCategory` group in the use-case suite, and four round-trip cases in the category data suite.
  - ⏳ **On-device verification still to do** — same pipe ceiling. Check that deleting a category shows the Undo bar for a full 5 s and that Undo brings the row back with its transactions intact.
- ☑ **Memory profiling pass + accessibility pass** — built and verified.
  - ✅ **Accessibility (a11y)**: Interactive controls and navigation rows expose `Semantics(button: true)`. Calendar day cells expose selected state and accessible day labels. `MonthStartsOnPage` chips expose explicit button semantics and `isSelected`. Tap targets satisfy iOS 44x44 minimum touch guidelines (`iOSTapTargetGuideline`). Tooltips configured for calendar month picker (`calendarPickMonth`).
  - ✅ **Memory & Lifecycle**: Bounded LRU cache verification (Avatar editor 10x open/close ≤ 32 cache limit). Navigating push/pop across screens 10x and viewport rotation across portrait/landscape 10x produces zero memory leaks, disposed controller errors, or unhandled exceptions.
  - ✅ Tests: `test/core/accessibility/accessibility_test.dart` and `test/core/memory/screen_lifecycle_memory_test.dart` passing 100%.
- ☐ **Milestone: TestFlight/internal build**
- ☑ **`AdaptiveNav`** — **built and verified on `emulator-5554`.** The glass tab bar / M3 `NavigationBar` / rail / sidebar are all in place: `NavDestination` (the single source of truth for the four destinations and their route matcher), `GlassSurface`/`FloatingGlassBar`/`DockedBottomBar`, `AdaptiveNav` (compact → M3 bar on Android/web, floating glass bar on iOS; medium → `NavigationRail`; expanded/large → 240 px sidebar), and `AppShell` (mounted from the router's `ShellRoute`; also raises the bottom `MediaQuery` padding so content is never hidden behind the bar). `_PlaceholderShell` is gone and `_PlaceholderPage` now renders the shared coming-soon state.
  - Size class beats platform: a wide Android tablet gets the same sidebar as an iPad (`docs/Platform.md` §2 rule 4).
  - On-device: all four destinations navigate by tapping, the active pill follows, the landscape window switches to the sidebar, and logcat shows no `overflow`/`RenderFlex` across the whole run.
  - `--dart-define=INITIAL_ROUTE=/settings` still starts a dev build on a specific route (`AppEnvironment.initialRouteFromDartDefine`, ignored in prod) — useful for screenshotting a page directly.
- ⚠ **`flutter run` cannot find the APK when a flavor is configured.** The Gradle build *succeeds*, but AGP writes to `build/app/outputs/apk/<flavor>/<buildType>/` and the tool does not resolve that for `dev`/`prod`, so it reports *"Gradle build failed to produce an .apk file"* even though `build/app/outputs/flutter-apk/app-dev-debug.apk` is freshly written. Until that is fixed, build and install in two steps:
  ```sh
  flutter build apk --debug --flavor dev --target-platform android-x64   # or ./tool/build_dev_apk.sh
  adb install -r build/app/outputs/flutter-apk/app-dev-debug.apk
  ```
  Launch with `com.yk.ledgerly.dev/com.yk.ledgerly.MainActivity` — the package carries the `.dev` suffix but the **activity class does not** (it is the `namespace`).
- ℹ **On this dev box, `flutter run` / `flutter build` can be blocked by OS-level named-pipe exhaustion** (`CreateFile failed 231 (All pipe instances are busy.)`) — `CreateNamedPipeW` runs out of instances machine-wide, so the tool cannot spawn its first child process. Proved with a bare `Process.run` probe that fails even outside the sandbox and after `adb kill-server`. Unrelated to the project. Run the build from a terminal outside the agent's process tree, or reboot to reset the pipe instance table.
  - Shortcut while the localizations are already generated: temporarily `mv l10n.yaml .l10n.yaml.buildskip` so the build skips the `gen_localizations` target (which spawns `dart format`), then move it back.
  - After a failed attempt, `rm -rf .dart_tool/flutter_build` — the abandoned `--incremental --initialize-from-dill` step leaves a 0-byte `app.dill` that breaks the next run.
- ✅ **`WatchDayTotal` use case** — a day-level income/expense/net aggregate, so the calendar summary card can show the selected day rather than the month. Built alongside the calendar summary card with `TransactionsDao.sumForDay`, repository methods, and `watchDayTotalProvider`.

## Phase 2 — "Understand & Account" (v0.2) — IN PROGRESS

- ☑ **Insights & Financial Analytics** — Donut chart, income vs expense bar chart, cash flow trend line chart, and top categories breakdown cards by `BudgetPeriod`; period switcher, comparison deltas ("previous period" delta using `PeriodCalculator.previous`), responsive 1 → 2 → 3 column grid layouts, SQL aggregations.
- ☑ **Firebase Auth / Account architecture & flow**:
  - ✅ **Domain layer** (`lib/features/auth/domain/`): Pure Dart `AuthUser` & `AuthProviderType` entities, `AuthRepository` interface, 10 use cases (`WatchAuthState`, `GetCurrentUser`, `SignInAnonymously`, `SignInWithGoogle`, `SignInWithApple`, `SignInWithEmail`, `SignUpWithEmail`, `LinkAccount`, `SignOut`, `DeleteAccount`).
  - ✅ **Data layer** (`lib/features/auth/data/`): `AuthLocalDataSource` (persisting user session to `AppSettingsDao`), `AuthRemoteDataSource` contract & `NoopAuthRemoteDataSource` adapter, `AuthRepositoryImpl`.
  - ✅ **Presentation & State** (`lib/features/auth/presentation/`): `AuthNotifier` with Riverpod 3 purity, `authNotifierProvider`, `currentUserProvider`, `isAuthenticatedProvider`, `isGuestProvider`, fallback resilience for isolated widget tests without GetIt registration.
  - ✅ **UI Pages**:
    - `WelcomePage` (`/welcome`): Branding hero, first-run **"When does your month start?"** onboarding picker with live period preview, Continue as Guest, Apple, Google, and Email sign in buttons.
    - `SignInPage` (`/sign-in`): Email/Password authentication form with validation, toggle between Sign In and Create Account, Apple & Google sign in shortcuts.
    - `AccountPage` (`/settings/account`): User profile display, Guest Account badge, guest-to-account linking banner, Sign out confirmation modal, and store-compliant Delete Account destructive action modal.
  - ✅ **Routing & Navigation**: `/welcome` and `/sign-in` registered as full-screen routes outside shell; `/settings/account` accessible via Settings and Profile; Settings and Profile account rows show live user/guest status.
  - ✅ **Localization**: 32 new strings across `app_en.arb`, `app_my.arb`, and `app_ja.arb`.
  - ✅ **Tests**: 12 domain use case tests, 8 repository data tests, 10 notifier tests, and 4 page widget tests (all passing, 100% green).
- ☑ **Guest → account linking + merge prompt**:
  - ✅ Account linking implemented via `LinkAccount` use case and UI banner in `AccountPage` to link anonymous guest accounts to permanent Google, Apple, or Email credentials without losing local budget history.
- ☑ **Transactions list page: search, filters, paging** — Debounced search (notes & categories), filter chips (direction, category picker, date range picker, min/max amount range), modal filter bottom sheet (`TransactionFilterSheet`), infinite scrolling paging (`TransactionsListNotifier`), swipe-to-delete with undo bar, tap-to-edit, responsive layout, accessible semantics. Covered by unit and widget test suites.
- ☑ **Export CSV/JSON (+ clipboard/share)**:
  - Range presets ("this period", "last period", "all time", "custom") computed via `PeriodCalculator` and `BudgetPeriod`.
  - Pure Dart RFC 4180 CSV codec and JSON exporter formatting transactions with date, category, amount, currency, direction, and notes.
  - Export preview summary showing transaction count, total income, and total expense.
  - Clipboard copy and export feedback via `AppFeedback.confirm`.
- ☑ **Import CSV/JSON with column mapping, preview, deduplication**:
  - RFC 4180 compliant CSV parser and JSON parser handling commas, quotes, and multiline text.
  - Interactive column mapping preview with column type selectors (Date, Category, Amount, Currency, Direction, Note).
  - In-memory signature-based deduplication engine (`DeduplicationEngine`) detecting existing transactions.
  - Import options: skip duplicates, auto-create missing categories.
  - Detailed import result reporting rows imported, duplicates skipped, and categories created.
- ☑ **Full Backup & Restore**:
  - Schema-versioned full JSON archive encoding categories, transactions, and user app settings.
  - Backup metadata extraction (version, timestamp, record counts) for safe preview before restoring.
  - Two restore modes: Merge (safely adds missing categories and non-duplicate transactions) and Overwrite (atomically wipes and replaces all categories, transactions, and settings).
  - Hub UI page at `/settings/data-transfer` (`DataTransferPage`) with responsive layout, SegmentedTabs switching, 38 localized strings in en/my/ja, Riverpod 3 purity, and 19 passing tests.

## Phase 3 — "Manage" (v0.3) — COMPLETE (100% Shipped & CI Verified)

- ☑ **Accounts + transfers**:
  - Drift schema v2 migration with `Accounts` table, `idx_accounts_active`, and soft delete.
  - Multi-account support (Cash, Bank, Credit Card, Savings, E-Wallet) with custom icons, colors, opening balances, and net worth inclusion toggles.
  - Net Worth calculation card (`NetWorthCard`) aggregating non-archived included accounts.
  - Account-to-account atomic transfers with automatic double-entry transaction generation.
  - Active and Archived tabs, drag-and-drop reordering, and transfer dialog.
- ☑ **Budgets (category + total) with progress and alerts**:
  - Drift schema v3 migration with `Budgets` table keyed by period id (`yyyy-MM`).
  - Overall monthly budget and per-category budget support with alert threshold percentages (e.g., 80%).
  - Real-time budget progress bar (`BudgetProgressBar`) tracking spent amount, remaining amount, and daily suggested spend.
  - Active and Archived tabs, filter tabs, and responsive UI with full localization in en/my/ja.
- ☑ **Recurring transactions (scheduler on app open + local notifications)**:
  - Drift schema v4 migration with `RecurringTransactions` table and indexing.
  - Daily, weekly, monthly, and yearly recurrences with optional end dates and auto-add toggle.
  - `RecurringProcessor` engine automatically processing due transactions on app start with pending confirmation banner (`RecurringPendingBanner`).
  - Active and Paused tabs, skip occurrence, pause/resume, and instant manual execution.
- ☑ **Savings goals & target tracking**:
  - Drift schema v5 migration with `SavingsGoals` table and `idx_savings_goals_list`.
  - Visual progress bar, percentage, target date countdown, overdue badges, and CategoryGem icons.
  - Quick contribution and withdrawal bottom sheet (`GoalContributionDialog`) with optional linked account selection.
  - Active, Completed, and Archived tabs with empty states and full CRUD form (`GoalFormPage`).

## Phase 3.5 — "Design debt burn-down" (v0.3.1) — COMPLETE (A + B + C)

Design compliance was drifting because nothing enforced `docs/Design.md`:
`design_tokens_test.dart` only asserts token *values*, and the `banned-imports`
CI job carries no design rules. This phase fixes that in two halves.

### A. Mechanically enforceable — COMPLETE

- ☑ **`test/core/design_rules_test.dart`** — a source-level scanner in the style
  of `test/core/layer_rule_test.dart`, enforcing seven rules with per-file
  violation budgets. Budgets are checked in **both directions**: a file over
  budget fails (new debt), and a file under budget *also* fails (stale budget).
  Debt can therefore only shrink; the baseline can never quietly turn into an
  allowlist. A nine-test `scanner self-check` group guards the regexes
  themselves.
- ☑ **`design-rules` CI job** — design drift gets its own fast, isolated signal
  instead of hiding inside the full test wall. `analyze` and `test` now depend
  on it.
- ☑ **`tool/run_test.sh`** — local `flutter test` dies on the dev machine with
  `CreateFile failed 231 (All pipe instances are busy)`, a machine-wide pipe
  limit. This compiles one test to a debug kernel and runs it under
  `flutter_tester.exe` instead. Golden and widget tests cannot be driven this
  way; every other test can. CI remains the authoritative oracle.
- ☑ **Fixed a live bug the gate caught on its first run** — `AppTheme` set
  `splashFactory: InkSparkle.splashFactory` globally, so iOS rendered an Android
  ink ripple. That is the "skinned, not native" trap `docs/Design.md` §1 forbids
  and §5.2 names explicitly. `AppTheme.light`/`dark` now take an injectable
  `AppPlatform? platform` so the factory is chosen per platform and a golden
  test can render iOS chrome on a Linux runner.

**Measured baseline when the gate first went live: 170 tolerated violations
across 7 rules.**

| Rule | Doc | Baseline | Files | Now |
| --- | --- | ---: | ---: | ---: |
| Inline `TextStyle(` in a view | §3 | 61 | 20 | **0** |
| Raw `Scaffold(` in a feature page | §5.1 | 32 | 25 | **0** |
| Off-scale radius (`BorderRadius`/`circular`) | §4.2 | 30 | 15 | **0** |
| First-paint spinner instead of skeleton | §5.11 | 21 | 16 | **0** |
| Hardcoded colour (`Color(0x…)` / `Colors.x`) | §2 | 18 | 11 | **0** |
| Sub-caption size (`fontSize` < 11) | §3 | 4 | 4 | **0** |
| Hardcoded English UI string | §7 | 4 | 3 | **0** |

These are counts of matching *lines*, which is what the scanner and its budgets
measure. They were re-derived by replaying the scanner's own scope and regexes
after an earlier hand-tallied table under-counted the multi-line budget maps.

### B. Burn the debt down — COMPLETE

All seven budgets are now `const <String, int>{}` — **zero tolerated
violations, no per-file exemptions**. The two-directional check made this a
ratchet: each commit that fixed a file also had to delete that file's stale
budget, so the baseline could only tighten.

| Commit | Item | Fixed |
| --- | --- | ---: |
| `81a2e2b` | Sub-caption sizes + hardcoded English strings | 8 |
| `55a1104` | Hardcoded colour → token | 18 |
| `09c8221` | Off-scale radius → `AppRadius` | 30 |
| `6d2273d` | Raw page `Scaffold` → `AppScaffold` | 32 |
| `aff5821` | Inline `TextStyle` → `AppTypography` | 54 |
| `ebb2948` | First-paint spinner → skeleton | 19 |

- ☑ **`inline TextStyle` → `AppTypography`** (61, 20 files). Mapping used:
  16–18 px bold → `title`, 14–15 px → `body`, 12 px → `label`, 11 px +
  `tracking: 0.8` → `overline`. Any bare `FontWeight.bold` (w700) on small text
  was demoted to at most `w600`, per §3's "nothing lighter than w500 at small
  sizes, nothing heavier than w600 below 22 px".
- ☑ **Raw `Scaffold` → `AppScaffold`** (32, 25 files). `AppScaffold` gained a
  `bottom` slot (`PreferredSizeWidget?`) so `TabBar`s stay part of the app bar
  as M3 requires; a `bottom`-only caller now still gets an app bar. The three
  files whose `Scaffold` genuinely *is* the frame (`app_shell.dart`,
  `app_router.dart`, `responsive_layout.dart`) became a named `framePaths`
  exemption list, guarded by
  `should_keep_the_exempted_page_frames` — an exemption that stops matching
  fails the suite, so the list cannot silently rot.
- ☑ **Off-scale radius → `AppRadius`** (30, 15 files). Added `AppRadius.radiusSm`
  as the single-[`Radius`] sibling of the existing `radiusXl`. Making
  `borderMd` const-propagation-visible then surfaced two
  `prefer_const_constructors` hits in `account_page.dart` (CI `Analyze`), fixed
  by marking the `RoundedRectangleBorder`s `const`.
- ☑ **First-paint spinner → skeleton** (21, 16 files). New `AppSkeleton`,
  `AppSkeletonList`, `AppSkeletonCard` in `lib/core/widgets/app_skeleton.dart`
  — a 1200 ms `reverse: true` fade over `surfaceSubtle`, collapsing to a static
  block under `MediaQuery.disableAnimationsOf`. `state_placeholder.dart` was the
  leverage point as predicted: `LoadingPlaceholder` *was* a centred spinner, and
  making it a skeleton fixed eight `loading:` call sites in one file. Rule 4 was
  rewritten to **dismiss** the legitimate busy-indicator form
  (`dismiss: (line) => line.contains('strokeWidth')`, with a one-line lookahead
  because `dart format` wraps the argument onto the next line) rather than
  budget it — pinned by `should_dismiss_only_the_busy_indicator_form`.
- ☑ **Hardcoded colour → token** (18, 11 files). Two real bugs fell out:
  `budget_form_page.dart`'s `#D97706` was a second off-system amber that also
  broke in dark mode (it is the `warning` role reimplemented), and
  `data_transfer_page.dart` was using stock Material `Colors.green/orange/blue`.
- ☑ **Sub-caption size** (4) and **hardcoded string** (4). Trivial cleanups.

**Known gap left by this phase (follow-up):** Rule 2 checks radius *values*, not
token *usage*, so ~35 sites still hand-write `BorderRadius.circular(12)`,
`(20)` or `(8)` where `AppRadius.borderMd`, `borderLg` and `borderSm` already
exist. The rule permits that value-level bypass. Tightening it to require the
token at those exact values is the natural next increment.

**Known gaps left by C (follow-up):** recurring-list `Active (n)` / `Paused (n)`
labels are still hardcoded English (they dodge Rule 6 via string
interpolation) — they need `recurringActiveTab` / `recurringPausedTab` ARB keys
with a count placeholder. Insight/chart cards still hand-roll `Container` +
`BoxDecoration` (`surfaceSubtle` + `borderMd`) instead of `AppCard`.

### D. Post-3.5 compliance sweep — COMPLETE (`flutter test`: 1367 green)

The full suite carried 14 red tests at the `db5fe12` baseline (reproduced on a
`git stash` clean tree, so none came from Phase 3.5). Root causes and fixes,
one PR-shaped commit:

- ☑ **Stale icon finders (10)** — the Rule 8 vocabulary migration changed
  glyphs (`chevron_left` → `chevron_left_outlined`, …) but the tests still
  searched raw codepoints: month/year picker (4), avatar editor close (2),
  transactions search/tune (2), calendar switcher + overflow menu (2). Tests
  now find by the `AppIcons` role constants.
- ☑ **Capsule width tests (2)** — asserted `390 / 7 * 0.6`, ignoring the 16 px
  page padding `AppScaffold` wraps the grid in (30.69 px actual). Rewritten as
  a proportion of the *rendered* row (tolerance ±0.5), so padding changes can
  never break them again.
- ☑ **Auth delete dialog (1)** — the Delete row sits below the fold on a
  600 px window; the tap silently missed. Test now `scrollUntilVisible`s first.
- ☑ **Search-clear ambiguity (1)** — active search shows two close glyphs
  (field + Clear-all chip); the finder is now scoped to the `TextField`.
- ☑ **Radius token bypass (36 sites)** — `BorderRadius.circular(12/20/8)`
  hand-writes values `AppRadius.borderMd/Lg/Sm` already own. All migrated
  (plus new `radiusMd`/`radiusLg` single-`Radius` siblings); Rule 2 gained a
  token-*usage* test so the value-level bypass is closed. Bonus: 18 newly
  `const`-eligible shapes (tokens are const, literals were not).
- ☑ **Hardcoded copy (§7)** — recurring `Active/Paused (n)` tabs,
  goal `None (General Saved)` ×2, goal `Not set` + hand-built ISO date,
  recurring start/end ISO dates, sign-in `OR` divider, goals `Error: $e` dump
  (now an `ErrorBanner` with Retry) — all ARB keys / intl / spec treatment.
- ☑ **w700 demotion (21 sites)** — no token is heavier than w600; every
  `bold`/`w700` in features is now `w600` (headline sizes included — weight
  comes from size, not boldness, in this system).
- ☑ **Bespoke glows (2)** — color-swatch selection had a `BoxShadow` glow on
  top of its 3 px ring; §4.3 allows only flat/raised/floating. Ring alone now.
- ☑ **Insight/calendar/category/month heroes → `AppCard` (8)** — summary,
  donut, bar, cash-flow, top-categories, calendar summary, category preview,
  month preview, net worth. `surfaceSubtle` + `borderMd` treatments are gone;
  status borders ride the `AppCard.border` slot.

Deliberately **not** done here (judgment, recorded): replacing the Material
outlined glyph set with custom 2026 line-art — an art commission, not a code
violation (Rule 8 already pins one glyph per concept). Page-splitting lived
here too until §F did it.

### E. Whole-app Design.md + 2026 UX audit — COMPLETE (1390 green)

All three open items from the Categories review, plus a full-lib sweep:

- ☑ **Screen goldens** — `categories`, `settings`, `transactions_list`,
  `calendar` × light/dark (8 PNGs, 2% tolerant comparator). Component goldens
  already covered `AppCard`/`ListRow`/`SegmentedTabs`.
- ☑ **§5.6 separators** — category rows set `ListRow(showDivider: true)`
  (1 px hairline, 72 px inset). Other `ListRow` sites stay divider-free,
  matching their pre-existing airy treatment.
- ☑ **`AppOverflowMenu`** (`core/widgets/`) — popup on Material, Cupertino
  action sheet on iOS (`Platform.md` §2); destructive red on both. All seven
  row/card menus migrated; **Rule 12** bans raw `PopupMenuButton`. The shared
  `moreHorizontal` trigger keeps every existing icon-finder test green.
  Caught while building: popup-route children sit above `MaterialApp`, so
  `AppThemeColors.of` throws inside `itemBuilder` — colors resolve in the
  parent and pass down. Covered by Material + iOS widget tests (3).
- ☑ **Spacing literals** — `vertical: 14` → `md`, `all(3)` → `xs`,
  `left: 28` → `20 + sm` (aligns under the 20 px icon + gap it sits beside),
  `circular`-adjacent `horizontal: 8` → `sm`, `vertical: 4` → `xs`,
  `top: 2` → `xxs`, stray `6`s → `xs`. Left as documented exceptions: FAB
  clearances (80/88) and 48 px grid geometry (== `xxxl` by value, layout, not
  spacing).
- Sweep confirms: zero `BoxShadow` outside `AppElevation`, zero `TextStyle(`
  outside token definitions, zero `print(`, all copy ARB-backed (incl. the
  `Swap accounts` tooltip and ISO-date subtitles found on the way).

### F. Page splits + status bar + icon/copy correctness — COMPLETE (1394 green)

Eleven refactor commits, each green on its own tests before pushing:

- ☑ **Splits** (`Conventions.md` §1 — one public class per file, ~200 lines):
  `calendar_page` 1129→210 (`widgets/calendar/`, 8 files),
  `avatar_editor_page` 1005→212 (`widgets/avatar_editor/`, 11 files),
  `settings_page` 712→125 (sections + rows + groups, 6 files),
  `transactions_list_page` 582→290 (chips + row),
  `data_transfer_page` 588→78 (export/import/backup tabs),
  `account_form_page` 512→348 (preview + labels + pickers),
  `transaction_filter_sheet` 490→267 (4 sections),
  `welcome_page` 481→197 (hero + question + buttons),
  `category_list_page` 496→227 (body + pane + row),
  `budget_form_page` 449→243 (4 sections),
  `recurring_form_page` 444→212 (3 sections).
  Rule 9's exemption list moved with the rows (page → widget file). Still
  over ~200 by nature, not by neglect: long forms whose fields *are* the page
  (`account_form` 348, `transactions_list` 290) — splitting those further
  would scatter one form's wiring for no readability gain.
- ☑ **Status bar invisible in Light Mode** — no `SystemUiOverlayStyle` was set
  anywhere, so edge-to-edge transparent bars showed white-on-white icons.
  `AppTheme.systemOverlayStyle(brightness)` + `AppBarTheme.systemOverlayStyle`
  + a declarative `AnnotatedRegion` in `LedgerlyApp.builder` (covers AppBar-less
  pages too). Pinned by 3 tests in `design_tokens_test.dart`.
- ☑ **Category gems all identical** — seeds used Material names (`restaurant`,
  …) while the catalogue speaks semantic keys (`food`, …); 10/11 rows fell
  back to the tag glyph. Seeds → canonical keys; `iconFor` heals the 10 legacy
  Material names (existing installs + old backups, no migration); `seed_test`
  asserts vocabulary membership + glyph distinctness, `category_catalog_test`
  pins aliases + fallback (7 tests).
- ☑ **CategoryRow → ListRow** (§5.6: 64/76 heights, lg/md padding, press wash;
  measured 72/76 — the 72 is the 48 px menu button + padding, §5.7 wins over
  the 64 figure, recorded) + `showDivider` separators.
- ☑ **Silent-lookup wildcard killed** — `_resolve`'s `_ => failureValidation`
  rendered "Please check the highlighted fields." for every key added without a
  case (goal dropdown + date subtitle on first paint, among others). Unknown
  keys now **throw** (matching `fill()` + the doc comment's own claim); the
  throw immediately surfaced 4 more pre-existing gaps (`cancel`/`delete`/
  `save`/`accountsDelete` → `action*`/`accountDeleteTitle`) plus 3 hardcoded
  auth fallbacks (now ARB keys). New `app_strings_test.dart` (4 tests) pins
  resolve + throw + fill.
- ☑ **Goal form icons/colors** — `_kGoalIcons` had 6/8 non-vocabulary keys
  (same tag-everywhere bug) → canonical 8; `_kGoalColors` hardcoded hex →
  shared `CategoryPalette`; goal legacy aliases added (6).
- ☑ **Import format switch was a no-op** — `onChanged` re-applied the current
  options, ignoring the tapped format. `ImportNotifier.setFormat` + notifier
  test.
- ☑ **`transfer_page` 407→244** (`widgets/transfer/`: selectors + details;
  also fixed `Swap accounts` tooltip, ISO date → intl, raw-minor balances →
  `MoneyFormatter`) + **`accountsTransferSwap`** ARB key.
- ☑ **Lookup coverage guard** — the wildcard kill exposed a systematic hole:
  nothing asserted ARB↔lookup parity. New test reads `app_en.arb` and requires
  every key to appear as a case in `app_strings.dart`; it immediately caught
  2 more gaps (`accountLinkFailed/Success`). Pre-existing phantom keys
  (`cancel`/`delete`/`save`/`accountsDelete`, never in any ARB) migrated to
  `action*` keys; hardcoded auth fallbacks → ARB; dead `recurringNextDue` key
  removed. Also fixed: missing `recurringProcessedSuccess` fill case (would
  have thrown at runtime on scheduler runs).

### G. Remaining work (honest list, ordered)

1. **Phase 4 Sync (v0.4)** — still NOT STARTED: outbox + `RemoteStore`
   contract tests + Firebase adapter, sync status UI, merge-on-first-login,
   app lock, widget, web release, Supabase proof.
   **The backend blocker is cleared — `docs/Backend.md` is written (16 Oct
   2026).** It carries an audit, the 11 constraints the backend must satisfy,
   the three options, a weighted decision matrix, a recommendation and the
   backend-agnostic `RemoteStore`/outbox/cursor design, plus 5 open questions.
   **Awaiting the owner's ratification of its §6 before any Phase 4 code.**
   - ⚠ **This item previously contained a false claim, now corrected:** it said
     "`firebase_auth` already ships (§Phase 2 Auth), so Firebase is the only one
     with code in the tree." **It does not ship.** `pubspec.yaml` has no backend
     package whatsoever — no `firebase_core`, `firebase_auth`, `cloud_firestore`,
     `supabase_flutter`, not even `dio`. `lib/core/network/` is a lone
     `.gitkeep`, `lib/features/sync/` is 14 of them, and the only
     `AuthRemoteDataSource` bound in DI is `NoopAuthRemoteDataSource` — a local
     fake that fabricates users from `DateTime.now()` and never opens a socket.
     The backend choice is therefore **genuinely green-field**; the case for
     Firebase is *documentation* continuity (`Agent.md` §4, `Platform.md` §6),
     not code continuity.
   - The "§3.14" this item used to point at is not a rule in `Agent.md` (rule 14
     is about packages). The constraint that *is* recorded is `Agent.md` §3.2 —
     "backend is a plug-in": UI/domain only see repository interfaces, and remote
     providers live behind `RemoteDataSource` in `data/`.
2. **Remaining splits — DONE.** All pages now ≤ 348 lines:
  `transfer_page` 407→244, `profile_page` 412→76, `transaction_form_page`
  397→262, `goal_form_page` 384→206, `category_form_page` 395→49,
  `account_page` (auth) 350→163, `sign_in_page` 318→115, `insights_page`
  285→85, `month_starts_on_page` 286→114, `goal_card` 338→139,
  `goal_contribution_dialog` 346→232. Longest survivor is `account_form_page`
  (348) — a 7-field form whose fields *are* the page. Found on the way and
  fixed: `Swap accounts` tooltip, `Guest User`/`User` names, auth fallbacks,
  goal amount errors (`goalAmountRequired` + mode-correct invalid keys),
  ISO-date subtitles → intl, raw-minor balances → `MoneyFormatter`, dead
  `recurringNextDue` key removed, and an ARB↔lookup **coverage guard** so a
  key without a case can never ship silently again. Deliberately excluded
  (unchanged): generated code, `app_strings` (registry),
  `money`/`money_formatter`, DAOs/datasources/providers (cohesive data
  layer), `app_theme`/`app_router`/`adaptive_nav`/`amount_keypad` (cohesive
  components), `avatar_catalog` (data table).
3. **Screen goldens for the rest — DONE** (see §H). Every screen is now pinned
   at `TestWidths.phone × 900`, light + dark: the four in §E plus accounts,
   budgets, goals, recurring, insights, data_transfer, welcome, sign-in and
   account. The only thing deliberately unpinned is `AppScaffold`
   (viewport-dependent). Seven of the nine new files were **not actually
   testing what they claimed** — see §H.
4. **Custom 2026 icon set** — art commission (see §D note). Code is ready:
   one glyph per concept (Rule 8), keys are semantic so the set swaps without
   a data migration.
5. **Design.md verdict today** — tokens, radius, type, cards, segments,
   rows+separators, splash, skeleton, copy, calendar spec: enforced by Rules
   1–12, suite **1437 green** (and green *locally*, not only on CI — §H.1), with
   every screen now walked at all six mandated widths × two text scales (§I).
   Known accepted deviations: menu-row height 72 vs
   64 (§5.7 wins), `TabBar` page tabs + `FilterChip` multi-filters +
   `SwitchListTile` kept as distinct components, 3 AppScaffold-exempt frame
   files (guarded), FAB clearances + 48 px grid geometry as documented
   non-token values, `AppScaffold` excluded from goldens (viewport-dependent).
6. **Two more doc-map entries point at files that do not exist.** `Agent.md` §2
   and `docs/README.md` items 2 and 8 list **`docs/Product.md`** and
   **`docs/Auth.md`**, neither of which was ever written — the same defect
   `docs/Backend.md` was written to fix (see §G.1). Decide per file: write it, or
   drop it from the index. `Auth.md` matters more than it looks: Phase 4's
   merge-on-first-login and account-deletion flows (and the store compliance in
   `Platform.md` §7) currently have no written spec.
7. **`AvatarPainter` was dead code — DELETED (16 Oct 2026).** Nothing in `lib/`
   constructed it; only its own test referenced it. `Avatar` — the widget
   actually in use — renders through `flutter_svg` + `AvatarSvgComposer`, which
   `docs/Avatar.md` §5 declares as *the* renderer. `Avatar.md` never names the
   painter, and its status line says v2 "**replaces the procedural robot-face
   avatar (background/backdrop/shape/eyes/mouth)**" — which is precisely the
   painter's part list. So it was not a fallback; it was the superseded v1.
   Removed: `avatar_painter.dart` (390 lines), `avatar_painter_test.dart`
   (270 lines), and — found on the way — `presentation/widgets/avatar_palette.dart`
   (85 lines), a **second** class also named `AvatarPalette` that only the
   painter imported. It held the `Color` tints (`headFor`/`rimFor`/`inkFor`/
   `eyeHighlightFor`) and was distinct from `domain/entities/avatar_palette.dart`,
   which holds the curated `0xFFRRGGBB` ints and is still used by the catalog,
   the config, the editor's colour tab and the design-rule guard. 745 lines
   gone, all recoverable from git history.
   - `test/core/design_rules_test.dart` had a Rule 1 exemption pointing at the
     deleted presentation palette. It is retargeted to the domain palette and
     the now-unnecessary `include:` filter is dropped: the domain file holds
     bare ints, so `\bColor\(0x` never matched it anyway. Its guard test's
     assertion moved from `Color(0x` to `0xFF` to match. That guard is the only
     thing protecting the curated set, because a regex that cannot see a file
     cannot defend it.

### H. Screen goldens completed + five real bugs the work exposed (16 Oct 2026)

The nine remaining screen goldens were "done" but three separate defects meant
most of them were asserting the wrong thing. Fixing that turned up five genuine
product bugs. `flutter test`: **1437 green**; `flutter analyze`: 0 issues.

1. **The local toolchain was never broken — the shell proxy was.** `flutter
   test` died on *every* file with `WebSocketException: Invalid WebSocket
   upgrade request`, which read like a Flutter/tooling bug. It was
   `http_proxy`/`https_proxy`: the tool talks to `flutter_tester` over a
   localhost WebSocket and the Dart HTTP client routed it through the proxy.
   `env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY flutter test`
   runs the whole suite — **goldens included**, which `tool/run_test.sh` cannot
   drive. The golden suite had therefore never run locally before this. Recorded
   in `docs/Versions.md`.
2. **Seven of the nine new goldens pinned the wrong screen.** `goals`,
   `recurring`, `insights`, `data_transfer`, `welcome`, `sign-in` and `account`
   all passed `overrides: <Override>[]`, so each page resolved against
   unregistered DI and painted its **error banner** — `goals_light.png` was
   95 % `warningSubtle`. They also passed no `size` (so 800×600, not the phone
   width) and no `brightness`, so **every "dark" PNG was byte-identical to its
   light twin** (verified by hash). All seven now seed real fixtures and render
   light *and* dark; every light/dark pair now differs.
3. **Real overflow bugs, found only because the goldens finally rendered real
   data at phone width.** All were `RenderFlex overflowed` at 390 px:
   - `goal_card/progress.dart` — 126 px. Fixed with `Flexible` + ellipsis.
   - `budget_summary_card.dart` — 34 px (header row) and **296 px**
     (`spent / limit`). The 296 is structural: MMK/JPY are zero-decimal, so
     both sides are 7-digit numbers, and a 28 px hero plus a 17 px secondary
     cannot share 326 px. Both sides now flex.
   - `budget_category_row.dart` — **351 px** (the `spent / limit` column, already
     narrowed by the gem, status pill and overflow menu) and its bottom row.
   The budgets fixture was also unrealistic (100,000,000 Ks ≈ USD 48,000 for a
   *monthly* budget); it now uses 1,500,000 Ks / 400,000 Ks so the golden shows
   what a user actually sees.
4. **`goalRemaining` was fed raw minor units.** `progress.dart` passed
   `'${goal.remainingAmount.amountMinor}'` into an ARB message that expects a
   *formatted* amount, so a goal needing 2,000,000 Ks rendered
   `2000000 remaining` — no grouping, no currency. Now goes through
   `MoneyFormatter`, the same fix §D applied to the transfer page.
5. **The tolerant golden comparator was copy-pasted 15 times** (two naming
   variants, private and public). Extracted to
   `test/support/tolerant_golden.dart` + `useTolerantGoldens()`; every golden
   installs it from `setUpAll`, so a new golden file cannot silently opt into
   exact matching and fail on CI's Linux rasterizer.

**Also recorded, not fixed (judgment calls for the owner):**

- **`AvatarPainter` is dead code.** Nothing in `lib/` references it — the
  Open Peeps SVG composer replaced it (§"Avatar v2"). Only
  `avatar_painter_test.dart` keeps it alive, so 12 passing tests assert
  constants of a renderer that no longer ships. Either delete both or say it is
  the v2.1 reference.
- **The avatar goldens' light/dark split is vacuous.** `avatar_circle_light.png`
  and `avatar_circle_dark.png` are byte-identical, and legitimately so: Open
  Peeps colours come from `AvatarConfig.colors` (user data), not the theme, and
  `AvatarSvgComposer.compose` takes no `Brightness`. The test's real coverage is
  circle vs squircle; the theme axis asserts nothing.
- **Seven screens had no responsive width walk — DONE, see §I.** Only
  `categories`, `settings`, `calendar` and the shared layout walk
  360/390/430/768/1024/1440 × text scale 1.0/2.0 and assert `takeException()`
  is null. `accounts`, `budgets`, `goals`, `recurring`, `insights`,
  `data_transfer` and `auth` did not — which is exactly why the §H.3 overflows
  survived. All nine now do, and the walks found eleven more overflows the
  goldens could not see.

### I. Responsive width walks for every screen — DONE (16 Oct 2026)

`test/support/width_walk.dart` registers the `every mandated width` group for a
page: it pumps the page at 360 / 390 / 430 / 768 / 1024 / 1440 px, at text scale
1.0 **and** 2.0, checks three frames per width, and asserts `takeException()` is
null. It generalises the inline walk `calendar_page_test.dart` already had, and is
now wired into all nine screens that lacked one (`accounts`, `budgets`, `goals`,
`recurring`, `insights`, `data_transfer`, `welcome`, `sign-in`, `account`).
`flutter test`: **1437 green**; `flutter analyze`: 0 issues.

**It found eleven overflow sites immediately**, every one of them at 360 px with
text scale 2.0 — a configuration no golden covered:

| Screen | Widget | Overflow |
|---|---|---|
| insights | `donut_chart_card` legend chip | up to 223 px |
| insights | `top_categories_card` row | up to 144 px |
| insights | `income_expense_bar_chart_card` legend | 0.5 px |
| accounts | `net_worth_card` header | up to 147 px |
| accounts | `account_card` balance | up to 109 px |
| budgets | `budgets_page` section heading | up to 219 px |
| budgets | `budget_category_row` amounts + ` / ` separator | 33 / 36 px |
| budgets | `budget_status_pill` label | 21 px |
| recurring | `recurring_item_card` amount | 21 px |
| welcome | app bar `Skip for now` action | 27 px |
| data_transfer | `AppButton` label | up to 127 px |

The mechanism is the same everywhere: `flutter_test`'s placeholder font advances
each glyph by exactly the font size, so at 2× every string doubles — `Category
Budget` at `titleMedium` is 480 px on a 360 px screen. Each site now yields
(`Flexible` / `Expanded` + `maxLines: 1` + ellipsis, tokens only), except where
noted below.

Two causes are worth keeping, because neither is obvious:

1. **`AppBar` measures its actions with an unbounded main axis.** `actions` go
   straight into a `Row(mainAxisSize: min)`, and a `Row` lays its non-flex
   children out unbounded — so `Skip for now` is measured at its full ~384 px and
   overflows the 360 px toolbar instead of ellipsizing. Flutter clamps the *title*
   to 1.34× text scale but does not clamp actions. Fix: wrap the action in
   `Flexible` and ellipsize its label. `AppScaffold.actions` now documents this.
2. **A `Flexible` in an unbounded `Row` does not collapse.** `RenderFlex` only
   allocates space to flexible children when the main axis is bounded (`canFlex`),
   and otherwise lays them out exactly as if they were non-flex. This matters
   because `AppButton` and `BudgetStatusPill` are both used as non-flex children
   of a `Row` (`data_transfer/widgets/import_tab.dart`, `budget_summary_card.dart`)
   — a first attempt at the fix assumed the label would be given `maxWidth: 0`
   and silently vanish, and rewrote both as `Wrap`s. It would not have. Both keep
   the simpler `Flexible`.

**Two coverage limits, recorded because they are how these survived:**

- **The walk sees only what gets laid out.** A page whose body is a lazy list
  builds just the viewport, so a widget below the fold is never measured — and the
  golden, which captures the viewport too, does not see it either.
  `TopCategoriesCard` is exactly that case: its overflow only showed at the wider
  configurations, where the card finally came into view. It now has a focused
  widget test (`top_categories_card_test.dart`), as does `budget_status_pill`
  (which had none at all). Scrolling each page to the bottom inside the walk would
  close the gap.
- **The 2 % golden tolerance is far too coarse for a small widget.** The tolerance
  exists to absorb rasterizer differences on CI, but a four-glyph label
  disappearing or being truncated changes ~0.3 % of a 360×900 capture — inside it.
  Overflow is still caught (it throws); a *layout* regression of a small element is
  not. Focused widget tests are the answer, not tighter goldens.

**Four rows are capped, not flexed** — and this is the subtlest part of the work.
Rows shaped `[icon][label] … [value][menu]` (`account_card`, `budget_category_row`,
`recurring_item_card`, `top_categories_card`) put the *data* last, and the shipped
design gives it the whole row while the label truncates to nothing. Wrapping the
value in `Flexible` fixes the 2× overflow but is wrong twice over: a flex share is
allocated at **every** width, so it also binds at 1× and truncates the amount on a
screen that has room for it; and because the label is `Expanded` (tight) while
`Flexible` is loose, whenever the value is narrower than its share the row is left
with unused space and the value drifts off the right edge.

`lib/core/widgets/capped_row.dart` holds the fix: `CappedRow` wraps the row in a
`LayoutBuilder` (it must wrap the *row* — inside it, the builder would be a non-flex
child measured with an unbounded main axis) and hands the builder the width its
trailing value may take. The value goes in a `ConstrainedBox`, so the cap is **inert
until the row genuinely cannot fit**, which is what keeps 1× and wide layouts
byte-identical to what shipped. `kTrailingValueMaxFraction` (0.6) is a documented
judgment call with its measured headroom, and `top_categories_card` passes 0.7
because its trailing pair needs ~198 px of a 304 px row at 1×. Pinned by
`should_not_truncate_the_amount_where_the_row_fits`; the other three rows are covered
by their page goldens, though only for gross changes (see above).

### C. Judgment items — done

The first four items turned out to be *mechanically* expressible after all, so
they were pulled forward into A's enforce-the-rule shape rather than left as
hand-audit chores.

- ☑ **Icon system** — `lib/app/theme/app_icons.dart`, ~70 role-named constants.
  104 ad-hoc `Icons.*` references with two or three competing variants per core
  concept (delete, edit, calendar, close, person, check) collapsed to one glyph
  each. **Rule 8** and a duplicate-glyph assertion in
  `design_rules_test.dart` keep it that way. Two named exemptions survive
  because they are not chrome: the DB-backed `CategoryIcons`/`AccountIcons`
  catalogues, and the two provider brand marks — both re-asserted by their own
  test so the list cannot rot.
- ☑ **`ListRow` adoption** — `docs/Design.md` §5.6. Raw `ListTile` in a plain
  list went 9 → 5, `ListRow` 0 → 5. The roadmap's "0 vs 14" decomposed into
  5 `SwitchListTile` (no `ListRow` equivalent — a switch *is* the row), 4
  date-picker *fields* and rich-trailing rows, and **3** genuine list rows.
  **Rule 9** pins the 4 remaining raw `ListTile`s with re-asserted exemptions.
  Forcing the field rows into `ListRow` would have silently dropped their
  trailing overflow menu, so they were deliberately left alone.
- ☑ **`AppCard` adoption** — **Rule 10** (`should_not_build_a_raw_material_card`,
  lookbehind so `AppCard(` itself never matches) burned the 7 raw `Card(`
  sites to zero: account/goal/recurring/budget-summary/budget-form-preview/
  account-page action group all route through `AppCard` now. `AppCard` gained
  an optional `border` slot (default none per §5.2) so status-signalling
  borders (goal-completed green, recurring-due amber) survive without a
  hand-rolled `Card`. Remaining hand-rolled `Container` + `BoxDecoration`
  cards (insight/chart cards on `surfaceSubtle` + `borderMd`) are a different
  treatment, not the M3-`Card` anti-pattern — unifying them is a follow-up.
- ☑ **`SegmentedTabs`** — **Rule 11** (`should_not_build_a_raw_material_
  segmented_button`, generic-aware pattern: call sites are
  `SegmentedButton<int>(`, which a bare `SegmentedButton\(` never matches —
  the scanner self-check caught that blindness before it landed). All 8 raw
  sites migrated: transaction direction, category kind, filter direction
  (All/Expense/Income), goal deposit/withdraw, budget total/category,
  recurring direction, recurring Active/Paused, settings theme + week-start.
  `TabBar`s (page-level tabs) and `FilterChip`s (multi-filters) are a
  different component and stay. The migration caught a real layout bug:
  long Burmese labels overflowed `_SegmentItem`'s min-size `Row` (unbounded
  width disables `ellipsis`), fixed with a `Flexible` label — the `my` locale
  settings test goes red without it.
- ☑ **Golden tests** — `test/core/widgets/design_system_golden_test.dart`
  pins `AppCard` / `ListRow` / `SegmentedTabs` × light/dark (6 PNGs under
  `test/core/widgets/goldens/`, 2% tolerant comparator like the avatar
  goldens). `AppScaffold` stays out: viewport-dependent goldens pin the test
  window, not the component.
- ☑ **Calendar spec deviations** (§6) — all three fixed in `d617299`:
  `_Capsule` width is now `cellWidth * 0.6` measured through `LayoutBuilder`
  (so it scales to tablet instead of hardcoding 24); the selected cell is a
  `brandSubtle` fill at `radius.md` with today's `radius.full` ring drawn *over*
  it in a `Stack` (was `BoxShape.circle`); and the intensity ramp was
  **inverted** — `step * 64` faded the already-subtle tint *out*, making the
  busiest day the palest capsule, so it now `Color.lerp`s from `moneyOutSubtle`
  toward full `moneyOut`. Three tests pin each.

## Phase 4 — "Sync & Polish" (v0.4) — NOT STARTED

- ☐ (Auth already shipped in v0.2) Sync status UI
- ☐ Outbox + `RemoteStore` contract tests + Firebase adapter
- ☐ Sync status UI, merge-on-first-login flow, delete account
- ☐ App lock, widget
- ☐ Web release (PWA, responsive QA, browser support matrix)
- ☐ Supabase adapter (prove swap)

## Phase 5 — Release — NOT STARTED

- ☐ Store checklist from `Platform.md` §7 (Sign in with Apple, data safety, deletion URL, iPad/tablet screenshots)
- ☐ Store listing, privacy policy, screenshots
- ☐ Crash reporting + (opt-in) analytics decision
- ☐ Beta with Osaka Myanmar community → feedback loop
- ☐ Monetization decision

## Backlog / ideas

Receipt photos · split bills · multi-currency FX · shared budgets · PDF monthly report · Siri Shortcuts
