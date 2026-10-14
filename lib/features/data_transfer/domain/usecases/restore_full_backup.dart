import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/backup_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/repositories/data_transfer_repository.dart';

class RestoreFullBackupParams {
  const RestoreFullBackupParams({required this.backupJson, required this.mode});

  final String backupJson;
  final RestoreMode mode;
}

/// Restores a full backup from a JSON archive string.
class RestoreFullBackup
    implements UseCase<RestoreResult, RestoreFullBackupParams> {
  const RestoreFullBackup(this._repository);

  final DataTransferRepository _repository;

  @override
  Future<Result<RestoreResult>> call(RestoreFullBackupParams params) =>
      _repository.restoreFullBackup(
        backupJson: params.backupJson,
        mode: params.mode,
      );
}
