import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/domain/repositories/account_repository.dart';
import 'package:ledgerly/features/accounts/domain/validators/account_validators.dart';

final class SaveAccountParams {
  const SaveAccountParams({required this.account, this.isNew = false});

  final Account account;
  final bool isNew;
}

/// Validates and saves an account (create or update).
class SaveAccount implements UseCase<Account, SaveAccountParams> {
  const SaveAccount(this._repository);

  final AccountRepository _repository;

  @override
  Future<Result<Account>> call(SaveAccountParams params) async {
    final account = params.account;
    final normalizedName = AccountValidators.normalizeName(account.name);

    if (normalizedName.isEmpty) {
      return const Err<Account>(
        ValidationFailure(
          'Account name is required',
          fieldErrors: {'name': AccountValidators.nameRequired},
        ),
      );
    }

    if (normalizedName.length > AccountValidators.maxNameLength) {
      return const Err<Account>(
        ValidationFailure(
          'Account name is too long',
          fieldErrors: {'name': AccountValidators.nameTooLong},
        ),
      );
    }

    final existsRes = await _repository.nameExists(
      normalizedName,
      excludingId: params.isNew ? null : account.id,
    );
    if (existsRes case Err(:final failure)) return Err<Account>(failure);
    if (existsRes.valueOrNull ?? false) {
      return const Err<Account>(
        ValidationFailure(
          'Account name already exists',
          fieldErrors: {'name': AccountValidators.nameTaken},
        ),
      );
    }

    if (account.iconKey.trim().isEmpty) {
      return const Err<Account>(
        ValidationFailure(
          'Account icon is required',
          fieldErrors: {'icon': AccountValidators.iconRequired},
        ),
      );
    }

    final normalizedAccount = account.copyWith(name: normalizedName);
    return _repository.saveAccount(
      account: normalizedAccount,
      isNew: params.isNew,
    );
  }
}
