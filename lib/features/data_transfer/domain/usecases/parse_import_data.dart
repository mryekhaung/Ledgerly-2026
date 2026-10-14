import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/import_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/repositories/data_transfer_repository.dart';

class ParseImportDataParams {
  const ParseImportDataParams({
    required this.content,
    required this.format,
    this.customMapping,
  });

  final String content;
  final ImportFormat format;
  final ImportColumnMapping? customMapping;
}

/// Parses raw text content (CSV or JSON) and produces an [ImportPreview].
class ParseImportData implements UseCase<ImportPreview, ParseImportDataParams> {
  const ParseImportData(this._repository);

  final DataTransferRepository _repository;

  @override
  Future<Result<ImportPreview>> call(ParseImportDataParams params) =>
      _repository.parseImportData(
        content: params.content,
        format: params.format,
        customMapping: params.customMapping,
      );
}
