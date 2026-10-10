# Agent.md — Instructions for AI Coding Agents

> Read this file FIRST in every session. Then read the docs it points to before writing code.
> Working app name: **Ledgerly** (placeholder — rename in one place: `lib/core/constants/app_info.dart`).

## 1. What we are building
A **compact, clean, premium, unique** personal budget manager for iOS/Android, built with **Flutter**.
Inspired by simple calendar-based budget apps, but adds **charts, import/export, budgets, accounts, recurring transactions** and real money-management tools.
Status: **prototype** — real user count unknown. Backend is **free-tier only** and must be **swappable** without touching domain/presentation code.

## 2. Doc map (read before coding)
| File | Read when |
|---|---|
| `docs/Product.md` | Any feature work — scope, user stories, acceptance criteria |
| `docs/Design.md` | Any UI work — tokens, components, screen specs (MANDATORY for UI) |
| `docs/Architecture.md` | Creating/moving files, new features, DI, state |
| `docs/Platform.md` | Any UI work — iOS Liquid Glass / Android Material 3 / responsive web (MANDATORY for UI) |
| `docs/Auth.md` | Auth, profile, avatar, account deletion |
| `docs/DataModel.md` | Entities, DB schema, money handling |
| `docs/Backend.md` | Anything touching remote/sync/auth |
| `docs/Versions.md` | Before adding/upgrading any package or SDK; Riverpod 3 / Flutter 3.47 rules |
| `docs/Conventions.md` | Code style, naming, memory rules, testing, Git |
| `docs/Roadmap.md` | Picking the next task |

## 3. Non-negotiable rules
1. **Clean Architecture, feature-first.** Dependencies point inward: `presentation → domain ← data`. `domain` is pure Dart (no Flutter, no Dio, no Drift, no Firebase/Supabase imports).
2. **Backend is a plug-in.** UI/domain only know repository interfaces. Remote providers live behind `RemoteDataSource` interfaces in `data/`. Swapping Firebase → Supabase → custom API must touch only `data/` + DI.
3. **SOLID everywhere.** Small classes, one reason to change, depend on abstractions, inject dependencies (get_it), no god-widgets, no god-providers.
4. **`Result<T>` for errors.** Repositories/use-cases return `Result<T>` (`Success`/`Failure`). **No try/catch in the presentation layer.** Map exceptions to `Failure` in `data/`.
5. **Money is an integer in minor units + currency code.** Never `double` for money. See `docs/DataModel.md`.
6. **Local-first.** SQLite (Drift) is the source of truth. The app must be fully usable offline.
7. **Memory & performance discipline** (see `docs/Conventions.md` §Memory): dispose everything, `autoDispose` providers, `const` widgets, `ListView.builder`, paginate, select-based rebuilds.
8. **UI quality bar = `docs/Design.md`.** Clean, polished, modern, premium UI/UX. **Do NOT produce admin-dashboard aesthetics** (dense tables, heavy borders, generic Material cards). Use **dedicated, separate CRUD pages** (list page → detail/form page), not inline dialogs or mega-screens. Keep layouts consistent across all screens via shared scaffolds/components.
9. **No hardcoded** colors, text styles, spacing, radii, strings. Use design tokens + l10n.
10. **Platform-adaptive UI.** iOS = **Liquid Glass**, Android = **Material 3**, Web = responsive M3. Pages never branch on platform; only `core/widgets` adaptive components do (see `Platform.md`). Layouts adapt by **window size class** (compact/medium/expanded/large), never by device guesses. Test at 360/768/1440 px.
11. **Web-ready from day one.** No `dart:io` outside conditional imports; every package must support iOS + Android (+ web or a stub behind an interface).
12. **Auth is optional & pluggable.** Guest mode always works. Apple/Google sign-in, in-app account deletion, and store compliance per `Auth.md`.
13. **Versions are pinned in `docs/Versions.md`.** Use Flutter 3.47.1 APIs (no deprecated/legacy: no `StateProvider`, no `dart:html`, no `package:flutter/material.dart` imports). Prerelease packages only behind an interface + exit plan.
14. **Never** add a package without justification in the PR/commit message and checking maintenance status, license, and size.

## 4. Tech stack (fixed unless discussed)
- **Flutter 3.47.1 / Dart 3.13.1** (pinned with FVM) — sealed classes, records, patterns. **Exact package versions: `docs/Versions.md`** (single source of truth)
- UI libs: **`material_ui` + `cupertino_ui`** standalone packages (Flutter 3.47+). Import from these, not `package:flutter/material.dart` / `cupertino.dart`
- State: **Riverpod 3.x** (`flutter_riverpod ^3.4`) — `Notifier`/`AsyncNotifier`/`StreamNotifier` only; **no** `StateProvider`/`StateNotifierProvider` (legacy). Presentation layer only
- DI: **get_it** (data/domain wiring) — Riverpod providers read use-cases from get_it
- Local DB: **Drift ^2.35** + `drift_flutter` (SQLite; WASM on web) · Key-value: `shared_preferences`
- Network: **Dio** + `pretty_dio_logger` (debug only)
- Routing: **go_router ^17**
- Auth (data layer only): `firebase_auth`, `google_sign_in`, `sign_in_with_apple`
- Avatars/icons: `flutter_svg` (or CustomPainter) · Android dynamic color (optional): `dynamic_color`
- Models: **freezed 3.x** + `json_serializable` (+ `build_runner`)
- Charts: **fl_chart**
- i18n: `flutter_localizations` + `intl` (en, my, ja)
- Files: `file_picker`, `share_plus`, `csv`, `path_provider`
- Testing: `flutter_test`, `mocktail`, `integration_test`

## 5. Workflow for every task
1. Read the relevant doc(s) + the roadmap item.
2. Restate the plan in ≤10 lines (files to add/change, layers touched).
3. Implement **domain → data → presentation** (in that order).
4. Write/Update tests (domain use-cases + repositories mandatory; widget tests for key flows).
5. Run: `dart format .` · `flutter analyze` (zero warnings) · `flutter test`.
6. Self-review against the **Definition of Done** below.
7. Summarize: what changed, why, and any follow-ups. Update docs if behavior/architecture changed.

## 6. Definition of Done
- [ ] Layer boundaries respected (no forbidden imports)
- [ ] `Result<T>` used; no UI try/catch
- [ ] No `double` money; formatting via `MoneyFormatter`
- [ ] All streams/controllers/timers/listeners disposed
- [ ] Providers are `autoDispose` unless they must live app-wide
- [ ] UI matches `Design.md` tokens; light **and** dark mode checked
- [ ] Looks native on **iOS (Liquid Glass)** and **Android (M3)**; verified at compact / medium / expanded widths
- [ ] Strings localized (en/my/ja); long Burmese/Japanese text doesn't overflow
- [ ] Empty / loading / error states implemented
- [ ] Tests added; analyzer clean
- [ ] Docs updated if needed

## 7. Communication
- **ALWAYS answer in Burmese** (Myanmar Unicode, never Zawgyi) — every reply, plan, explanation, review and question to the owner (YK) must be in Burmese, in a friendly, informal tone. Technical terms (Riverpod, Clean Architecture, widget, etc.) stay in English.
- This applies at the start of every session and after every `/clear`; don't switch to English even if the task prompt is written in English.
- Code, code comments, identifiers, commit messages, PR titles and project docs stay in **English**.
- Shell output, error messages and file paths are quoted as-is; explain them in Burmese.
- Ask a question only when blocked; otherwise state the assumption and proceed.
- Be honest about trade-offs; push back if a request violates rules above.

## 8. Do NOT
- Put business logic in widgets or in `data/` models.
- Call remote SDKs outside `data/`.
- Use `setState` for anything beyond purely local ephemeral UI state.
- Use `BuildContext` across async gaps without a `mounted` check.
- Ship placeholder/Lorem text, `print()`, or commented-out code.
- Add ads, analytics, or tracking SDKs without explicit approval.