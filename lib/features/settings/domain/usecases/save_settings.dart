import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/domain/repositories/settings_repository.dart';

/// Parameters for [SaveSettings].
///
/// Takes the desired snapshot plus a `partial` flag rather than a delta: a
/// settings form edits one field at a time but always holds the whole object, and
/// re-writing four rows is trivially cheap. The flag exists so a caller that
/// genuinely wants "only touch this one key" — for example a future
/// deep-link-driven toggle — can say so, instead of the default whole-object save
/// clobbering a preference changed elsewhere.
typedef SaveSettingsParams = ({AppSettings settings, bool partial});

/// Persists the preferences.
class SaveSettings implements UseCase<AppSettings, SaveSettingsParams> {
  const SaveSettings(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Result<AppSettings>> call(SaveSettingsParams params) async {
    // A partial save would need a per-field write path; until one exists,
    // refusing is better than silently doing a full write and pretending the
    // flag was honoured. This becomes a real branch when a caller needs it.
    if (params.partial) {
      return const Err<AppSettings>(
        ValidationFailure(
          'Partial settings writes are not supported yet',
          fieldErrors: <String, String>{},
          cause: null,
        ),
      );
    }

    final result = await _repository.save(params.settings);
    return result.map((_) => params.settings);
  }
}
