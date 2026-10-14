/// Field-level validation for an account form and transfer draft.
///
/// Pure Dart — no Flutter, no Drift (docs/Agent.md §3.1).
library;

abstract final class AccountValidators {
  const AccountValidators._();

  /// Maximum display-name length. Matches the `withLength(max: 60)` column in
  /// `tables/accounts.dart`.
  static const int maxNameLength = 60;

  /// Validation key returned when a name is empty or whitespace-only.
  static const String nameRequired = 'accountNameRequired';

  /// Validation key returned when a name is longer than [maxNameLength].
  static const String nameTooLong = 'accountNameTooLong';

  /// Validation key returned when a name is already taken by another account.
  static const String nameTaken = 'accountNameTaken';

  /// Validation key returned when no icon has been chosen.
  static const String iconRequired = 'accountIconRequired';

  /// Validation key returned when a colour is not a valid opaque ARGB value.
  static const String colorInvalid = 'accountColorInvalid';

  /// Validation key returned when a transfer source and target are the same account.
  static const String transferSameAccount = 'accountTransferSameAccount';

  /// Validation key returned when a transfer amount is non-positive.
  static const String transferAmountInvalid = 'accountTransferAmountInvalid';

  /// Trims a raw name to its storage form.
  static String normalizeName(String raw) => raw.trim();

  /// Validates [rawName].
  static String? nameError(
    String rawName, {
    Iterable<String> existingNames = const <String>[],
  }) {
    final normalized = normalizeName(rawName);
    if (normalized.isEmpty) return nameRequired;
    if (normalized.length > maxNameLength) return nameTooLong;

    final lowered = normalized.toLowerCase();
    for (final existing in existingNames) {
      if (normalizeName(existing).toLowerCase() == lowered) return nameTaken;
    }
    return null;
  }

  /// Validates a transfer between [fromAccountId] and [toAccountId] for [amountMinor].
  static String? transferError({
    required String? fromAccountId,
    required String? toAccountId,
    required int amountMinor,
  }) {
    if (fromAccountId == null || toAccountId == null) return null;
    if (fromAccountId == toAccountId) return transferSameAccount;
    if (amountMinor <= 0) return transferAmountInvalid;
    return null;
  }
}
