import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';

/// A user-defined label attached to a transaction.
///
/// The domain's own type — deliberately **not** the Drift row class. Keeping
/// them separate is what lets `domain/` stay pure Dart and lets the storage
/// layer change (a new column, a remote sync field) without a domain edit
/// (`docs/Architecture.md` §1, `docs/Agent.md` §3.1).
///
/// Immutable value type: every "change" is a `copyWith` returning a new
/// instance, so a notifier can diff two states by identity of value.
///
/// Spec: `docs/DataModel.md` §2.
final class Category {
  /// Creates a category.
  const Category({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.kind,
    required this.sortOrder,
    required this.isArchived,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Client-generated UUIDv4 — created offline, before any server exists
  /// (`docs/Architecture.md` ADR #3).
  final String id;

  /// Display name, unique among **active** rows (enforced in the repository,
  /// not a UNIQUE index, so a soft-deleted `Food` can be recreated).
  final String name;

  /// Catalog key resolved by `core/widgets` (e.g. `restaurant`).
  ///
  /// A key, not a code point: iOS and Android icon sets differ, so storing a
  /// raw glyph would render differently per platform.
  final String iconKey;

  /// ARGB32 accent colour. Must clear WCAG AA against surfaces
  /// (`docs/Design.md` §2.3).
  final int colorValue;

  /// Which transaction directions may use this category.
  final CategoryKind kind;

  /// Manual ordering in the category list, ascending.
  final int sortOrder;

  /// Hidden from pickers but retained in history and reports.
  ///
  /// Deliberately distinct from [deletedAt]: retiring "Rent" should remove it
  /// from the picker without erasing last year's chart.
  final bool isArchived;

  /// True only for the seeded starter categories, so a "restore defaults"
  /// action needs no schema change (`docs/DataModel.md` §6).
  final bool isDefault;

  /// UTC epoch milliseconds, set on insert.
  final int createdAt;

  /// UTC epoch milliseconds, bumped on every write so a future outbox can diff
  /// (`docs/DataModel.md` §1).
  final int updatedAt;

  /// UTC epoch milliseconds when soft-deleted, or null while live.
  final int? deletedAt;

  /// True while this row is live (not soft-deleted).
  bool get isActive => deletedAt == null;

  /// True when this category may be offered in a picker for [direction].
  ///
  /// Both [isArchived] and the direction must allow it — a category retired for
  /// a new expense must still resolve its historical rows, which is why this is
  /// a separate question from [isActive].
  bool isSelectableFor(CategoryKind direction) =>
      isActive && !isArchived && kind == direction;

  /// Returns a copy with the given fields replaced.
  ///
  /// [deletedAt] is nullable, so a plain `deletedAt ?? this.deletedAt` could
  /// never clear it. It uses a sentinel instead: pass [clearDeletedAt] to
  /// restore a soft-deleted row, which the undo affordance needs.
  Category copyWith({
    String? name,
    String? iconKey,
    int? colorValue,
    CategoryKind? kind,
    int? sortOrder,
    bool? isArchived,
    bool? isDefault,
    int? updatedAt,
    int? deletedAt,
    bool clearDeletedAt = false,
  }) => Category(
    id: id,
    name: name ?? this.name,
    iconKey: iconKey ?? this.iconKey,
    colorValue: colorValue ?? this.colorValue,
    kind: kind ?? this.kind,
    sortOrder: sortOrder ?? this.sortOrder,
    isArchived: isArchived ?? this.isArchived,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
  );

  /// Value equality across every persisted field.
  ///
  /// Includes the timestamps: two snapshots of the same category taken before
  /// and after an edit differ even when no visible field changed, and a
  /// `StreamNotifier` relies on that to emit.
  @override
  bool operator ==(Object other) =>
      other is Category &&
      other.id == id &&
      other.name == name &&
      other.iconKey == iconKey &&
      other.colorValue == colorValue &&
      other.kind == kind &&
      other.sortOrder == sortOrder &&
      other.isArchived == isArchived &&
      other.isDefault == isDefault &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    iconKey,
    colorValue,
    kind,
    sortOrder,
    isArchived,
    isDefault,
    createdAt,
    updatedAt,
    deletedAt,
  );

  @override
  String toString() =>
      'Category($id, "$name", ${kind.name}, archived: $isArchived)';
}

/// The fields a caller may set when creating or editing a category.
///
/// Exists so the form layer and the repository agree on one shape, and so
/// adding a field later touches this record and its two consumers rather than
/// every call site (`docs/Conventions.md` §1).
typedef CategoryDraft = ({
  String name,
  String iconKey,
  int colorValue,
  CategoryKind kind,
});
