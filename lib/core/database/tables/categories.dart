import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/tables/common_columns.dart';

/// A user-defined label attached to a transaction.
///
/// Spec: `docs/DataModel.md` §2. Seeded with defaults on first launch (§6).
@TableIndex(
  name: 'idx_categories_list',
  columns: {#deletedAt, #isArchived, #sortOrder},
)
@TableIndex(name: 'idx_categories_kind', columns: {#kind, #deletedAt})
class Categories extends Table with CommonColumns {
  /// Display name.
  ///
  /// Uniqueness among *active* rows is enforced in `CategoriesDao`, not by a
  /// UNIQUE index: a soft-deleted `Food` must not block recreating `Food`.
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// Catalog key resolved by `core/widgets` (e.g. `restaurant`).
  ///
  /// A key, not a code point — icon sets differ between iOS and Android, so
  /// storing a raw glyph would render differently per platform.
  TextColumn get iconKey => text()();

  /// ARGB32 accent colour. Must clear WCAG AA against surfaces (`Design.md` §2.3).
  IntColumn get colorValue => integer()();

  /// Which transaction directions may use this category.
  ///
  /// Stored as the enum `name`, never an ordinal: reordering the enum must not
  /// silently reinterpret existing rows (`docs/DataModel.md` §1).
  TextColumn get kind => text().withDefault(const Constant('expense'))();

  /// True only for the seeded starter categories, so a
  /// "restore default categories" action needs no schema change.
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
