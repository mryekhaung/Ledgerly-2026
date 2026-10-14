import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/data_transfer/data/json/backup_json_codec.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/backup_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/create_full_backup.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/restore_full_backup.dart';

class BackupRestoreState {
  const BackupRestoreState({
    this.isCreatingBackup = false,
    this.isRestoring = false,
    this.backupJson,
    this.loadedMetadata,
    this.restoreResult,
    this.failure,
  });

  final bool isCreatingBackup;
  final bool isRestoring;
  final String? backupJson;
  final BackupMetadata? loadedMetadata;
  final RestoreResult? restoreResult;
  final Failure? failure;

  BackupRestoreState copyWith({
    bool? isCreatingBackup,
    bool? isRestoring,
    String? backupJson,
    BackupMetadata? loadedMetadata,
    RestoreResult? restoreResult,
    Failure? failure,
    bool clearBackupJson = false,
    bool clearMetadata = false,
    bool clearRestoreResult = false,
    bool clearFailure = false,
  }) {
    return BackupRestoreState(
      isCreatingBackup: isCreatingBackup ?? this.isCreatingBackup,
      isRestoring: isRestoring ?? this.isRestoring,
      backupJson: clearBackupJson ? null : (backupJson ?? this.backupJson),
      loadedMetadata: clearMetadata
          ? null
          : (loadedMetadata ?? this.loadedMetadata),
      restoreResult: clearRestoreResult
          ? null
          : (restoreResult ?? this.restoreResult),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class BackupRestoreNotifier extends Notifier<BackupRestoreState> {
  BackupRestoreNotifier({
    this.createUseCase,
    this.restoreUseCase,
    this.codec = const BackupJsonCodec(),
  });

  final CreateFullBackup? createUseCase;
  final RestoreFullBackup? restoreUseCase;
  final BackupJsonCodec codec;

  @override
  BackupRestoreState build() => const BackupRestoreState();

  Future<void> createBackup() async {
    final useCase = createUseCase;
    if (useCase == null) return;

    state = state.copyWith(
      isCreatingBackup: true,
      clearFailure: true,
      clearRestoreResult: true,
    );

    final res = await useCase(const NoParams());
    state = switch (res) {
      Success(:final value) => state.copyWith(
        isCreatingBackup: false,
        backupJson: value,
        loadedMetadata: codec.extractMetadata(value),
      ),
      Err(:final failure) => state.copyWith(
        isCreatingBackup: false,
        failure: failure,
      ),
    };
  }

  void loadBackupPayload(String jsonString) {
    try {
      final metadata = codec.extractMetadata(jsonString);
      state = state.copyWith(
        backupJson: jsonString,
        loadedMetadata: metadata,
        clearFailure: true,
        clearRestoreResult: true,
      );
    } on FormatException catch (e) {
      state = state.copyWith(
        failure: ParseFailure(e.message),
        clearMetadata: true,
      );
    }
  }

  Future<void> restoreBackup({required RestoreMode mode}) async {
    final useCase = restoreUseCase;
    final json = state.backupJson;
    if (useCase == null || json == null) return;

    state = state.copyWith(
      isRestoring: true,
      clearFailure: true,
      clearRestoreResult: true,
    );

    final res = await useCase(
      RestoreFullBackupParams(backupJson: json, mode: mode),
    );

    state = switch (res) {
      Success(:final value) => state.copyWith(
        isRestoring: false,
        restoreResult: value,
      ),
      Err(:final failure) => state.copyWith(
        isRestoring: false,
        failure: failure,
      ),
    };
  }

  void reset() {
    state = const BackupRestoreState();
  }
}
