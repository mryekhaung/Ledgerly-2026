/// Failure taxonomy returned by the domain layer.
///
/// Every repository/usecase error path is expressed as a [Failure] wrapped in an
/// `Err` (see `result.dart`) — the data layer maps exceptions to these types, and the
/// presentation layer maps them to localized messages (docs/Architecture.md §8).
///
/// This file is pure Dart: no Flutter, no SDK, no packages (docs/Agent.md §3.1).
library;

/// Base type for every recoverable error the domain can produce.
///
/// Sealed so that presentation-layer mapping over failures is exhaustive —
/// adding a case becomes a compile error at every switch site.
sealed class Failure {
  const Failure(this.message, {this.cause, this.stackTrace});

  /// Technical, developer-facing description. NOT shown to users.
  ///
  /// User-facing text is resolved from the failure's runtime type via l10n in
  /// the presentation layer (`AppLocalization.failureKeyFor`).
  final String message;

  /// The original error, kept for logging. Never surfaced in the UI.
  final Object? cause;

  /// Stack trace captured at the mapping site, for logging.
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType($message)';
}

/// Local database / file-system read-write errors (Drift, path_provider, OPFS).
final class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause, super.stackTrace});
}

/// Network / transport errors (Dio timeouts, no connectivity, non-2xx).
final class NetworkFailure extends Failure {
  const NetworkFailure(
    super.message, {
    this.statusCode,
    super.cause,
    super.stackTrace,
  });

  /// HTTP status when there was a response; null for transport-level failures.
  final int? statusCode;
}

/// Authentication / authorization errors (docs/Auth.md).
final class AuthFailure extends Failure {
  const AuthFailure(
    super.message, {
    this.isCancelled = false,
    super.cause,
    super.stackTrace,
  });

  /// True when the user dismissed the sign-in sheet — not an error worth reporting.
  final bool isCancelled;
}

/// Input failed validation. [fieldErrors] keys are field names, values are
/// localization keys so the UI can render them without parsing text.
final class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, {
    this.fieldErrors = const <String, String>{},
    super.cause,
    super.stackTrace,
  });

  final Map<String, String> fieldErrors;
}

/// An entity was requested by id and does not exist.
final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.cause, super.stackTrace});
}

/// A write conflicts with existing state — unique constraint, stale sync revision.
final class ConflictFailure extends Failure {
  const ConflictFailure(super.message, {super.cause, super.stackTrace});
}

/// Import/export payload could not be parsed or is structurally invalid.
final class ParseFailure extends Failure {
  const ParseFailure(
    super.message, {
    this.rowNumber,
    super.cause,
    super.stackTrace,
  });

  /// 1-based row in the source file, when applicable, for import error reporting.
  final int? rowNumber;
}

/// Catch-all. Should be rare — reaching this means the data layer missed a mapping.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.cause, super.stackTrace});
}
