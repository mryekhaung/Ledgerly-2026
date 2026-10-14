import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_filter.dart';
import 'package:ledgerly/features/transactions/domain/repositories/transaction_repository.dart';

/// Parameters for [SearchTransactions].
typedef SearchTransactionsParams = ({
  TransactionFilter filter,
  int limit,
  int offset,
});

/// Searches and filters transactions with limit/offset pagination.
class SearchTransactions
    implements UseCase<List<Transaction>, SearchTransactionsParams> {
  const SearchTransactions(this._repository);

  final TransactionRepository _repository;

  @override
  Future<Result<List<Transaction>>> call(SearchTransactionsParams params) {
    return _repository.searchTransactions(
      filter: params.filter,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
