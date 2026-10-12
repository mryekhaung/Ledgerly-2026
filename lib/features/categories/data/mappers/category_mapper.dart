import 'package:drift/drift.dart' show Value;
import 'package:ledgerly/core/database/app_database.dart' as db;
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';

/// Translates between the Drift row class and the pure-Dart [Category] entity.
///
/// This is the **only** place the two representations meet. Keeping it here —
/// rather than letting the domain entity carry drift annotations or letting DAOs
/// return domain types — is what holds the layer boundary: `domain/` never
/// imports `package:drift` (`docs/Agent.md` §3.1, `docs/Architecture.md` §2).
///
/// **Name collision:** drift generates its row class as `Category`, the same
/// name as our entity. Both names are fixed by their owners (drift's by
/// convention, ours by `docs/Conventions.md` §1), so this file disambiguates by
/// importing the generated database **prefixed** and referring to the row as
/// `db.Category`.
///
/// Mappers are static and allocation-free so they can sit in a `Stream.map`
/// without a per-event object.
abstract final class CategoryMapper {
  const CategoryMapper._();

  /// Converts a Drift row into a domain entity.
  ///
  /// `kind` is stored as TEXT; an unrecognised value falls back to
  /// [CategoryKind.expense] rather than throwing. A row written by a newer app
  /// version (or an import) must not crash the list page — the alternative is a
  /// permanently un-openable screen. The fallback is a *display* default, not a
  /// rewrite: nothing is written back unless the user saves the form.
  static Category toEntity(db.Category row) => Category(
    id: row.id,
    name: row.name,
    iconKey: row.iconKey,
    colorValue: row.colorValue,
    kind: CategoryKind.tryParse(row.kind) ?? CategoryKind.expense,
    sortOrder: row.sortOrder,
    isArchived: row.isArchived,
    isDefault: row.isDefault,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  );

  /// Converts a list of rows, preserving order.
  static List<Category> toEntities(List<db.Category> rows) =>
      rows.map(toEntity).toList(growable: false);

  /// Builds the insert companion for a new category.
  ///
  /// `id` and [nowUtcMillis] are supplied by the datasource — the mapper owns
  /// neither the id generator nor the clock (`docs/Conventions.md` §1).
  static db.CategoriesCompanion toInsertCompanion({
    required String id,
    required CategoryDraft draft,
    required int sortOrder,
    required int nowUtcMillis,
    bool isDefault = false,
  }) => db.CategoriesCompanion.insert(
    id: Value(id),
    name: draft.name,
    iconKey: draft.iconKey,
    colorValue: draft.colorValue,
    kind: Value(draft.kind.storageValue),
    sortOrder: Value(sortOrder),
    isDefault: Value(isDefault),
    createdAt: nowUtcMillis,
    updatedAt: nowUtcMillis,
  );

  /// Builds the update companion for an edit.
  ///
  /// Every field is materialised rather than `Value.absent()`: the edit form
  /// always submits a complete draft, so an absent field would silently keep a
  /// value the user had just changed.
  static db.CategoriesCompanion toUpdateCompanion({
    required CategoryDraft draft,
    required int nowUtcMillis,
  }) => db.CategoriesCompanion(
    name: Value(draft.name),
    iconKey: Value(draft.iconKey),
    colorValue: Value(draft.colorValue),
    kind: Value(draft.kind.storageValue),
    updatedAt: Value(nowUtcMillis),
  );
}
