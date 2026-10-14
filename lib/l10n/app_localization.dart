/// Localization configuration.
///
/// The generated bindings (`AppLocalizations`) come from `flutter gen-l10n`,
/// driven by `l10n.yaml` at the repo root and the ARB files in `lib/l10n/`.
///
/// This file holds only the hand-written constants and the failure→message key
/// mapping, so the presentation layer never builds user-facing strings by
/// concatenation (docs/Conventions.md §5).
abstract final class AppLocalization {
  const AppLocalization._();

  /// Locales the app ships. `en` is the fallback.
  static const List<String> supportedLocales = <String>['en', 'my', 'ja'];

  /// Fallback locale when the device asks for something we don't have.
  static const String fallbackLocale = 'en';

  /// ARB key for a failure type.
  ///
  /// Keeps the mapping from domain `Failure` to user-facing string in one place,
  /// exhaustive over the sealed hierarchy (docs/Architecture.md §8).
  static String failureKeyFor(String failureRuntimeType) =>
      switch (failureRuntimeType) {
        'StorageFailure' => 'failureStorage',
        'NetworkFailure' => 'failureNetwork',
        'AuthFailure' => 'failureAuth',
        'ValidationFailure' => 'failureValidation',
        'NotFoundFailure' => 'failureNotFound',
        'ConflictFailure' => 'failureConflict',
        'ParseFailure' => 'failureParse',
        'UnexpectedFailure' => 'failureUnexpected',
        _ => 'failureUnexpected',
      };

  /// ARB key for a **validator key** carried in `ValidationFailure.fieldErrors`.
  ///
  /// Validators emit stable domain keys such as `categoryNameRequired` rather
  /// than ARB keys, because `domain/` must not know about the l10n catalog
  /// (`docs/Agent.md` §3.1). This is the single place that bridges the two, so a
  /// new validator message is added here and nowhere else.
  ///
  /// Falls back to the generic validation message for an unknown key, so a
  /// validator added ahead of its translation still shows something readable.
  static String validationKeyFor(String validatorKey) => switch (validatorKey) {
    'categoryNameRequired' => 'categoriesNameRequired',
    'categoryNameTooLong' => 'categoriesNameTooLong',
    'categoryNameTaken' => 'categoriesNameTaken',
    'categoryIconRequired' => 'categoriesIconRequired',
    'categoryColorInvalid' => 'categoriesColorInvalid',
    'transactionAmountZero' => 'transactionAmountZero',
    'transactionAmountTooLarge' => 'transactionAmountTooLarge',
    'transactionNoteTooLong' => 'transactionNoteTooLong',
    'transactionCategoryRequired' => 'transactionCategoryRequired',
    'transactionDirectionUnsupported' => 'transactionDirectionUnsupported',
    'accountNameRequired' => 'accountsNameRequired',
    'accountNameTooLong' => 'accountsNameTooLong',
    'accountNameTaken' => 'accountsNameTaken',
    'transferSameAccount' => 'accountsTransferSameAccount',
    'transferAmountNonPositive' => 'accountsTransferAmountInvalid',
    'transferAmountZero' => 'accountsTransferAmountInvalid',
    'budgetAmountInvalid' => 'budgetAmountInvalid',
    'budgetThresholdInvalid' => 'budgetThresholdInvalid',
    'budgetDuplicateCategory' => 'budgetDuplicateCategory',
    'budgetDuplicateTotal' => 'budgetDuplicateTotal',
    _ => 'failureValidation',
  };
}
