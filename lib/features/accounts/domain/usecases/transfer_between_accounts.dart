import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/accounts/domain/entities/account_transfer.dart';
import 'package:ledgerly/features/accounts/domain/repositories/account_repository.dart';
import 'package:ledgerly/features/accounts/domain/validators/account_validators.dart';

/// Transfers funds between two accounts.
class TransferBetweenAccounts implements UseCase<void, AccountTransfer> {
  const TransferBetweenAccounts(this._repository);

  final AccountRepository _repository;

  @override
  Future<Result<void>> call(AccountTransfer transfer) async {
    final validationError = AccountValidators.transferError(
      fromAccountId: transfer.fromAccountId,
      toAccountId: transfer.toAccountId,
      amountMinor: transfer.amount.amountMinor,
    );

    if (validationError != null) {
      return Err<void>(
        ValidationFailure(
          'Transfer is invalid: $validationError',
          fieldErrors: {'transfer': validationError},
        ),
      );
    }

    return _repository.transferFunds(transfer);
  }
}
