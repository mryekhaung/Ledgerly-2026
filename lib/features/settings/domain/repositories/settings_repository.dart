import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';

/// Reads and writes the app's preferences.
///
/// Phase 1 has a single local store, but the interface exists now so the
/// presentation layer never sees the datasource and a future remote/云-synced
/// preference store is a new implementation rather than a refactor of every call
/// site (`docs/Architecture.md` §4).
abstract interface class SettingsRepository {
  /// The current preferences. Never fails on a *decoding* problem — an
  /// unreadable value falls back to its default; a failure means storage itself
  /// is unavailable.
  Future<Result<AppSettings>> load();

  /// The current preferences, re-emitted whenever they change.
  Stream<Result<AppSettings>> watch();

  /// Persists [settings] in full.
  Future<Result<void>> save(AppSettings settings);
}
