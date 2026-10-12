import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/database/tables/categories.dart';
import 'package:ledgerly/core/database/uuid.dart';

part 'categories_dao.g.dart';

/// Data access for [Categories]. Spec: `docs/DataModel.md` §2.
///
/// Every read filters `deletedAt IS NULL` — the app soft-deletes
/// (`docs/Architecture.md` ADR #4), so a plain `select(categories)` would
/// resurrect deleted rows into pickers and reports.
///
/// **Naming note:** writes are `insert`, `updateById`, `updateSortOrders` rather
/// than bare `insert`/`update`. `DatabaseAccessor` already declares
/// `update<Tbl, R>(TableInfo<Tbl, R>)` and `into<T, D>(TableInfo<T, D>)` as
/// public API (`drift/src/runtime/api/connection_user.dart`), so a method named
/// `update(String id, …)` with an incompatible signature is a compile error, not
/// an overload. Suffixing the id-based form keeps the friendly name and keeps the
/// drift builder reachable.
@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db, {Clock clock = const Clock()}) : _clock = clock;

  final Clock _clock;

  /// Active (non-deleted) categories in manual order, archived ones last.
  ///
  /// Archived categories are included: the list page shows them in a collapsed
  /// section, and only pickers filter them out.
  Stream<List<Category>> watchAll() {
    return (select(categories)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.isArchived),
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.name),
          ]))
        .watch();
  }

  /// Active, non-archived categories usable for [kind] — the picker query.
  Stream<List<Category>> watchPickable({required String kind}) {
    return (select(categories)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                t.isArchived.equals(false) &
                t.kind.equals(kind),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .watch();
  }

  Future<Category?> findById(String id) {
    return (select(
      categories,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
  }

  /// Whether an active category already uses [name].
  ///
  /// Uniqueness is checked here rather than by a UNIQUE index so that a
  /// soft-deleted `Food` does not block recreating `Food`
  /// (`docs/DataModel.md` §2).
  Future<bool> nameExists(String name, {String? excludingId}) async {
    final query = select(categories)
      ..where(
        (t) =>
            t.deletedAt.isNull() &
            t.name.equals(name) &
            (excludingId == null
                ? const Constant(true)
                : t.id.equals(excludingId).not()),
      );
    final match = await query.getSingleOrNull();
    return match != null;
  }

  /// Inserts a category, assigning a UUID and timestamps.
  ///
  /// Returns the new id. [sortOrder] defaults to the end of the list.
  ///
  /// [id] and [nowUtcMillis] are overridable so the data layer can own id
  /// generation and the clock — a test then asserts on a known id and a known
  /// timestamp without reaching around the DAO with raw SQL. Production callers
  /// omit both and get a UUIDv4 plus the wall clock.
  Future<String> insert({
    required String name,
    required String iconKey,
    required int colorValue,
    String kind = 'expense',
    int? sortOrder,
    bool isDefault = false,
    bool isArchived = false,
    String? id,
    int? nowUtcMillis,
  }) async {
    final newId = id ?? generateUuid();
    final now = nowUtcMillis ?? _clock.nowUtcMillis();
    await into(categories).insert(
      CategoriesCompanion.insert(
        id: Value(newId),
        name: name,
        iconKey: iconKey,
        colorValue: colorValue,
        kind: Value(kind),
        sortOrder: Value(sortOrder ?? await _nextSortOrder()),
        isDefault: Value(isDefault),
        isArchived: Value(isArchived),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return newId;
  }

  /// Updates the editable fields of [id]. `updatedAt` is bumped here, not by the
  /// database, so a future outbox can diff writes (`docs/DataModel.md` §1).
  ///
  /// Named `updateById`, not `update`, because `DatabaseAccessor` already
  /// declares `update<Tbl, R>(TableInfo<Tbl, R>)` — see the class doc.
  Future<void> updateById(
    String id, {
    String? name,
    String? iconKey,
    int? colorValue,
    String? kind,
    int? nowUtcMillis,
  }) {
    return (update(categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        name: name == null ? const Value.absent() : Value(name),
        iconKey: iconKey == null ? const Value.absent() : Value(iconKey),
        colorValue: colorValue == null
            ? const Value.absent()
            : Value(colorValue),
        kind: kind == null ? const Value.absent() : Value(kind),
        updatedAt: Value(nowUtcMillis ?? _clock.nowUtcMillis()),
      ),
    );
  }

  /// Soft-deletes [id] — no `DELETE` statement is ever issued.
  Future<void> softDelete(String id) {
    final now = _clock.nowUtcMillis();
    return (update(categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// Archives or unarchives [id].
  ///
  /// Distinct from [softDelete]: archiving retires a category from the picker
  /// ([watchPickable]) while keeping it in [watchAll] and in history, so last
  /// year's chart still resolves its label (`docs/DataModel.md` §2).
  Future<void> setArchived(String id, {required bool isArchived}) {
    return (update(categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        isArchived: Value(isArchived),
        updatedAt: Value(_clock.nowUtcMillis()),
      ),
    );
  }

  /// Clears the tombstone on [id] — the undo path for [softDelete].
  ///
  /// Not scoped by `deletedAt IS NOT NULL`: restoring an already-live row is a
  /// no-op that writes the same value, so a double-tap on Undo cannot corrupt
  /// anything and the caller needs no read first.
  Future<void> restore(String id) {
    final now = _clock.nowUtcMillis();
    return (update(categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(deletedAt: const Value(null), updatedAt: Value(now)),
    );
  }

  /// Rewrites `sortOrder` to match [orderedIds] — the reorder gesture's write.
  ///
  /// Runs in one transaction so the list can never be observed half-reordered.
  Future<void> reorder(List<String> orderedIds) {
    return transaction(() async {
      final now = _clock.nowUtcMillis();
      for (var i = 0; i < orderedIds.length; i++) {
        await (update(
          categories,
        )..where((t) => t.id.equals(orderedIds[i]))).write(
          CategoriesCompanion(sortOrder: Value(i), updatedAt: Value(now)),
        );
      }
    });
  }

  Future<int> _nextSortOrder() async {
    final row =
        await (selectOnly(categories)
              ..addColumns([categories.sortOrder.max()])
              ..where(categories.deletedAt.isNull()))
            .getSingle();
    return (row.read(categories.sortOrder.max()) ?? -1) + 1;
  }
}
