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
        'StorageFailure' => 'failure.storage',
        'NetworkFailure' => 'failure.network',
        'AuthFailure' => 'failure.auth',
        'ValidationFailure' => 'failure.validation',
        'NotFoundFailure' => 'failure.notFound',
        'ConflictFailure' => 'failure.conflict',
        'ParseFailure' => 'failure.parse',
        'UnexpectedFailure' => 'failure.unexpected',
        _ => 'failure.unexpected',
      };
}
