import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/database/tables/accounts.dart';
import 'package:ledgerly/core/database/uuid.dart';

part 'accounts_dao.g.dart';

/// Data access for [Accounts]. Spec: `docs/DataModel.md` §4.
///
/// **No UI consumes this yet** — accounts ship in Phase 3 (`docs/Roadmap.md`).
/// The DAO exists so the v1 schema's `transactions.accountId` has a complete
/// counterpart from day one, and so the v1 → v2 work is additive.
///
/// Note: this DAO holds **balances**, which unlike transaction amounts are signed
/// (`openingBalanceMinor`). See the rationale in `docs/DataModel.md` §4.
///
/// **Naming note:** the id-based write is `updateById`, not `update` —
/// `DatabaseAccessor` already declares `update<Tbl, R>(TableInfo<Tbl, R>)`
/// (`drift/src/runtime/api/connection_user.dart`), so an incompatible
/// `update(String id, …)` fails to override and does not compile.
@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db, {this.clock = const Clock()});

  final Clock clock;

  /// Live accounts in manual order, archived last.
  Stream<List<Account>> watchAll() {
    return (select(accounts)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.isArchived),
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.name),
          ]))
        .watch();
  }

  Future<Account?> findById(String id) {
    return (select(
      accounts,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
  }

  Future<String> insert({
    required String name,
    required String type,
    required String currency,
    required int openingBalanceMinor,
    required String iconKey,
    required int colorValue,
    int? sortOrder,
    bool includeInTotal = true,
    bool isArchived = false,
  }) async {
    final id = generateUuid();
    final now = clock.nowUtcMillis();
    await into(accounts).insert(
      AccountsCompanion.insert(
        id: Value(id),
        name: name,
        type: type,
        currency: currency,
        openingBalanceMinor: openingBalanceMinor,
        iconKey: iconKey,
        colorValue: colorValue,
        sortOrder: Value(sortOrder ?? await _nextSortOrder()),
        includeInTotal: Value(includeInTotal),
        isArchived: Value(isArchived),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  /// Updates the editable fields of [id]. See the class doc for the `updateById`
  /// name.
  Future<void> updateById(
    String id, {
    String? name,
    String? type,
    String? currency,
    int? openingBalanceMinor,
    String? iconKey,
    int? colorValue,
    bool? includeInTotal,
  }) {
    return (update(accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(
        name: name == null ? const Value.absent() : Value(name),
        type: type == null ? const Value.absent() : Value(type),
        currency: currency == null ? const Value.absent() : Value(currency),
        openingBalanceMinor: openingBalanceMinor == null
            ? const Value.absent()
            : Value(openingBalanceMinor),
        iconKey: iconKey == null ? const Value.absent() : Value(iconKey),
        colorValue: colorValue == null
            ? const Value.absent()
            : Value(colorValue),
        includeInTotal: includeInTotal == null
            ? const Value.absent()
            : Value(includeInTotal),
        updatedAt: Value(clock.nowUtcMillis()),
      ),
    );
  }

  Future<void> softDelete(String id) {
    final now = clock.nowUtcMillis();
    return (update(accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// Archives or unarchives [id].
  ///
  /// Distinct from [softDelete]: archiving a closed card retires it from the
  /// picker while keeping its history and its balance contribution intact
  /// (`docs/DataModel.md` §4). An archived account still appears in
  /// [watchAll] — sorted last — so the user can unarchive it.
  Future<void> setArchived(String id, {required bool isArchived}) {
    return (update(accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(
        isArchived: Value(isArchived),
        updatedAt: Value(clock.nowUtcMillis()),
      ),
    );
  }

  /// Rewrites `sortOrder` to match [orderedIds] — the reorder gesture's write.
  ///
  /// Runs in one transaction so the list can never be observed half-reordered.
  Future<void> reorder(List<String> orderedIds) {
    return transaction(() async {
      final now = clock.nowUtcMillis();
      for (var i = 0; i < orderedIds.length; i++) {
        await (update(
          accounts,
        )..where((t) => t.id.equals(orderedIds[i]))).write(
          AccountsCompanion(sortOrder: Value(i), updatedAt: Value(now)),
        );
      }
    });
  }

  Future<int> _nextSortOrder() async {
    final row =
        await (selectOnly(accounts)
              ..addColumns([accounts.sortOrder.max()])
              ..where(accounts.deletedAt.isNull()))
            .getSingle();
    return (row.read(accounts.sortOrder.max()) ?? -1) + 1;
  }
}
