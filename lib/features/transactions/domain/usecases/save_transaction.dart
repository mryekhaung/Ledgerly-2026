import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:ledgerly/features/transactions/domain/validators/transaction_validators.dart';

/// Parameters for [SaveTransaction].
///
/// [id] null means "create"; a value means "update". One use case for both
/// because the form is one form — splitting it would duplicate the validation
/// that is the only interesting part.
typedef SaveTransactionParams = ({String? id, TransactionDraft draft});

/// Validates and persists a transaction, create or update.
///
/// The single gate every write passes through, so the invariants
/// `docs/DataModel.md` §3 relies on — a **positive** magnitude with the sign in
/// the direction, a note within the column length — cannot be bypassed by a
/// caller.
///
/// Returns a [ValidationFailure] with `fieldErrors` mapping a field name to a
/// localization key, so the form can mark the offending field without parsing
/// text.
class SaveTransaction implements UseCase<Transaction, SaveTransactionParams> {
  const SaveTransaction(this._repository);

  final TransactionRepository _repository;

  @override
  Future<Result<Transaction>> call(SaveTransactionParams params) async {
    final draft = params.draft;
    final id = params.id;

    final fieldError = TransactionValidators.draftError(draft);
    if (fieldError != null) {
      return Err<Transaction>(
        ValidationFailure(
          'Transaction draft is invalid: $fieldError',
          fieldErrors: <String, String>{_fieldFor(fieldError): fieldError},
        ),
      );
    }

    // The amount is stored unsigned and the direction carries the sign, so the
    // magnitude is normalised here rather than trusting every caller to have
    // done it. `Money.abs()` keeps the currency, which a bare `.abs()` on an int
    // would lose.
    final normalised = (
      categoryId: draft.categoryId,
      amount: draft.amount.abs(),
      direction: draft.direction,
      date: draft.date,
      note: TransactionValidators.normalizeNote(draft.note),
    );

    return id == null
        ? _repository.create(normalised)
        : _repository.update(id, normalised);
  }

  /// Maps a validator key to the form field it belongs to.
  static String _fieldFor(String validationKey) => switch (validationKey) {
    TransactionValidators.amountZero ||
    TransactionValidators.amountTooLarge => 'amount',
    TransactionValidators.directionUnsupported => 'direction',
    TransactionValidators.categoryRequired => 'categoryId',
    _ => 'note',
  };
}
