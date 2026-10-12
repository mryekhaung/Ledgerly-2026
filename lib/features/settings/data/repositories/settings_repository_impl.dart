import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/result/result_guard.dart';
import 'package:ledgerly/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/domain/repositories/settings_repository.dart';

/// Drift-backed [SettingsRepository].
///
/// Every call is funnelled through `guardResult` / `guardResultStream` — the
/// single seam where a `data/` exception becomes a `Failure`
/// (`docs/Architecture.md` §8). No `try`/`catch` appears above this line.
class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._local);

  final SettingsLocalDataSource _local;

  @override
  Future<Result<AppSettings>> load() => guardResult(_local.read);

  @override
  Stream<Result<AppSettings>> watch() => guardResultStream(_local.watch());

  @override
  Future<Result<void>> save(AppSettings settings) =>
      guardResult(() => _local.write(settings));
}
