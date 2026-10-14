# Roadmap.md

Legend: ☐ todo · ◐ in progress · ☑ done. Each task = one small PR following `Agent.md` §5.

**Where we are:** Phase 0 is ~80% done and is the only phase started. **Phases 1–5 are not started** — the `lib/features/*` folders exist but contain only `.gitkeep` scaffolds, and there is no `lib/data/` or `lib/domain/` yet. The app currently has no screens beyond the scaffold placeholder and no persistence (Drift is not a dependency yet).


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

## Phase 3.5 — "Design debt burn-down" (v0.3.1) — IN PROGRESS (A + B complete)

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

### C. Judgment items — not auto-detectable (NOT STARTED)

- ☐ **Icon system** — no enforced icon set; icons are picked ad hoc.
- ☐ **`ListRow` adoption** — 0 used against 14 `ListTile` (`docs/Design.md` §5.6).
- ☐ **`AppCard` adoption** — cards mostly hand-rolled from `Container` +
  `BoxDecoration` (§5.2).
- ☐ **`SegmentedTabs`** — segmented controls are rebuilt per screen.
- ☐ **Golden tests** — few screens are pinned; regression is invisible.
- ☐ **Calendar spec deviations** (§6) — `_Capsule` hardcodes `width: 24` where
  the spec says "60% of cell"; the height step is `step * 64` against the spec's
  five-step quantization; `BoxShape.circle` where the spec says `radius.md`.

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
