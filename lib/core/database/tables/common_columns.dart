import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/uuid.dart';
import 'package:ledgerly/core/utils/local_date.dart';

/// Shared column builders so every table spells the common fields identically.
///
/// The rules these encode live in `docs/DataModel.md` §1 — read that first.
/// Keeping them here (rather than copy-pasted per table) means a change to, say,
/// the id convention is one edit, and a table cannot accidentally drift.
///
/// A `mixin ... on Table`, **not** an `extension on Table`: an extension is not
/// mixin-able, so `class Categories extends Table with CommonColumns` would not
/// compile against one. The `on Table` clause is what makes drift's column
/// builders (`text()`, `integer()`, …) visible inside the getters.
/// `docs/DataModel.md` §1.
mixin CommonColumns on Table {
  /// Primary key: a client-generated UUIDv4.
  ///
  /// Never autoincrement — rows are created offline before any server exists, so
  /// ids must not collide on sync (`docs/Architecture.md` ADR #3).
  TextColumn get id => text().clientDefault(generateUuid)();

  /// UTC epoch milliseconds, set on insert.
  IntColumn get createdAt => integer()();

  /// UTC epoch milliseconds, bumped by the repository on every write.
  IntColumn get updatedAt => integer()();

  /// Soft delete (`docs/Architecture.md` ADR #4). Null means live.
  ///
  /// No `DELETE` statement is issued by the app; a purge only happens offline
  /// after a sync has acknowledged the tombstone.
  IntColumn get deletedAt => integer().nullable()();

  /// Manual display ordering, ascending.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Hidden from pickers but retained in history and reports.
  ///
  /// Deliberately distinct from [deletedAt]: retiring "Rent" should remove it
  /// from the picker without erasing last year's chart.
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

/// A `yyyyMMdd` calendar day stored as a packed integer.
///
/// A transaction belongs to a *day*, not an instant — storing a timestamp makes
/// a 23:30 entry on the 31st land in the next month for some timezones. See
/// `docs/DataModel.md` §3.
class LocalDateConverter extends TypeConverter<LocalDate, int> {
  const LocalDateConverter();

  @override
  LocalDate fromSql(int fromDb) {
    final date = LocalDate.fromPacked(fromDb);
    if (date == null) {
      throw ArgumentError.value(
        fromDb,
        'fromDb',
        'not a packed yyyyMMdd calendar day',
      );
    }
    return date;
  }

  @override
  int toSql(LocalDate value) => value.value;
}
