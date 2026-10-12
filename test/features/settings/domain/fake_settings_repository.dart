import 'dart:async';

import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/domain/repositories/settings_repository.dart';

/// An in-memory [SettingsRepository] for use-case tests.
///
/// Holds the current snapshot in a subject-like controller so a test can assert
/// that a save is *observed* by a watcher, which is the actual contract that
/// makes the Settings page repaint.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({AppSettings? initial})
    : _current = initial ?? AppSettings.defaults;

  AppSettings _current;

  /// When set, `load`/`watch`/`save` fail with this instead of succeeding.
  Failure? failure;

  /// Counts saves, so a test can prove a no-op did not write.
  int saveCount = 0;

  /// The last snapshot handed to [save], or null if never called.
  AppSettings? lastSaved;

  final StreamController<AppSettings> _controller =
      StreamController<AppSettings>.broadcast();

  /// The snapshot currently held.
  AppSettings get current => _current;

  @override
  Future<Result<AppSettings>> load() async {
    if (failure case final failure?) return Err<AppSettings>(failure);
    return Success(_current);
  }

  @override
  Stream<Result<AppSettings>> watch() async* {
    if (failure case final failure?) {
      yield Err<AppSettings>(failure);
      return;
    }
    yield Success(_current);
    yield* _controller.stream.map(Success<AppSettings>.new);
  }

  @override
  Future<Result<void>> save(AppSettings settings) async {
    saveCount++;
    if (failure case final failure?) return Err<void>(failure);
    lastSaved = settings;
    _current = settings;
    _controller.add(settings);
    return const Success<void>(null);
  }

  /// Releases the stream controller. Wired via `addTearDown` in tests that watch.
  Future<void> dispose() => _controller.close();
}
