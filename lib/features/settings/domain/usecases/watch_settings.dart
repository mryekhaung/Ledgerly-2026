import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/domain/repositories/settings_repository.dart';

/// Streams the preferences, re-emitting on every change.
///
/// This is what makes the Settings page reactive and lets `MaterialApp` follow a
/// theme or language change without a restart (`docs/Architecture.md` §7).
class WatchSettings implements StreamUseCase<AppSettings, NoParams> {
  const WatchSettings(this._repository);

  final SettingsRepository _repository;

  @override
  Stream<Result<AppSettings>> call(NoParams params) => _repository.watch();
}
