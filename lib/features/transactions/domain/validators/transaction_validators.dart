import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';

/// Field-level validation for a transaction form.
///
/// Lives in `domain/` so the form, the CSV import, and a future sync payload all
/// apply the same rules (`docs/Architecture.md` §11). Returns **localization
/// keys**, never sentences — the UI resolves them from ARB
/// (`docs/Conventions.md` §5).
///
/// Pure Dart: no Flutter, no Drift (`docs/Agent.md` §3.1).
abstract final class TransactionValidators {
  const TransactionValidators._();

  /// Maximum note length. Mirrors `withLength(max: 500)` in
  /// `tables/transactions.dart` — the schema is the source of truth.
  static const int maxNoteLength = 500;

  /// Validation key for a zero amount.
  ///
  /// Zero is rejected rather than stored: a `0` transaction is almost always an
  /// unfinished entry, and it pollutes every aggregate without changing any of
  /// them.
  static const String amountZero = 'transactionAmountZero';

  /// Validation key for an amount larger than [Money.maxDigits] allows.
  static const String amountTooLarge = 'transactionAmountTooLarge';

  /// Validation key for a note longer than [maxNoteLength].
  static const String noteTooLong = 'transactionNoteTooLong';

  /// Validation key for a missing category.
  static const String categoryRequired = 'transactionCategoryRequired';

  /// Validation key for a direction v0.1 cannot store meaningfully.
  static const String directionUnsupported = 'transactionDirectionUnsupported';

  /// The first problem with [draft], or null when it is valid.
  ///
  /// Order matches the form: amount → direction → category → note, so the user
  /// is pointed at the topmost problem.
  static String? draftError(TransactionDraft draft) {
    final amount = amountError(draft.amount);
    if (amount != null) return amount;

    final direction = directionError(draft.direction);
    if (direction != null) return direction;

    final category = categoryError(draft.categoryId);
    if (category != null) return category;

    return noteError(draft.note);
  }

  /// The first problem with [amount], or null when it is acceptable.
  static String? amountError(Money amount) {
    if (amount.isZero) return amountZero;
    // Digits, not magnitude: `Money.maxDigits` caps the significant-digit count
    // because that is what bounds the intermediate products on web, where `int`
    // is a JS number (`core/money/money.dart`).
    final digits = amount.amountMinor.abs().toString().length;
    return digits > Money.maxDigits ? amountTooLarge : null;
  }

  /// The first problem with [direction], or null when it is acceptable.
  static String? directionError(TransactionDirection direction) =>
      direction.isSelectableInV1 ? null : directionUnsupported;

  /// The first problem with [categoryId], or null when it is acceptable.
  static String? categoryError(String categoryId) =>
      categoryId.trim().isEmpty ? categoryRequired : null;

  /// The first problem with [note], or null when it is acceptable.
  ///
  /// Null and whitespace-only are both fine — a note is optional. Trailing
  /// whitespace is not an error either; the caller normalises it.
  static String? noteError(String? note) {
    if (note == null) return null;
    return note.trim().length > maxNoteLength ? noteTooLong : null;
  }

  /// Trims [note] to its storage form, mapping blank to null.
  ///
  /// A note of `'   '` becomes `null`, not `''`, so "has a note" and "empty
  /// note" are one state rather than two — which is what lets the row widget
  /// decide whether to render a second line at all.
  static String? normalizeNote(String? note) {
    final trimmed = note?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// Whether [date] is in the future relative to [today].
  ///
  /// Not an error — a user may log a planned expense — so this is a *hint* the
  /// form may use for a warning, deliberately kept out of [draftError].
  ///
  /// Rejects dates outside the packed `yyyyMMdd` range implicitly, since
  /// [LocalDate] cannot represent them.
  static bool isFuture(LocalDate date, {required LocalDate today}) =>
      date.isAfter(today);
}
