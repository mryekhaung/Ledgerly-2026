import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';

/// Filter criteria for querying transactions.
///
/// Immutable value type representing search and filter parameters.
class TransactionFilter {
  const TransactionFilter({
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.categoryId,
    this.direction,
    this.minAmountMinor,
    this.maxAmountMinor,
  });

  /// An empty filter with no criteria applied.
  const TransactionFilter.empty()
      : searchQuery = null,
        startDate = null,
        endDate = null,
        categoryId = null,
        direction = null,
        minAmountMinor = null,
        maxAmountMinor = null;

  /// Text query matching note or category name.
  final String? searchQuery;

  /// Inclusive start date.
  final LocalDate? startDate;

  /// Inclusive end date.
  final LocalDate? endDate;

  /// Target category ID.
  final String? categoryId;

  /// Money direction (income or expense).
  final TransactionDirection? direction;

  /// Minimum amount in minor units.
  final int? minAmountMinor;

  /// Maximum amount in minor units.
  final int? maxAmountMinor;

  /// Returns true if any filter criteria is active (non-null and non-empty).
  bool get isActive =>
      (searchQuery != null && searchQuery!.trim().isNotEmpty) ||
      startDate != null ||
      endDate != null ||
      categoryId != null ||
      direction != null ||
      minAmountMinor != null ||
      maxAmountMinor != null;

  /// Returns true if no criteria is active.
  bool get isEmpty => !isActive;

  /// Returns a copy of this filter with the given fields replaced.
  TransactionFilter copyWith({
    String? searchQuery,
    LocalDate? startDate,
    LocalDate? endDate,
    String? categoryId,
    TransactionDirection? direction,
    int? minAmountMinor,
    int? maxAmountMinor,
    bool clearSearchQuery = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearCategoryId = false,
    bool clearDirection = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
  }) {
    return TransactionFilter(
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      direction: clearDirection ? null : (direction ?? this.direction),
      minAmountMinor:
          clearMinAmount ? null : (minAmountMinor ?? this.minAmountMinor),
      maxAmountMinor:
          clearMaxAmount ? null : (maxAmountMinor ?? this.maxAmountMinor),
    );
  }

  /// Returns an empty filter.
  TransactionFilter clear() => const TransactionFilter.empty();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionFilter &&
          other.searchQuery == searchQuery &&
          other.startDate == startDate &&
          other.endDate == endDate &&
          other.categoryId == categoryId &&
          other.direction == direction &&
          other.minAmountMinor == minAmountMinor &&
          other.maxAmountMinor == maxAmountMinor;

  @override
  int get hashCode => Object.hash(
        searchQuery,
        startDate,
        endDate,
        categoryId,
        direction,
        minAmountMinor,
        maxAmountMinor,
      );

  @override
  String toString() =>
      'TransactionFilter(query: $searchQuery, date: $startDate..$endDate, cat: $categoryId, dir: $direction, min: $minAmountMinor, max: $maxAmountMinor)';
}
