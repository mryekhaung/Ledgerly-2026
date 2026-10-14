/// Field-level validation rules for budget limits and configurations.
///
/// Pure Dart — no Flutter, no Drift (docs/Agent.md §3.1).
abstract final class BudgetValidators {
  const BudgetValidators._();

  /// Validation key returned when a budget amount is zero or negative.
  static const String amountInvalid = 'budgetAmountInvalid';

  /// Validation key returned when an alert threshold is outside the valid range [0.1, 1.0].
  static const String thresholdInvalid = 'budgetThresholdInvalid';

  /// Validation key returned when a category already has an active budget for the specified period.
  static const String duplicateCategory = 'budgetDuplicateCategory';

  /// Validation key returned when a total overall budget already exists for the specified period.
  static const String duplicateTotal = 'budgetDuplicateTotal';

  /// Validates [amountMinor].
  static String? validateAmount(int amountMinor) {
    if (amountMinor <= 0) return amountInvalid;
    return null;
  }

  /// Validates [threshold].
  static String? validateThreshold(double threshold) {
    if (threshold < 0.1 || threshold > 1.0) return thresholdInvalid;
    return null;
  }
}
