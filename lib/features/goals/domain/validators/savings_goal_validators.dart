/// Pure Dart validation rules for savings goals.
///
/// Follows the conventions of `CategoryValidators`, `BudgetValidators`,
/// and `RecurringValidators`: returns null when valid, or a stable localization
/// key string when validation fails.
final class SavingsGoalValidators {
  SavingsGoalValidators._();

  static const int maxNameLength = 100;
  static const int maxNotesLength = 500;

  /// Validates the goal name.
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'goalNameRequired';
    }
    if (name.trim().length > maxNameLength) {
      return 'goalNameTooLong';
    }
    return null;
  }

  /// Validates the target amount (must be positive).
  static String? validateTargetAmount(int? amountMinor) {
    if (amountMinor == null || amountMinor <= 0) {
      return 'goalTargetAmountInvalid';
    }
    return null;
  }

  /// Validates initial or current saved amount (cannot be negative).
  static String? validateCurrentAmount(int? amountMinor) {
    if (amountMinor == null || amountMinor < 0) {
      return 'goalCurrentAmountInvalid';
    }
    return null;
  }

  /// Validates a deposit/contribution amount.
  static String? validateContributionAmount(int? amountMinor) {
    if (amountMinor == null || amountMinor <= 0) {
      return 'goalContributionAmountInvalid';
    }
    return null;
  }

  /// Validates a withdrawal amount.
  static String? validateWithdrawalAmount({
    required int? amountMinor,
    required int currentAmountMinor,
  }) {
    if (amountMinor == null || amountMinor <= 0) {
      return 'goalWithdrawAmountInvalid';
    }
    if (amountMinor > currentAmountMinor) {
      return 'goalWithdrawExceedsBalance';
    }
    return null;
  }

  /// Validates optional notes length.
  static String? validateNotes(String? notes) {
    if (notes != null && notes.length > maxNotesLength) {
      return 'goalNotesTooLong';
    }
    return null;
  }
}
