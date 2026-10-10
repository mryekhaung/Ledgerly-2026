# Architecture.md

## 1. Style
**Clean Architecture, feature-first**, Riverpod for presentation state, get_it for dependency wiring.

```
presentation  →  domain  ←  data
(widgets,        (entities,   (models, datasources,
 providers)       repo ifaces, repo impls, mappers)
                  use cases)
```
- `domain`: pure Dart. Zero Flutter/SDK imports.
- `data`: implements domain interfaces. Only layer allowed to import Drift, Dio, Firebase/Supabase, file APIs.
- `presentation`: Flutter + Riverpod. Calls **use cases only** (never repositories directly).

## 2. Folder structure
```
lib/
├─ main.dart
├─ app/
│  ├─ app.dart                 # MaterialApp.router, theme, l10n
│  ├─ router/                  # go_router config, route names
│  ├─ theme/                   # tokens: colors, typography, spacing, radius
│  └─ di/                      # get_it setup (injection.dart, modules per feature)
├─ core/
│  ├─ result/                  # Result<T>, Failure types
│  ├─ usecase/                 # UseCase<T, Params>
│  ├─ money/                   # Money, CurrencyCode, MoneyFormatter
│  ├─ network/                 # Dio factory, interceptors
│  ├─ database/                # Drift AppDatabase, DAOs shared, migrations
│  ├─ utils/ extensions/ constants/
│  ├─ platform/                # AppPlatform, WindowSizeClass, AdaptiveStyle
│  └─ widgets/                 # Design-system; adaptive: ios/ + material/ impls (see Platform.md)
├─ features/
│  ├─ transactions/
│  │  ├─ data/{datasources,models,mappers,repositories}
│  │  ├─ domain/{entities,repositories,usecases}
│  │  └─ presentation/{pages,widgets,providers}
│  ├─ calendar/   categories/   accounts/   budgets/
│  ├─ insights/   recurring/    goals/
│  ├─ data_transfer/           # import / export / backup
│  ├─ auth/                    # Welcome/SignIn/Account/DeleteAccount (see Auth.md)
│  ├─ sync/                    # v0.4
│  ├─ profile/                 # UserProfile, AvatarConfig, AvatarCatalog, AvatarEditorPage
│  └─ settings/  onboarding/
└─ l10n/                       # arb files: en, my, ja
test/                         # mirrors lib/
integration_test/
```

## 3. Core contracts
```dart
sealed class Result<T> { const Result(); }
final class Success<T> extends Result<T> { final T value; const Success(this.value); }
final class Err<T> extends Result<T> { final Failure failure; const Err(this.failure); }

sealed class Failure { final String message; const Failure(this.message); }
// StorageFailure, NetworkFailure, AuthFailure, ValidationFailure, NotFoundFailure, ConflictFailure, UnexpectedFailure

abstract interface class UseCase<T, P> { Future<Result<T>> call(P params); }
abstract interface class StreamUseCase<T, P> { Stream<Result<T>> call(P params); }
```
Presentation consumes `Result` via `AsyncValue` mapping helpers (`result.fold(...)`) — no try/catch in UI.

## 4. Repository pattern & backend swap
```
domain/ TransactionRepository (interface)
data/   TransactionRepositoryImpl
          ├─ TransactionLocalDataSource   (Drift)      ← source of truth
          └─ TransactionRemoteDataSource  (interface)  ← optional
                ├─ FirebaseTransactionRemoteDataSource
                ├─ SupabaseTransactionRemoteDataSource
                └─ NoopTransactionRemoteDataSource  (default: local-only)
```
Swap = change one binding in `app/di/` — nothing in domain/presentation changes. See `Backend.md`.

## 5. State management rules (Riverpod)
- `AsyncNotifier`/`StreamNotifier` per screen concern; keep notifiers thin (call use cases, hold UI state).
- **Riverpod 3.x** (see `Versions.md` §4): `Notifier`/`AsyncNotifier`/`StreamNotifier` only; no legacy `StateProvider`/`StateNotifierProvider`.
- Providers are auto-disposed by default. App-wide singletons (settings, auth session) are the exception (`keepAlive`, documented).
- Set `retry` explicitly for providers that return `Result`; don't blindly retry validation/business failures.
- Use `ref.mounted` after awaits inside notifiers.
- Use `ref.watch(provider.select(...))` to limit rebuilds.
- Expose use cases to Riverpod via a thin provider that reads from get_it: `final addTransactionProvider = Provider((_) => getIt<AddTransaction>());`
- Navigation side-effects via `ref.listen`, never inside `build` bodies.
- Form state: dedicated notifier per form (`TransactionFormNotifier`) with validation in domain `Validators`.

## 6. Data flow example — add transaction
`AddTransactionPage` → `TransactionFormNotifier.submit()` → `AddTransaction` use case (validates, builds entity) → `TransactionRepository.add` → `LocalDataSource.insert` (+ enqueue outbox row if sync enabled) → Drift stream emits → `watchMonthTransactions` use case → calendar & summary providers update.

## 7. Reactive reads
Drift `watch*` queries expose `Stream`s through repositories → `StreamNotifier`s. Aggregations (month totals, per-day net, category sums) are computed **in SQL** (GROUP BY), not in Dart loops.

## 8. Error handling
Data layer catches exceptions → maps to `Failure`. Domain returns `Result`. Presentation maps `Failure` → localized message + retry affordance. Global `FlutterError`/zone guard logs unexpected errors (Crashlytics/Sentry optional later).

## 9. Navigation
`go_router` with typed routes, feature-owned route files. Auth/onboarding guards via redirect. Deep links: `/tx/new?date=...` (supports widgets/shortcuts later).

## 10. Dependency injection
- `get_it` modules per feature: `registerTransactionsModule(GetIt)`.
- Lazy singletons for datasources/repositories; factories for use cases.
- Environment flavors (`dev`, `prod`) choose implementations (e.g., `Noop` vs `Firebase` remote).

## 11. Testing strategy
- **Domain:** unit tests for every use case & validator (fast, no mocks of Flutter).
- **Data:** repository tests with in-memory Drift + mocked remote.
- **Presentation:** widget tests for forms, calendar, empty/error states; golden tests for design-system components (light/dark).
- **Integration:** add → see in calendar → export → import round-trip.
- Target: domain ≥ 90%, data ≥ 80%, overall ≥ 70%.

## 12. Decision log (ADR-lite)
| # | Decision | Reason |
|---|---|---|
| 1 | Local-first Drift | Offline, instant UX, zero backend cost, no vendor lock |
| 2 | Money as int minor units | Exact arithmetic |
| 3 | Client-generated UUIDv4 ids | Offline creation + conflict-free sync |
| 4 | Soft delete (`deletedAt`) | Needed for sync + undo |
| 5 | Remote behind interfaces | Swap backend without rewrite |
| 6 | Riverpod + get_it | Reactive UI state + explicit DI for non-UI layers |
