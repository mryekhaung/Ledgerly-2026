# Roadmap.md

Legend: ☐ todo · ◐ in progress · ☑ done. Each task = one small PR following `Agent.md` §5.

## Phase 0 — Foundation
- ◐ **Pin toolchain** (FVM 3.47.1, Dart ^3.13, CI same); create project with `material_ui` / `cupertino_ui` imports; resolve & record all unverified packages in `docs/Versions.md`
  - ✅ `.fvmrc` = 3.47.1, `pubspec.yaml` `sdk: ^3.13.0` / `flutter: ">=3.47.0"`, CI pinned to 3.47.1
  - ⚠ **Blocked:** the Flutter tool cannot start on the dev machine (`All pipe instances are busy`, OS error 231), and the installed SDK is 3.38.2 not 3.47.1 — so no package has been genuinely resolved. See the status block in `Versions.md`.
- ☐ Riverpod 3 baseline provider/notifier template + lint rule banning `legacy.dart` imports
  - ◐ CI `banned-imports` job enforces the ban; the baseline provider template is still todo
- ☑ Create Flutter project, flavors (dev/prod), lints, CI (format/analyze/test)
- ☑ `core/`: Result, Failure, UseCase, Money + MoneyFormatter (+ tests)
- ◐ Design tokens (`app/theme`): colors light/dark, typography, spacing, radius — done; motion/elevation included. Awaiting a font-bundling pass.
- ◐ get_it bootstrap + Riverpod `ProviderScope` + go_router skeleton — wired; the real adaptive nav shell lands with the design-system item below
- ◐ l10n setup (en/my/ja) + font bundling — ARB files + `l10n.yaml` written; **not generated** (`flutter gen-l10n` blocked) and fonts not bundled
- ☐ Drift database, migration test harness, seed defaults
- ☐ `core/platform/` (AppPlatform, WindowSizeClass, AdaptiveStyle) + `GlassSurface` spike: blur fallback first, then `cupertino_native_better` (native iOS 26 tab bar/buttons); `liquid_glass_renderer` experimental only — decide & document
  - ✅ `core/platform/` done (AppPlatform, WindowSizeClass, AdaptiveStyle + tests); GlassSurface spike still todo
- ☐ Web spike: Drift (`drift_flutter` WASM) + conditional imports + fonts + `flutter build web --wasm` running
- ☐ Design-system widgets (adaptive iOS/Material impls + responsive helpers): AppScaffold, AppCard, CategoryGem, AmountText, SegmentedTabs, ListRow, buttons, fields, EmptyState, GlassDock (+ goldens)
  - 📄 Specs for all of these now live in `docs/Design.md` §5


## Phase 1 — MVP "Log & See" (v0.1)
- ☐ Categories: domain/data/use cases (CRUD, reorder, archive)
- ☐ Categories pages: list + form (icon grid, color palette, live preview)
- ☐ Transactions: domain/data/use cases (add/update/delete/watch by month/day)
- ☐ Add/Edit Transaction page + AmountKeypad + Category Picker page
- ☐ Calendar page: Day Capsules, month switcher, summary card, day list
- ☐ Settings: currency, language, theme, week start
- ☐ Profile (guest) + Avatar catalog/renderer + Avatar Editor page + random generate
- ☐ Responsive layouts (compact/medium/expanded) for Calendar, Forms, Categories, Settings
- ☐ Empty/loading/error states, haptics, undo
- ☐ Memory profiling pass + accessibility pass
- ☐ **Milestone: TestFlight/internal build**

## Phase 2 — "Understand & Account" (v0.2)
- ☐ Firebase project + flavors; `AuthRepository` + Firebase adapter
- ☐ Welcome / Sign in with Apple / Google (/ Email) / Account pages
- ☐ Guest → account linking + merge prompt
- ☐ Sign out + **Delete account** (re-auth, Apple token revoke) — store requirement
- ☐ Insights: donut, bar, line, top categories (SQL aggregations)
- ☐ Transactions list page: search, filters, paging
- ☐ Export CSV/JSON (+ share)
- ☐ Import CSV/JSON with mapping, preview, dedupe (isolate)
- ☐ Full backup/restore

## Phase 3 — "Manage" (v0.3)
- ☐ Accounts + transfers
- ☐ Budgets (category + total) with progress and alerts
- ☐ Recurring transactions (scheduler on app open + local notifications)
- ☐ Savings goals

## Phase 4 — "Sync & Polish" (v0.4)
- ☐ (Auth already shipped in v0.2) Sync status UI
- ☐ Outbox + `RemoteStore` contract tests + Firebase adapter
- ☐ Sync status UI, merge-on-first-login flow, delete account
- ☐ App lock, widget
- ☐ Web release (PWA, responsive QA, browser support matrix)
- ☐ Supabase adapter (prove swap)

## Phase 5 — Release
- ☐ Store checklist from `Platform.md` §7 (Sign in with Apple, data safety, deletion URL, iPad/tablet screenshots)
- ☐ Store listing, privacy policy, screenshots
- ☐ Crash reporting + (opt-in) analytics decision
- ☐ Beta with Osaka Myanmar community → feedback loop
- ☐ Monetization decision

## Backlog / ideas
Receipt photos · split bills · multi-currency FX · shared budgets · PDF monthly report · Siri Shortcuts
