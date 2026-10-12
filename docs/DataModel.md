# DataModel.md — Local Schema (Drift / SQLite)

The source of truth for the on-device database. Every table, column, index and
migration decision lives here; `lib/core/database/` implements it.

**Status: v1 (schemaVersion = 1).** Written before the first table so Phase 1 has
a spec to build against. `docs/Agent.md` §2 references this file.

Related: `docs/Architecture.md` ADR #1–#5 (local-first, int money, UUIDv4,
soft delete, remote behind interfaces).

---

## §1 Global rules

These apply to **every** table. Do not restate them per table.

| Rule | Detail |
|---|---|
| **Primary keys** | `TEXT` holding a **client-generated UUIDv4**. Never autoincrement — rows are created offline, before any server exists, and must not collide on sync (`Architecture.md` ADR #3). |
| **Money** | Stored as `INTEGER` **minor units** + a separate `TEXT` currency code. Never `REAL`. Domain maps to `Money` (`core/money`) at the boundary. |
| **Dates (day precision)** | Stored as `INTEGER` packed `yyyyMMdd` via `LocalDate` (`core/utils/local_date.dart`). Used for transaction dates, budget periods, recurring anchors. |
| **Timestamps (instant)** | Stored as `INTEGER` **UTC epoch milliseconds**, column suffix `At`. Used for `createdAt`, `updatedAt`, `deletedAt`. |
| **Soft delete** | Every syncable table has a nullable `deletedAt`. Deletion sets it; no `DELETE` statement is issued by the app (`Architecture.md` ADR #4). Queries filter `deletedAt IS NULL` unless explicitly reading tombstones. |
| **Sync readiness** | `updatedAt` is bumped on every write by the repository, not by the database, so an outbox can diff later (v0.4). |
| **Enums** | Persisted as `TEXT` (the enum's `name`), never `INT` ordinals — reordering an enum must not corrupt existing rows. |
| **Booleans** | `INTEGER` 0/1 (`BOOL` in Drift). |
| **Naming** | Tables `snake_case` plural (`transactions`); columns `camelCase` in Dart, `snake_case` in SQL (Drift default). |

### Indexes — the rule, not a list
Index every column used in a `WHERE`, `ORDER BY` or `JOIN` on a hot path.
The **hot paths** for this app are: a month of transactions, one day of
transactions, a category's transactions, and active (non-deleted) rows. Indexes
are declared per table below.

### Foreign keys
SQLite ships with foreign keys **off**; `AppDatabase` enables
`PRAGMA foreign_keys = ON` in `beforeOpen`. Deletes are soft, so `ON DELETE`
behaviour matters only for hard deletes during a future purge.

---

## §2 `categories`

A user-defined label for a transaction. Seeded with defaults on first launch.

| Column | Type | Null | Notes |
|---|---|---|---|
| `id` | TEXT | PK | UUIDv4 |
| `name` | TEXT | no | Display name; unique among **active** rows (enforced in the DAO, not a UNIQUE index, so a soft-deleted `Food` can be recreated) |
| `iconKey` | TEXT | no | Catalog key resolved by `core/widgets` (e.g. `restaurant`). Not a code point — icons change sets between platforms |
| `colorValue` | INTEGER | no | ARGB32. The AppBar/accent colour; must clear WCAG AA against surfaces (`Design.md` §2.3) |
| `kind` | TEXT | no | `expense` \| `income` \| `transfer` — the transaction directions this category may be used for |
| `sortOrder` | INTEGER | no | Manual ordering in the category list. Unique-ish; reorder rewrites the whole column |
| `isArchived` | BOOL | no | Hidden from pickers but kept in history. Distinct from `deletedAt` |
| `isDefault` | BOOL | no | True only for seeded rows — lets a reset restores them |
| `createdAt` | INTEGER | no | UTC epoch ms |
| `updatedAt` | INTEGER | no | UTC epoch ms |
| `deletedAt` | INTEGER | **yes** | Soft delete |

**Indexes:** `(deletedAt, isArchived, sortOrder)` for the list/picker query;
`(kind, deletedAt)` for filtering pickers by direction.

**Why `isArchived` *and* `deletedAt`:** a user retiring "Rent" wants it out of the
picker but still wants last year's chart to show it. Only `deletedAt` hides it
from history.

---

## §3 `transactions`

One money movement. The centre of the app.

| Column | Type | Null | Notes |
|---|---|---|---|
| `id` | TEXT | PK | UUIDv4 |
| `categoryId` | TEXT | no | FK → `categories.id` |
| `accountId` | TEXT | **yes** | FK → `accounts.id`. Null until accounts land in v0.3 — a v1 row is category-only |
| `amountMinor` | INTEGER | no | **Always positive.** Direction comes from `direction`, never from the sign. Range is validated in the domain against `Money.maxDigits` |
| `currency` | TEXT | no | ISO code (`MMK`, `JPY`, `USD`, …) — the enum `name`, lowercase in storage |
| `direction` | TEXT | no | `expense` \| `income` \| `transfer` |
| `date` | INTEGER | no | Packed `yyyyMMdd` (`LocalDate.value`) — the business date the user picked |
| `note` | TEXT | yes | Free text |
| `createdAt` / `updatedAt` / `deletedAt` | INTEGER | `deletedAt` yes | see §1 |

**Why the sign lives in `direction`, not in `amountMinor`:** a negative amount plus
an expense direction is double-negation and produces bugs at every aggregation.
Keeping the magnitude unsigned makes `SUM(amount_minor)` over a filtered
direction the only correct query — and it is hard to get wrong.
`MoneyFormatter` renders direction via colour/layout (`Design.md` §2.4).

**Why `date` is not a timestamp:** a transaction belongs to a *day* in the user's
calendar, not an instant. Storing an instant means a transaction entered at
23:30 on the 31st appears in the next month for anyone east of the writer's
timezone. `createdAt` keeps the instant for audit.

**Indexes:** `(date, deletedAt)` — the **budget-period (inclusive `start..end` range)** and day queries (§8);
`(categoryId, date, deletedAt)` — per-category history and aggregates;
`(deletedAt, date)` — the sync/outbox scan.

**"Month" means budget period, not calendar month** (§8): every month-style query is `date BETWEEN :periodStart AND :periodEnd`. The same index serves both, so a pay-cycle month costs nothing extra.

**Denormalisation:** totals are **not** stored. They are computed in SQL
(`SUM … GROUP BY`) per `Architecture.md` §7. A cached total is a second source of
truth that drifts.

---

## §4 `accounts`

Where money sits. **Schema only in v1** — no UI, no seeds, no use cases until
Phase 3 (`Roadmap.md`). Declared now so `transactions.accountId` has a target and
the v1→v2 migration stays additive.

| Column | Type | Null | Notes |
|---|---|---|---|
| `id` | TEXT | PK | UUIDv4 |
| `name` | TEXT | no | e.g. `Wallet`, `KBZ Bank` |
| `type` | TEXT | no | `cash` \| `bank` \| `credit` \| `savings` \| `ewallet` |
| `currency` | TEXT | no | ISO code |
| `openingBalanceMinor` | INTEGER | no | Signed — an account can start in debt. The **only** signed money column in the schema, because it is a balance, not a movement |
| `iconKey` / `colorValue` | TEXT / INTEGER | no | same convention as `categories` |
| `sortOrder` | INTEGER | no | manual ordering |
| `isArchived` | BOOL | no | retired accounts stay in history |
| `includeInTotal` | BOOL | no | exclude a closed card from "net worth" |
| `createdAt` / `updatedAt` / `deletedAt` | INTEGER | `deletedAt` yes | see §1 |

**Indexes:** `(deletedAt, isArchived, sortOrder)`.

**Why `openingBalanceMinor` is signed:** it is a *position*, not a movement.
`transactions.amountMinor` is unsigned precisely because it is a movement. The
inconsistency is deliberate and is the reason both columns are documented
individually.

---

## §5 Migrations

`AppDatabase.schemaVersion = 2` today.

- **v1** — initial: `categories`, `transactions`, `accounts`.
- **v2** — `app_settings`: app-wide preferences. Purely additive (a new table),
  so an existing v1 database keeps every row and simply gains an empty table. No
  backfill: an absent key means "use the default".

- Every schema change adds a `MigrationStrategy.onUpgrade` step for the version it
  introduces, plus a test in `test/core/database/migration_test.dart` that opens a
  database at the previous version and upgrades it. The v1→v2 case builds the v1
  schema **by hand** with frozen DDL, so the fixture cannot drift along with the
  current schema.
- Additive changes (new nullable column, new table) are preferred; a destructive
  change must be justified in the PR and must include a data-preserving migration.
- The **migration harness exists from day one** so the first real migration is not
  also the first test of the harness.
- `drift_dev schema dump` / `schema generate` output belongs in
  `drift_schemas/` once a second version exists — not before, to avoid an empty
  directory in the repo.

---

## §6 Seed data

`seedDefaults(AppDatabase)` inserts the starter categories on first launch
(detected by an empty `categories` table). All seeded rows carry `isDefault = true`
so a "restore default categories" action can be implemented later without a
schema change.

Seeded set (name / iconKey / kind): Food, Transport, Groceries, Bills, Health,
Shopping, Entertainment, Education, Other — all `expense`; Salary, Other Income —
`income`. Colours come from the design tokens, not hardcoded hex.

Seeds are **not** inserted by a migration — a migration runs once, but the user may
delete every category deliberately and must not have them come back.

---

## §7 `app_settings`

| column | type | notes |
| --- | --- | --- |
| `key` | TEXT | Primary key. A `SettingsKeys` constant. |
| `value` | TEXT | Serialized preference. Enums store `.name`, never an ordinal. |
| `updatedAt` | INTEGER | UTC epoch ms of the last write. |

**Index:** `(key)` — a single-column lookup, but the primary key already covers
it; the named index exists so the table follows the §1 index convention and a
future compound lookup has a home.

**Why a key–value table and not `shared_preferences`:** SQLite is already the
source of truth (ADR #1), and Drift's `watch()` is what makes a theme or language
change repaint the app with no restart and no change-notifier plumbing. A KV
table also means a new preference is a new *row*, not a new column — the schema
does not grow.

**Why not `CommonColumns`:** preferences are not user data. They are never
soft-deleted, sorted, archived, or synced in v0.4 — a device's theme choice must
not travel to another device. Omitting the columns encodes that.

**Decode rule:** an unreadable or unknown value falls back to that field's
default rather than raising. This table is read before the first frame, where
there is no screen yet to show an error — the worst acceptable outcome is the user
re-picking one preference.

**Locale is special:** `null` ("follow the device") is stored by *deleting* the
row, not by writing a sentinel. An absent key and an empty string both decode to
null, so a blank row cannot shadow the device locale.

**Keys are append-only.** Renaming one orphans the existing row and silently
reverts that preference to its default, so a rename needs a migration step.

---

## §8 Budget period — a "month" that starts on the user's pay day

Most people are paid mid-month (e.g. the 10th), so "this month" for budgeting means
**Oct 10 → Nov 9**, not Oct 1 → Oct 31. The app models this once, in the domain, so no
screen or query ever assumes a calendar month.

**Setting.** One new `app_settings` key: **`monthStartDay`** (`SettingsKeys.monthStartDay`),
an integer **1–28**, default **1** (= ordinary calendar month).
- **No migration.** It is a new *row*, not a new column (§7) — schema stays v2. An absent key
  means 1.
- **Decode rule (§7):** a missing, non-numeric or out-of-range value falls back to **1**; it
  never throws.
- **Why 28 max:** every month has days 1–28, so there is no "start on the 31st" clamping and
  no ambiguity in February.
- Keys are append-only (§7) — do not rename it later without a migration step.

**Transactions are untouched.** Each keeps its real `date`. A period is a *view* computed
from dates, so changing `monthStartDay` later needs **no data migration** — every screen
simply recomputes.

**Domain type (pure Dart, `core/period/`)**
```dart
final class BudgetPeriod {            // both ends inclusive
  final LocalDate start, end;
  String get id => /* 'yyyy-MM' of start */;   // Oct 10–Nov 9 -> '2026-10'
}
final class PeriodCalculator {
  const PeriodCalculator(this.startDay);        // asserts 1..28
  final int startDay;
  BudgetPeriod containing(LocalDate d);         // d.day >= startDay ? this month : previous month
  BudgetPeriod next(BudgetPeriod p);            // containing(p.end + 1 day)
  BudgetPeriod previous(BudgetPeriod p);        // containing(p.start - 1 day)
}
```
`end = nextStart − 1 day`. January wraps to the previous December. `LocalDate` already has
`addMonths`; add `addDays` if it is missing (packed `yyyyMMdd` arithmetic must go through
`DateTime`, never integer `±1`).

**Period id** = `yyyy-MM` of the period's **start** date. Budgets (v0.3), goals' monthly
targets, insights and "previous period" comparisons all key on this id. *(Open decision:
name by start month vs end month — settle before the Budgets table is created, because the
id is persisted there.)*

**Queries.** Every "month" query takes a `BudgetPeriod`:
- Period totals / per-day totals / category totals: `WHERE date BETWEEN :start AND :end AND
  deletedAt IS NULL` (uses `(date, deletedAt)`).
- Trend over several periods: one indexed range query per period (≤ 12–24), or a single
  query with `CASE WHEN date BETWEEN … THEN id`. **Never `GROUP BY date / 100`** — that is
  a calendar month and silently ignores the setting.
- "Pick a date" (transaction form) stays a **calendar** picker: choosing a date is about the
  calendar, not the cycle.

**Required tests** (startDay 10): Oct 9 → Sep 10–Oct 9 · Oct 10 → Oct 10–Nov 9 · Dec 31 →
Dec 10–Jan 9 · Jan 5 → Dec 10–Jan 9 (year boundary) · Feb in leap and non-leap years ·
startDay 1 ≡ calendar month · startDay 28 · `previous(next(p)) == p` for 100 random dates ·
a transaction on the first and last day of a period lands in exactly one period.
