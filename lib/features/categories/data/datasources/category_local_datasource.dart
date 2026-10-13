import 'package:ledgerly/core/database/app_database.dart' as db;
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/database/uuid.dart';
import 'package:ledgerly/features/categories/data/mappers/category_mapper.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';

/// Reads and writes categories in the local SQLite database.
///
/// The datasource owns **every** Drift type. Nothing above it — repository,
/// use case, notifier — imports `package:drift`, which is what makes the store
/// behind the repository replaceable (`docs/Architecture.md` §4).
///
/// It returns domain entities rather than raw rows so the mapper runs once per
/// read, at the boundary, instead of at each call site.
class CategoryLocalDataSource {
  CategoryLocalDataSource(
    this._database, {
    this.clock = const Clock(),
    this.idGenerator = generateUuid,
  });

  final db.AppDatabase _database;
  final Clock clock;

  /// Injected so a test can assert on a known id — the production default is a
  /// UUIDv4 (`docs/Architecture.md` ADR #3).
  final String Function() idGenerator;

  /// Active and archived categories in manual order, archived ones last.
  Stream<List<Category>> watchAll() =>
      _database.categoriesDao.watchAll().map(CategoryMapper.toEntities);

  /// Non-archived, active categories usable for [kind].
  Stream<List<Category>> watchPickable({required CategoryKind kind}) =>
      _database.categoriesDao
          .watchPickable(kind: kind.storageValue)
          .map(CategoryMapper.toEntities);

  /// The live category with [id], or null when missing or soft-deleted.
  Future<Category?> findById(String id) async {
    final row = await _database.categoriesDao.findById(id);
    return row == null ? null : CategoryMapper.toEntity(row);
  }

  /// Inserts [draft] and returns the stored row.
  ///
  /// The insert and the read-back share one `transaction` so a concurrent write
  /// cannot make the read return null for a row we just created — which would
  /// otherwise surface as a spurious `NotFoundFailure` on a successful create.
  Future<Category> create(CategoryDraft draft) =>
      _database.transaction(() async {
        final id = _generatedId();
        final now = clock.nowUtcMillis();
        await _database.categoriesDao.insert(
          id: id,
          nowUtcMillis: now,
          name: draft.name,
          iconKey: draft.iconKey,
          colorValue: draft.colorValue,
          kind: draft.kind.storageValue,
        );
        final row = await _database.categoriesDao.findById(id);
        // Non-null by construction: the row was written inside this transaction
        // and only a soft delete could hide it, and none ran.
        return CategoryMapper.toEntity(row!);
      });

  /// Applies [draft] to [id] and returns the updated row.
  ///
  /// Throws [CategoryNotFoundException] when the row does not exist; the
  /// repository maps that to a `NotFoundFailure` (`docs/Architecture.md` §8).
  Future<Category> update(String id, CategoryDraft draft) =>
      _database.transaction(() async {
        final now = clock.nowUtcMillis();
        await _database.categoriesDao.updateById(
          id,
          nowUtcMillis: now,
          name: draft.name,
          iconKey: draft.iconKey,
          colorValue: draft.colorValue,
          kind: draft.kind.storageValue,
        );
        final row = await _database.categoriesDao.findById(id);
        if (row == null) throw CategoryNotFoundException(id);
        return CategoryMapper.toEntity(row);
      });

  /// Soft-deletes [id]. No row leaves disk (`docs/Architecture.md` ADR #4).
  Future<void> delete(String id) => _database.categoriesDao.softDelete(id);

  /// Undoes a soft delete by clearing the tombstone.
  Future<void> restore(String id) => _database.categoriesDao.restore(id);

  /// Archives or unarchives [id].
  Future<void> setArchived(String id, {required bool isArchived}) =>
      _database.categoriesDao.setArchived(id, isArchived: isArchived);

  /// Rewrites `sortOrder` to match [orderedIds], in one transaction.
  Future<void> reorder(List<String> orderedIds) =>
      _database.categoriesDao.reorder(orderedIds);

  /// Whether an active category other than [excludingId] already uses [name].
  Future<bool> nameExists(String name, {String? excludingId}) =>
      _database.categoriesDao.nameExists(name, excludingId: excludingId);

  /// A UUIDv4, or a deterministic value in a test.
  ///
  /// Falls back to a generated id when the injected generator returns blank, so
  /// a mis-wired test fixture cannot write an empty primary key and shadow the
  /// real failure with a constraint violation.
  String _generatedId() {
    final id = idGenerator();
    return id.isEmpty ? generateUuid() : id;
  }
}

/// Thrown when a category is expected to exist and does not.
///
/// A data-layer signal, not a domain failure: the repository catches it and
/// returns a `NotFoundFailure` so `domain/` never sees an exception
/// (`docs/Architecture.md` §8).
final class CategoryNotFoundException implements Exception {
  const CategoryNotFoundException(this.id);

  /// The id that could not be found.
  final String id;

  @override
  String toString() => 'CategoryNotFoundException($id)';
}
