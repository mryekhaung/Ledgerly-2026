import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/core/money/amount_entry.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:ledgerly/features/transactions/presentation/transaction_form_state.dart';

/// Drives the add/edit transaction form.
///
/// Holds only the form snapshot; every entry rule it applies comes from
/// `AmountEntry` and every business rule from `TransactionValidators`, so this
/// class is glue and nothing else.
class TransactionFormNotifier extends Notifier<TransactionFormState> {
  @override
  TransactionFormState build() => TransactionFormState.blank(
    currency: ref.watch(currencyProvider),
    date: _today(),
  );

  /// Seeds the form for an edit, or resets it for a create.
  void initialise({Transaction? existing, LocalDate? initialDate}) {
    state = existing == null
        ? TransactionFormState.blank(
            currency: ref.read(currencyProvider),
            date: initialDate ?? _today(),
          )
        : TransactionFormState.from(existing);
  }

  /// Appends a digit through the `AmountEntry` rules.
  ///
  /// Assigns only when the buffer actually changed, so an ignored key does not
  /// notify listeners (and therefore does not rebuild the display or fire a
  /// selection haptic).
  void enterDigit(String digit) {
    final next = AmountEntry.digit(state.entryBuffer, digit, state.currency);
    if (next == state.entryBuffer) return;
    state = state.copyWith(entryBuffer: next, clearFailure: true);
  }

  /// Appends a decimal point through the `AmountEntry` rules.
  void enterDecimalPoint() {
    final next = AmountEntry.decimalPoint(state.entryBuffer, state.currency);
    if (next == state.entryBuffer) return;
    state = state.copyWith(entryBuffer: next, clearFailure: true);
  }

  /// Removes the last character.
  void backspace() {
    final next = AmountEntry.backspace(state.entryBuffer);
    if (next == state.entryBuffer) return;
    state = state.copyWith(entryBuffer: next, clearFailure: true);
  }

  /// Clears the whole entry.
  void clear() {
    if (state.entryBuffer.isEmpty) return;
    state = state.copyWith(entryBuffer: '', clearFailure: true);
  }

  /// Sets the expense/income direction.
  void setDirection(TransactionDirection direction) =>
      state = state.copyWith(direction: direction, clearFailure: true);

  /// Sets the calendar day.
  void setDate(LocalDate date) =>
      state = state.copyWith(date: date, clearFailure: true);

  /// Sets the chosen category.
  void setCategory(String categoryId) =>
      state = state.copyWith(categoryId: categoryId, clearFailure: true);

  /// Sets the free-text note.
  void setNote(String note) =>
      state = state.copyWith(note: note, clearFailure: true);

  /// Validates and saves. Returns true when the save succeeded.
  Future<bool> save() async {
    if (state.isSaving) return false;

    final draft = state.draft;
    if (draft == null) {
      // The draft is only null for a missing category — the amount is validated
      // by the use case, which owns the `amountZero` / `amountTooLarge` rules.
      state = state.copyWith(
        fieldErrors: const <String, String>{
          'categoryId': 'transactionCategoryRequired',
        },
      );
      return false;
    }

    state = state.copyWith(isSaving: true, clearFailure: true);

    final result = await ref.read(saveTransactionProvider).call((
      id: state.existingId,
      draft: draft,
    ));

    // The notifier may have been disposed while the save was in flight.
    if (!ref.mounted) return false;

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isSaving: false,
          saved: true,
          fieldErrors: const <String, String>{},
        );
        return true;
      },
      onErr: (failure) {
        state = state.copyWith(
          isSaving: false,
          failure: failure,
          fieldErrors: failure is ValidationFailure
              ? failure.fieldErrors
              : const <String, String>{},
        );
        return false;
      },
    );
  }

  /// Today, as a calendar day in the device's local time.
  ///
  /// `DateTime.now()` rather than a UTC instant: a transaction dated "today"
  /// must match what the user's clock says, not what UTC says.
  static LocalDate _today() => LocalDate.fromDateTime(DateTime.now());
}

/// Provides the transaction form state.
///
/// `autoDispose`: a half-typed amount must not resurface on the next visit.
final transactionFormProvider =
    NotifierProvider.autoDispose<TransactionFormNotifier, TransactionFormState>(
      TransactionFormNotifier.new,
    );
