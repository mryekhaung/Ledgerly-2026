import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';

/// Immutable state for the add/edit transaction form.
///
/// Pure Dart so the keypad's digit handling and the draft it produces are
/// unit-testable without a widget tree — the amount entry is the one part of
/// this screen where a bug costs the user real money
/// (`docs/Agent.md` §6).
///
/// The amount is held as an **entry buffer** (the digits the user has typed),
/// not as a [Money]. A buffer cannot lose a trailing decimal point or a leading
/// zero the way a parsed number would, and the parse happens once, on submit.
final class TransactionFormState {
  /// Creates form state.
  const TransactionFormState({
    required this.entryBuffer,
    required this.currency,
    required this.direction,
    required this.date,
    this.categoryId,
    this.note = '',
    this.existingId,
    this.isSaving = false,
    this.fieldErrors = const <String, String>{},
    this.failure,
    this.saved = false,
  });

  /// State for a brand-new transaction.
  ///
  /// Starts on an empty buffer rather than `0`, so the display shows the
  /// currency placeholder instead of a misleading zero.
  factory TransactionFormState.blank({
    required CurrencyCode currency,
    required LocalDate date,
    TransactionDirection direction = TransactionDirection.expense,
  }) => TransactionFormState(
    entryBuffer: '',
    currency: currency,
    direction: direction,
    date: date,
  );

  /// State prefilled from an existing transaction.
  ///
  /// The buffer is seeded from the stored magnitude with the minor digits the
  /// currency has, so editing a `1000` MMK row shows `1000` and not `10.00`.
  factory TransactionFormState.from(Transaction transaction) =>
      TransactionFormState(
        entryBuffer: _bufferFor(transaction.amount),
        currency: transaction.amount.currency,
        direction: transaction.direction,
        date: transaction.date,
        categoryId: transaction.categoryId,
        note: transaction.note ?? '',
        existingId: transaction.id,
      );

  /// The raw digits the user has entered, e.g. `'12.5'`.
  final String entryBuffer;

  /// The currency amounts are entered in.
  ///
  /// Fixed for the life of the form: a currency switch mid-entry would silently
  /// reinterpret the digits already typed.
  final CurrencyCode currency;

  /// Expense or income.
  final TransactionDirection direction;

  /// The transaction's calendar day.
  final LocalDate date;

  /// The chosen category, or null while nothing is picked.
  final String? categoryId;

  /// Free-text note.
  final String note;

  /// The id being edited, or null when creating.
  final String? existingId;

  /// True while the save is in flight.
  final bool isSaving;

  /// Per-field validation errors, keyed by field name.
  final Map<String, String> fieldErrors;

  /// The last save failure, or null.
  final Failure? failure;

  /// True once the save succeeded, so the page can pop.
  final bool saved;

  /// True when editing rather than creating.
  bool get isEditing => existingId != null;

  /// The parsed amount, or null when the buffer is not a usable number.
  ///
  /// Uses `Money.tryParseAmountMinor`, so a partially typed value (`'12.'`)
  /// resolves rather than throwing — the keypad lets the user submit from any
  /// state, and validation reports a zero or an overflow separately.
  Money? get amount {
    final minor = Money.tryParseAmountMinor(entryBuffer, currency);
    return minor == null ? null : Money.minor(minor, currency);
  }

  /// True when the buffer holds nothing but an empty or malformed entry.
  bool get hasEntry => entryBuffer.isNotEmpty;

  /// The draft this form describes, or null when the amount cannot be parsed.
  TransactionDraft? get draft {
    final resolved = amount;
    final category = categoryId;
    if (resolved == null || category == null) return null;
    return (
      categoryId: category,
      amount: resolved,
      direction: direction,
      date: date,
      note: note.trim().isEmpty ? null : note.trim(),
    );
  }

  /// Returns a copy with the given fields replaced.
  ///
  /// Field errors and the failure are cleared on every edit by default: a stale
  /// "pick a category" must not survive the user picking one.
  TransactionFormState copyWith({
    String? entryBuffer,
    TransactionDirection? direction,
    LocalDate? date,
    String? categoryId,
    String? note,
    bool? isSaving,
    Map<String, String>? fieldErrors,
    Failure? failure,
    bool? saved,
    bool clearFailure = false,
  }) => TransactionFormState(
    entryBuffer: entryBuffer ?? this.entryBuffer,
    currency: currency,
    direction: direction ?? this.direction,
    date: date ?? this.date,
    categoryId: categoryId ?? this.categoryId,
    note: note ?? this.note,
    existingId: existingId,
    isSaving: isSaving ?? this.isSaving,
    fieldErrors: fieldErrors ?? const <String, String>{},
    failure: clearFailure ? null : (failure ?? this.failure),
    saved: saved ?? this.saved,
  );

  /// Seeds the keypad buffer from a stored [money] amount.
  ///
  /// `exponent 0` currencies (MMK, JPY, KRW) have no decimal point at all, so
  /// they render as whole units; others get the minor digits back.
  static String _bufferFor(Money money) {
    final digits = money.amountMinor.abs().toString();
    final exponent = money.currency.exponent;
    if (exponent == 0) return digits;
    // Left-pad so `5` with exponent 2 becomes `0.05`, not `.5`.
    final padded = digits.padLeft(exponent + 1, '0');
    final split = padded.length - exponent;
    return '${padded.substring(0, split)}.${padded.substring(split)}';
  }
}
