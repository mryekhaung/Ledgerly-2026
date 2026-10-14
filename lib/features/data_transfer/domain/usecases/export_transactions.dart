import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/export_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/repositories/data_transfer_repository.dart';

/// Exports transactions as CSV or JSON according to the given filter.
class ExportTransactions implements UseCase<ExportData, ExportFilter> {
  const ExportTransactions(this._repository);

  final DataTransferRepository _repository;

  @override
  Future<Result<ExportData>> call(ExportFilter params) =>
      _repository.exportTransactions(params);
}
