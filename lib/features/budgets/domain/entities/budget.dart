import 'package:ledgerly/core/money/currency_code.dart';

/// A budget cap defined for a specific category or the overall period.
///
/// Pure Dart — no Flutter, no Drift (docs/Agent.md §3.1, docs/Architecture.md §1).
///
/// When [categoryId] is null, this budget applies to all expenses combined
/// (Total Budget). When non-null, it limits spending in that single category.
///
/// When [periodId] is null, this budget recurs every month/budget-period by default.
/// When non-null (e.g. `'2026-10'`), it overrides spending for that specific period.
final class Budget {
  const Budget({
    required this.id,
    this.categoryId,
    this.periodId,
    required this.amountMinor,
    required this.currency,
    this.alertThreshold = 0.8,
    required this.sortOrder,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Client-generated UUIDv4.
  final String id;

  /// Target category id, or null for an overall total period budget.
  final String? categoryId;

  /// Specific budget period id (e.g. `'2026-10'`), or null if recurring every period.
  final String? periodId;

  /// Limit cap in minor units (unsigned: e.g. 500,000 MMK).
  final int amountMinor;

  /// Currency of this budget cap.
  final CurrencyCode currency;

  /// Fraction of [amountMinor] at which a warning alert is triggered (0.0 to 1.0, default 0.8 = 80%).
  final double alertThreshold;

  /// Ascending sort order index.
  final int sortOrder;

  /// Whether the budget is archived.
  final bool isArchived;

  /// Milliseconds since UTC epoch.
  final int createdAt;

  /// Milliseconds since UTC epoch.
  final int updatedAt;

  /// Milliseconds since UTC epoch if soft-deleted, null otherwise.
  final int? deletedAt;

  /// Whether this budget applies to all expense categories combined.
  bool get isTotalBudget => categoryId == null;

  /// Whether this budget applies to a specific category.
  bool get isCategoryBudget => categoryId != null;

  /// Whether this budget recurs every period by default.
  bool get isRecurring => periodId == null;

  /// Whether this budget is soft-deleted.
  bool get isDeleted => deletedAt != null;

  Budget copyWith({
    String? id,
    String? categoryId,
    bool clearCategoryId = false,
    String? periodId,
    bool clearPeriodId = false,
    int? amountMinor,
    CurrencyCode? currency,
    double? alertThreshold,
    int? sortOrder,
    bool? isArchived,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      periodId: clearPeriodId ? null : (periodId ?? this.periodId),
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget &&
        other.id == id &&
        other.categoryId == categoryId &&
        other.periodId == periodId &&
        other.amountMinor == amountMinor &&
        other.currency == currency &&
        other.alertThreshold == alertThreshold &&
        other.sortOrder == sortOrder &&
        other.isArchived == isArchived &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    periodId,
    amountMinor,
    currency,
    alertThreshold,
    sortOrder,
    isArchived,
    createdAt,
    updatedAt,
    deletedAt,
  );

  @override
  String toString() =>
      'Budget(id: $id, categoryId: $categoryId, periodId: $periodId, amount: $amountMinor, threshold: $alertThreshold)';
}
