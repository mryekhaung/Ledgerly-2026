import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/data_transfer/domain/repositories/data_transfer_repository.dart';

/// Generates a full Ledgerly backup JSON archive.
class CreateFullBackup implements UseCase<String, NoParams> {
  const CreateFullBackup(this._repository);

  final DataTransferRepository _repository;

  @override
  Future<Result<String>> call(NoParams params) =>
      _repository.createFullBackup();
}
