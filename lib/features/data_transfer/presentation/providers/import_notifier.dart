import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/import_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/execute_import.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/parse_import_data.dart';

class ImportState {
  const ImportState({
    this.rawContent,
    this.format = ImportFormat.csv,
    this.preview,
    this.options = const ImportOptions(),
    this.isParsing = false,
    this.isImporting = false,
    this.result,
    this.failure,
  });

  final String? rawContent;
  final ImportFormat format;
  final ImportPreview? preview;
  final ImportOptions options;
  final bool isParsing;
  final bool isImporting;
  final ImportResult? result;
  final Failure? failure;

  ImportState copyWith({
    String? rawContent,
    ImportFormat? format,
    ImportPreview? preview,
    ImportOptions? options,
    bool? isParsing,
    bool? isImporting,
    ImportResult? result,
    Failure? failure,
    bool clearPreview = false,
    bool clearResult = false,
    bool clearFailure = false,
  }) {
    return ImportState(
      rawContent: rawContent ?? this.rawContent,
      format: format ?? this.format,
      preview: clearPreview ? null : (preview ?? this.preview),
      options: options ?? this.options,
      isParsing: isParsing ?? this.isParsing,
      isImporting: isImporting ?? this.isImporting,
      result: clearResult ? null : (result ?? this.result),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class ImportNotifier extends Notifier<ImportState> {
  ImportNotifier({this.parseUseCase, this.executeUseCase});

  final ParseImportData? parseUseCase;
  final ExecuteImport? executeUseCase;

  @override
  ImportState build() => const ImportState();

  Future<void> loadAndParse({
    required String content,
    required ImportFormat format,
    ImportColumnMapping? customMapping,
  }) async {
    final useCase = parseUseCase;
    if (useCase == null) return;

    state = state.copyWith(
      rawContent: content,
      format: format,
      isParsing: true,
      clearPreview: true,
      clearResult: true,
      clearFailure: true,
    );

    final res = await useCase(
      ParseImportDataParams(
        content: content,
        format: format,
        customMapping: customMapping,
      ),
    );

    state = switch (res) {
      Success(:final value) => state.copyWith(isParsing: false, preview: value),
      Err(:final failure) => state.copyWith(isParsing: false, failure: failure),
    };
  }

  void updateMapping(int columnIndex, ImportFieldType fieldType) {
    final currentPreview = state.preview;
    final raw = state.rawContent;
    if (currentPreview == null || raw == null) return;

    final updatedMapping = currentPreview.mapping.withField(
      columnIndex,
      fieldType,
    );
    unawaited(
      loadAndParse(
        content: raw,
        format: state.format,
        customMapping: updatedMapping,
      ),
    );
  }

  void updateOptions(ImportOptions options) {
    state = state.copyWith(options: options);
  }

  /// Switches the parse format (CSV/JSON). The format is read at parse time,
  /// so changing it must update state — re-applying the current options (as
  /// the old call site did) silently ignores the tap.
  void setFormat(ImportFormat format) {
    state = state.copyWith(format: format);
  }

  Future<void> executeImport() async {
    final useCase = executeUseCase;
    final preview = state.preview;
    if (useCase == null || preview == null) return;

    state = state.copyWith(
      isImporting: true,
      clearFailure: true,
      clearResult: true,
    );

    final res = await useCase(
      ExecuteImportParams(preview: preview, options: state.options),
    );

    state = switch (res) {
      Success(:final value) => state.copyWith(
        isImporting: false,
        result: value,
      ),
      Err(:final failure) => state.copyWith(
        isImporting: false,
        failure: failure,
      ),
    };
  }

  void reset() {
    state = const ImportState();
  }
}
