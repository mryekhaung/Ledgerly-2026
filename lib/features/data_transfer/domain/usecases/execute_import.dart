import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/import_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/repositories/data_transfer_repository.dart';

class ExecuteImportParams {
  const ExecuteImportParams({required this.preview, required this.options});

  final ImportPreview preview;
  final ImportOptions options;
}

/// Executes the database import with the validated preview and options.
class ExecuteImport implements UseCase<ImportResult, ExecuteImportParams> {
  const ExecuteImport(this._repository);

  final DataTransferRepository _repository;

  @override
  Future<Result<ImportResult>> call(ExecuteImportParams params) => _repository
      .executeImport(preview: params.preview, options: params.options);
}
