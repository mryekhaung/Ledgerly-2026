import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/domain/repositories/settings_repository.dart';

/// Loads the current preferences once, at startup.
///
/// The app reads settings through the *stream* ([WatchSettings]) for everything
/// that must react to a change; this one-shot read exists for the pre-first-frame
/// path in `app.dart`, where a stream's initial `null` would flash the wrong
/// theme for a frame.
class LoadSettings implements UseCase<AppSettings, NoParams> {
  const LoadSettings(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Result<AppSettings>> call(NoParams params) => _repository.load();
}
