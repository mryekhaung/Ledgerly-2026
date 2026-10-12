import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/repositories/transaction_repository.dart';

/// Parameters for [GetTransaction].
typedef GetTransactionParams = ({String id});

/// Loads one transaction by id — the edit page's initial read.
///
/// The repository already maps a missing row to a `NotFoundFailure`; this adds
/// the "soft-deleted counts as missing" rule so a form opened from a stale
/// route reports "this no longer exists" rather than rendering an editable
/// tombstone (`docs/Architecture.md` §8).
class GetTransaction implements UseCase<Transaction, GetTransactionParams> {
  const GetTransaction(this._repository);

  final TransactionRepository _repository;

  @override
  Future<Result<Transaction>> call(GetTransactionParams params) async {
    final result = await _repository.findById(params.id);
    return result.flatMap(
      (transaction) => transaction.isActive
          ? Success(transaction)
          : Err<Transaction>(
              NotFoundFailure(
                'Transaction ${params.id} is deleted',
                cause: null,
              ),
            ),
    );
  }
}

/// Parameters for [DeleteTransaction].
typedef DeleteTransactionParams = ({String id});

/// Soft-deletes a transaction.
///
/// Soft, not hard: the tombstone is what a v0.4 sync propagates and what the
/// undo affordance reverses (`docs/Architecture.md` ADR #4).
class DeleteTransaction implements UseCase<void, DeleteTransactionParams> {
  const DeleteTransaction(this._repository);

  final TransactionRepository _repository;

  @override
  Future<Result<void>> call(DeleteTransactionParams params) =>
      _repository.delete(params.id);
}

/// Parameters for [RestoreTransaction].
typedef RestoreTransactionParams = ({String id});

/// Undoes a soft delete — the "undo" affordance in
/// `docs/Roadmap.md` Phase 1.
///
/// Exists as its own use case rather than a `deleted = false` flag on
/// [DeleteTransaction] so the undo path cannot be reached by accident from a
/// delete call site.
class RestoreTransaction implements UseCase<void, RestoreTransactionParams> {
  const RestoreTransaction(this._repository);

  final TransactionRepository _repository;

  @override
  Future<Result<void>> call(RestoreTransactionParams params) =>
      _repository.restore(params.id);
}
