import 'package:ledgerly/core/utils/local_date.dart';

/// Validation rules for creating and editing recurring transaction definitions.
///
/// Pure Dart — no Flutter, no Drift (docs/Agent.md §3.1).
abstract final class RecurringValidators {
  const RecurringValidators._();

  static const String amountInvalid = 'recurringErrorAmountPositive';
  static const String categoryRequired = 'recurringErrorCategoryRequired';
  static const String endDateBeforeStart = 'recurringErrorEndDateBeforeStart';

  /// Validates the recurring amount: must be non-null and strictly greater than zero.
  static String? validateAmount(int? amountMinor) {
    if (amountMinor == null || amountMinor <= 0) {
      return amountInvalid;
    }
    return null;
  }

  /// Validates the category id: must be non-empty.
  static String? validateCategory(String? categoryId) {
    if (categoryId == null || categoryId.trim().isEmpty) {
      return categoryRequired;
    }
    return null;
  }

  /// Validates start and end dates: if end date is set, it must not be before start date.
  static String? validateDates(LocalDate startDate, LocalDate? endDate) {
    if (endDate != null && endDate.isBefore(startDate)) {
      return endDateBeforeStart;
    }
    return null;
  }
}
