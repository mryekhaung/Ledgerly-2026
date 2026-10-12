import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/domain/usecases/load_settings.dart';
import 'package:ledgerly/features/settings/domain/usecases/save_settings.dart';
import 'package:ledgerly/features/settings/domain/usecases/watch_settings.dart';

import 'fake_settings_repository.dart';

/// The settings use cases.
///
/// These are thin — the interesting behaviour is at the repository boundary, so
/// the tests focus on what these classes add: defaults on a fresh read, the
/// `partial` guard, and the mapping of a save's `void` onto the saved snapshot.
void main() {
  late FakeSettingsRepository repository;

  setUp(() => repository = FakeSettingsRepository());

  group('LoadSettings', () {
    test('returns the stored snapshot', () async {
      repository = FakeSettingsRepository(
        initial: const AppSettings(
          currency: CurrencyCode.usd,
          themeMode: AppThemeMode.dark,
          weekStart: WeekStart.sunday,
          localeCode: 'ja',
        ),
      );

      final result = await LoadSettings(repository).call(const NoParams());

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.currency, CurrencyCode.usd);
      expect(result.valueOrNull?.localeCode, 'ja');
    });

    test('a fresh install yields the defaults', () async {
      final result = await LoadSettings(repository).call(const NoParams());
      expect(result.valueOrNull, AppSettings.defaults);
    });

    test('propagates a storage failure', () async {
      repository.failure = const StorageFailure('disk gone', cause: null);

      final result = await LoadSettings(repository).call(const NoParams());

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });

  group('WatchSettings', () {
    test('emits the current value first', () async {
      final stream = WatchSettings(repository).call(const NoParams());
      final first = await stream.first;

      expect(first.isSuccess, isTrue);
      expect(first.valueOrNull, AppSettings.defaults);
    });

    test('emits again after a save', () async {
      final emissions = <Result<AppSettings>>[];
      final sub = WatchSettings(repository)
          .call(const NoParams())
          .listen(emissions.add);

      await pumpEventQueue();
      await repository.save(
        AppSettings.defaults.copyWith(themeMode: AppThemeMode.light),
      );
      await pumpEventQueue();
      await sub.cancel();

      expect(emissions.first.valueOrNull, AppSettings.defaults);
      expect(emissions.last.valueOrNull?.themeMode, AppThemeMode.light);
    });

    test('a failure surfaces as a stream error value, not a throw', () async {
      repository.failure = const StorageFailure('unreadable', cause: null);

      final result = await WatchSettings(repository).call(const NoParams()).first;

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });

  group('SaveSettings', () {
    test('persists and returns the saved snapshot', () async {
      const next = AppSettings(
        currency: CurrencyCode.jpy,
        themeMode: AppThemeMode.light,
        weekStart: WeekStart.sunday,
      );

      final result = await SaveSettings(repository).call((
        settings: next,
        partial: false,
      ));

      expect(result.valueOrNull, next);
      expect(repository.lastSaved, next);
      expect(repository.saveCount, 1);
    });

    test('a partial save is refused rather than silently doing a full write', () async {
      final result = await SaveSettings(repository).call((
        settings: AppSettings.defaults,
        partial: true,
      ));

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      // The important half: nothing was written.
      expect(repository.saveCount, 0);
    });

    test('propagates a storage failure', () async {
      repository.failure = const StorageFailure('read-only', cause: null);

      final result = await SaveSettings(repository).call((
        settings: AppSettings.defaults,
        partial: false,
      ));

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });
}
