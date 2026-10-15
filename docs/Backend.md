# Backend.md — free-tier, swappable sync strategy

> Referenced by `Agent.md` §2 (doc map), `docs/README.md` item 6 and
> `Architecture.md` §4. Written 16 Oct 2026 to unblock Phase 4 (Roadmap §G.1).
> **Status: PROPOSAL — the owner must ratify §7 before any Phase 4 code is written.**

## 1. Why this document exists

`Agent.md` §3.2 makes the backend a **plug-in**: UI and domain only know repository
interfaces, and remote providers live behind `RemoteDataSource` interfaces in `data/`.
`Architecture.md` §4 names this file as the place the swap is specified. Phase 4
("Sync & Polish") is the only unstarted phase and it cannot be designed without
deciding *what it syncs to* — hence this doc.

## 2. What is actually in the tree today (audit, 16 Oct 2026)

An honest audit matters here, because two earlier documents overstate the position.

| Claimed elsewhere | Reality |
|---|---|
| Roadmap §G.1: "`firebase_auth` already ships (§Phase 2 Auth), so Firebase is the only one with code in the tree" | **False.** `pubspec.yaml` contains **no** backend package: no `firebase_core`, `firebase_auth`, `cloud_firestore`, `supabase_flutter`, not even `dio`. |
| Roadmap §Phase 4: outbox + `RemoteStore` + Firebase adapter | **Not started.** `lib/features/sync/` is 14 `.gitkeep` files and nothing else. |
| `Architecture.md` §2: `core/network/` — Dio factory, interceptors | **Empty.** `lib/core/network/` contains only `.gitkeep`. |

What *does* exist is one interface and one fake:

- `lib/features/auth/data/datasources/auth_remote_datasource.dart` — `AuthRemoteDataSource`,
  a 10-method contract (`watchAuthState`, `signInAnonymously`, `signInWithGoogle`,
  `signInWithApple`, `signInWithEmailAndPassword`, `signUpWithEmailAndPassword`,
  `linkAccount`, `signOut`, `deleteAccount`).
- `lib/features/auth/data/datasources/noop_auth_remote_datasource.dart` — the **only**
  implementation, and the one `registerAuthModule` binds. It fabricates users locally
  (`'guest-${DateTime.now().millisecondsSinceEpoch}'`), never touches a network, and is
  correctly documented as a dev/prototype/test fake.

**Consequence:** the backend choice is genuinely green-field. The argument for Firebase
is *documentation continuity* (`Agent.md` §4 and `Platform.md` §6 already name it), not
code continuity. Nothing has to be unwound to choose differently — which is the whole
point of ADR #5.

## 3. Constraints the backend must satisfy

These are not preferences; each is a rule already written down.

| # | Constraint | Source |
|---|---|---|
| C1 | **Local-first.** Drift is the source of truth; the app is fully usable offline. The remote is a *replication target*, never the source of truth. | `Agent.md` §3.6, ADR #1 |
| C2 | **Free tier only.** No paid infrastructure while the user count is unknown. | `Agent.md` §1 |
| C3 | **Swappable.** Changing providers may touch only `data/` + DI. | `Agent.md` §3.2, ADR #5 |
| C4 | **`domain/` stays pure Dart.** No Firebase/Supabase import may ever reach it. | `Agent.md` §3.1 |
| C5 | **Client-generated UUIDv4 primary keys**, created offline before a server exists. Sync is therefore an **upsert by id**, never an insert-and-reconcile. | ADR #3, `DataModel.md` §1 |
| C6 | **Soft delete + `updatedAt` bumped by the repository on every write**, so an outbox can diff and a merge can be last-write-wins. | ADR #4, `DataModel.md` §1 |
| C7 | **iOS + Android + web**, and Wasm-compatible (no `dart:html`/`dart:js`). | `Agent.md` §3.11, `Platform.md` §6 |
| C8 | **Store compliance:** in-app account deletion, plus a web URL for deletion requests (Play), plus Apple token revocation on delete. | `Platform.md` §7 |
| C9 | **Money is integer minor units + a currency code.** MMK and JPY are zero-decimal (`exponent: 0`). The remote must store the integer exactly — no float coercion anywhere in the pipe. | `Agent.md` §3.5, `DataModel.md` §1 |
| C10 | **Auth is optional; guest mode always works.** Sync is an upgrade a guest opts into, not a gate. | `Agent.md` §3.12 |
| C11 | **No ads, no analytics, no tracking** without explicit approval. | `Agent.md` §8 |

## 4. Options

### 4.1 Firebase (Auth + Firestore)

**Fits:** `Agent.md` §4 already lists `firebase_auth`, `google_sign_in`,
`sign_in_with_apple`; `Platform.md` §6 already assumes "Firebase popup/redirect flow for
Google/Apple" on web. Apple token revocation is a first-class Firebase call. The Spark
(free) tier does **not** pause on inactivity.

**Costs:**
- Firestore is a document store with its own offline cache, which would duplicate Drift.
  **Mitigation: disable Firestore offline persistence.** It is used strictly as a remote
  store; Drift remains the only cache. This preserves C1 and must be stated in the adapter.
- **Per-operation billing.** Spark allows ~50k document reads/day and ~20k writes/day.
  A 5,000-row import is 5,000 writes — a quarter of the daily quota. Aggregation queries
  are billed per document scanned, so no free server-side maths.
  **Mitigation:** batched writes (≤500/batch), delta-only sync after the first push, and
  an explicit user-triggered "resync" instead of automatic full pulls.
- No SQL. "All my transactions" is a paginated collection scan, and per-category
  aggregation has to happen client-side or in Cloud Functions (which adds a paid surface).
- Web bundle grows noticeably (`firebase_js` interop).

### 4.2 Supabase (Postgres + Auth + Storage)

**Fits:** the data model is relational and already written down. Every Drift table maps
1:1 to a Postgres table with the same columns and the same types — `TEXT` uuid, `INTEGER`
minor units, `INTEGER` packed `yyyyMMdd`, `INTEGER` UTC epoch ms. `int8` holds minor units
exactly (C9). Sync is one `INSERT … ON CONFLICT (id) DO UPDATE` per batch, and the free
tier is **row/GB-based, not per-operation**, so a bulk first sync cannot blow a quota.
Row Level Security expresses "this row belongs to this uid" declaratively. `supabase_flutter`
is pure Dart over `http`/`web_socket_channel`, so it is Wasm-safe (C7). Exit is a
`pg_dump` — the least lock-in of the three.

**Costs:**
- **Free-tier projects pause after 7 days of inactivity.** For a budget app used
  sporadically this is a real operational risk. **Mitigation:** a scheduled keep-alive
  request (the repo already supports scheduled automations), or accept a cold-start
  delay on first open after a pause.
- Sign in with Apple needs manual provider configuration; Apple token revocation must be
  implemented by hand (Firebase gives it for free).
- RLS policies must be written *and tested* — a missing policy is a data leak, not a bug.
- Auth surface still has to be re-verified method-by-method against `AuthRemoteDataSource`.

### 4.3 Custom API

Full control, cheapest at scale, zero vendor lock. Rejected for now: it is not free-tier
in engineering time, and it requires hosting, TLS, backups, rate limiting and an auth
service that C8 obliges us to get right. `Agent.md` §1 sets the project as a prototype
with an unknown user count; building a backend is premature. Revisit at Phase 5 if the
free tiers genuinely bind.

## 5. Decision matrix

Weighted by the constraints in §3, not by feature checklists.

| Criterion (weight) | Firebase | Supabase | Custom |
|---|---|---|---|
| Data-model fit to the Drift schema (high) | Fair — documents, no SQL | **Excellent** — 1:1 relational | Excellent |
| Quota shape for a bulk first sync (high) | Poor — per-write billing | **Good** — row/GB | n/a |
| Free tier stays warm (medium) | **Good** — no pause | Poor — 7-day pause | n/a |
| Auth continuity with existing docs (medium) | **Good** — already specified | Fair — needs re-verification | Poor |
| Apple token revocation (medium) | **Built in** | Manual | Manual |
| Wasm / web readiness (medium) | Fair — heavier bundle | **Good** — pure Dart | Good |
| Vendor lock-in / exit cost (low) | Fair — contained by ADR #5 | **Good** — `pg_dump` | Excellent |
| Engineering time to first sync (high) | **Good** — docs already written | Fair | Poor |

## 6. Recommendation (for the owner to ratify)

**Adopt Firebase as the first adapter; keep Supabase as the mandated swap proof.**

Reasoning, in order of weight:

1. **`Agent.md` §4 is a "fixed unless discussed" stack** and it already names Firebase for
   auth. Adopting it means zero documentation churn and a store-compliance path
   (Apple revocation, web popup/redirect) that is already reasoned about in `Platform.md`
   §6–7. Choosing Supabase means rewriting both docs *and* hand-building Apple revocation.
2. **Firebase's free tier does not pause.** For a prototype whose real user count is
   unknown and whose usage is sporadic, a backend that is asleep when the first user opens
   the app is the worst possible first impression. The Supabase keep-alive ping is a
   workaround for a problem Firebase simply does not have.
3. **The auth surface already matches.** `AuthRemoteDataSource` is 10 methods and
   `NoopAuthRemoteDataSource` was written against Firebase's shape — `signInAnonymously`,
   `linkAccount`, `deleteAccount` with token revocation. The Firebase adapter is a
   translation, not a redesign.
4. **Firestore's weaknesses are containable and are already contained.** Offline
   persistence is switched off (Drift stays the only cache, C1 intact); the quota risk is
   handled by batching + delta-only sync + an explicit resync affordance, all of which
   Phase 4 needs anyway.

**Honest caveat, stated plainly:** Supabase is the better fit on the two criteria that
matter most to the *data* (schema mapping and quota shape). The recommendation above is a
bet that documentation continuity, a warm free tier and a ready-made Apple-revocation path
outweigh that. If the owner weighs data-model fit higher — or if Firestore's quota proves
binding during Phase 4 — **Supabase is the right reversal, and switching costs one binding
in `app/di/` plus one adapter.** That is precisely why Phase 4 lists "Supabase adapter
(prove swap)" as a deliverable rather than a nice-to-have.

**If the owner prefers to decide on data-model fit alone, choose Supabase instead.** Both
paths satisfy §3; only the adapter changes.

## 7. The `RemoteStore` contract (backend-agnostic)

This is the interface Phase 4 implements per provider. It is expressed only in terms of
C5/C6 primitives, so it never leaks a provider's vocabulary into `domain/`.

```dart
/// One row, in transport form. `payload` is the row's columns as JSON.
final class SyncRecord {
  final String table;      // 'transactions' | 'categories' | 'accounts' | ...
  final String id;         // client-generated UUIDv4 (ADR #3)
  final DateTime updatedAt; // repository-bumped, UTC (C6)
  final DateTime? deletedAt; // tombstone, never a hard delete (ADR #4)
  final Map<String, Object?> payload;
}

abstract interface class RemoteStore {
  /// Upsert by `id`. Idempotent: replaying a batch must be safe.
  Future<Result<void>> upsertAll(String userId, List<SyncRecord> records);

  /// Rows changed strictly after `cursor`, for this user only.
  /// Returns the new cursor alongside the rows.
  Future<Result<SyncPage>> changesSince(String userId, DateTime? cursor);

  /// Removes everything for this user. Called by account deletion (C8).
  Future<Result<void>> purgeUser(String userId);
}
```

### 7.1 Outbox

A Drift table, written **in the same transaction as the row write** so a crash can never
lose a pending change:

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT | UUIDv4 |
| `table` | TEXT | target table name |
| `rowId` | TEXT | the affected row's id |
| `op` | TEXT | `upsert` \| `purge` (enum name, never an ordinal) |
| `enqueuedAt` | INTEGER | UTC epoch ms |
| `attempts` | INTEGER | retry counter |
| `lastError` | TEXT | nullable; for the sync-status UI |

A `SyncEngine` drains it: coalesce all pending ops for the same `(table, rowId)` to the
latest `updatedAt`, batch (≤500 for Firestore, ≤1000 rows for Postgres), `upsertAll`,
then delete the drained rows.

### 7.2 Cursor & conflict resolution

- A per-user `syncCursor` (the newest `updatedAt` seen from the server) is persisted
  locally. `changesSince` returns strictly-greater rows so the cursor never re-reads.
- **Conflict resolution: last-write-wins on `updatedAt`**, applied uniformly to writes and
  tombstones. Ties break toward the server. This is only sound because C6 guarantees the
  repository — not the database — stamps `updatedAt`, so the value is monotonic per row
  and comparable across devices.
- **No hard deletes, ever.** A delete is an `updatedAt` bump plus a `deletedAt` stamp, so
  it travels through the same LWW path as an edit and cannot be resurrected by a stale
  replica.

### 7.3 First-login merge (guest → account)

A guest has a full local ledger and no remote rows. On linking:

1. Push every local row (a full `upsertAll` in batches) with the guest's `updatedAt`
   values intact.
2. Only then adopt the server cursor.
3. If the account already has remote rows (a returning user on a new device), pull first,
   then LWW-merge the local rows, then push the survivors.

The merge must be **resumable**: a crash mid-push leaves the outbox populated, and the
next drain is idempotent (`upsertAll` is by definition).

## 8. What Phase 4 must deliver

Per `Roadmap.md` §Phase 4, with the backend now decided:

1. `RemoteStore` + `SyncRecord` in `features/sync/domain/` (pure Dart).
2. `Outbox` Drift table + migration, and the transactional write in every repository.
3. `SyncEngine` + cursor + LWW merge, with unit tests for the merge rules.
4. **`RemoteStore` contract tests** — one suite, run against `NoopRemoteStore`,
   `FirebaseRemoteStore` and later `SupabaseRemoteStore`. This is how "prove swap" is
   satisfied: the same tests pass unchanged against a different provider.
5. `FirebaseRemoteStore` (Auth + Firestore, offline persistence **disabled**).
6. Sync status UI (idle / syncing / offline / error+retry) reading the outbox.
7. Merge-on-first-login flow.
8. `SupabaseRemoteStore` as the swap proof.
9. Account deletion → `purgeUser` + provider-side token revocation (C8).

## 9. Security & privacy

- **Never trust a client-supplied `userId`.** Firestore rules and RLS policies must scope
  every read and write to the authenticated `uid`. The `userId` parameter in §7 exists so
  the adapter can assert it matches the session, not so the client can choose it.
- Guest mode signs in **anonymously first**, so a real `uid` exists before any sync is
  possible — no anonymous-write path is ever opened.
- Transport is TLS only; no plaintext fallback.
- **Data safety / privacy declarations** (C8): financial information is collected, is
  encrypted in transit, is used only to provide sync, is deletable in-app, and is deletable
  by web request. No analytics, no ads, no third-party sharing (C11).
- Secrets: no provider key that grants admin scope may ship in the client. Firestore and
  Supabase both rely on rules/RLS rather than a client secret — verify this holds for
  whichever provider is ratified.

## 10. Open questions for the owner

1. **Ratify §6.** Firebase-first, or Supabase-first on data-model fit? Everything else in
   Phase 4 is downstream of this one answer.
2. **Guest data on first login:** push-then-pull (recommended, §7.3) or ask the user?
   Push-then-pull is silent but could surprise someone who expected a clean account.
3. **Sync scope:** all tables, or transactions + categories + accounts only in v0.4?
   `app_settings` is explicitly *not* synced (`DataModel.md` §7 — a device's theme choice
   must not travel).
4. **Automatic vs manual resync** after the first full push. Automatic is friendlier;
   manual protects the free quota.
5. Two doc-map entries point at files that do not exist: **`docs/Product.md`** and
   **`docs/Auth.md`** are listed in `Agent.md` §2 and `docs/README.md` items 2 and 8, but
   were never written (the same defect this file was written to fix). Write them, or
   remove them from the index?
