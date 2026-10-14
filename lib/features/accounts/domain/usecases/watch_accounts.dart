import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/domain/repositories/account_repository.dart';

/// Parameters for [WatchAccounts].
final class WatchAccountsParams {
  const WatchAccountsParams({this.includeArchived = false});

  final bool includeArchived;
}

/// Watches live accounts, sorted by user preference.
class WatchAccounts
    implements StreamUseCase<List<Account>, WatchAccountsParams> {
  const WatchAccounts(this._repository);

  final AccountRepository _repository;

  @override
  Stream<Result<List<Account>>> call(WatchAccountsParams params) {
    return _repository.watchAccounts(includeArchived: params.includeArchived);
  }
}
