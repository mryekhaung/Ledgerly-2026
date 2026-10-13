import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/database/daos/app_settings_dao.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/features/settings/data/datasources/settings_keys.dart';
import 'package:ledgerly/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';

import '../../../core/database/db_harness.dart';

/// The settings datasource: the encode/decode boundary.
///
/// The cases that matter are the *unhappy* ones. A preference read from disk can
/// be missing (first launch), an empty string (a partial write), or a value from
/// a future build — and none of those may throw, because this runs during app
/// startup before any screen exists to show an error.
void main() {
  SettingsLocalDataSource make() {
    final harness = useDbHarness();
    return SettingsLocalDataSource(
      AppSettingsDao(harness.db, clock: harness.clock),
    );
  }

  group('read on a fresh install', () {
    test('returns the defaults', () async {
      final datasource = make();
      expect(await datasource.read(), AppSettings.defaults);
    });
  });

  group('write and read round-trip', () {
    test('persists every field', () async {
      final datasource = make();
      const settings = AppSettings(
        currency: CurrencyCode.eur,
        themeMode: AppThemeMode.dark,
        weekStart: WeekStart.sunday,
        localeCode: 'ja',
      );

      await datasource.write(settings);
      expect(await datasource.read(), settings);
    });

    test('a null locale is stored as an absent row, not a sentinel', () async {
      final harness = useDbHarness();
      final dao = AppSettingsDao(harness.db, clock: harness.clock);
      final datasource = SettingsLocalDataSource(dao);

      await datasource.write(
        AppSettings.defaults.copyWith(currency: CurrencyCode.usd),
      );

      // Read the table itself rather than decoding — the point of this test is
      // what is physically stored.
      final keys = (await dao.readAll()).keys.toSet();
      expect(keys, isNot(contains(SettingsKeys.locale)));
      expect(keys, contains(SettingsKeys.currency));
      expect(
        await datasource.read(),
        isA<AppSettings>().having((s) => s.localeCode, 'localeCode', isNull),
      );
    });

    test('clearing a previously-set locale removes the row', () async {
      final datasource = make();
      await datasource.write(AppSettings.defaults.copyWith(localeCode: 'my'));
      expect((await datasource.read()).localeCode, 'my');

      await datasource.write((await datasource.read()).clearLocale());
      expect((await datasource.read()).localeCode, isNull);
    });
  });

  group('decode resilience', () {
    test(
      'an unknown currency falls back to the default, not a failure',
      () async {
        final harness = useDbHarness();
        final datasource = SettingsLocalDataSource(
          AppSettingsDao(harness.db, clock: harness.clock),
        );

        await harness.db.customStatement(
          'INSERT INTO app_settings (key, value, updated_at) VALUES '
          "('${SettingsKeys.currency}', 'xxx', 1)",
        );

        // Must not throw: this runs before the first frame.
        expect(
          (await datasource.read()).currency,
          AppSettings.defaults.currency,
        );
      },
    );

    test('an unknown theme mode falls back to the default', () async {
      final harness = useDbHarness();
      final datasource = SettingsLocalDataSource(
        AppSettingsDao(harness.db, clock: harness.clock),
      );

      await harness.db.customStatement(
        'INSERT INTO app_settings (key, value, updated_at) VALUES '
        "('${SettingsKeys.themeMode}', 'sepia', 1)",
      );

      expect(
        (await datasource.read()).themeMode,
        AppSettings.defaults.themeMode,
      );
    });

    test(
      'an empty locale string decodes to null, not to an empty tag',
      () async {
        final harness = useDbHarness();
        final datasource = SettingsLocalDataSource(
          AppSettingsDao(harness.db, clock: harness.clock),
        );

        await harness.db.customStatement(
          'INSERT INTO app_settings (key, value, updated_at) VALUES '
          "('${SettingsKeys.locale}', '', 1)",
        );

        expect((await datasource.read()).localeCode, isNull);
      },
    );

    test('a good value survives alongside a corrupt one', () async {
      final harness = useDbHarness();
      final datasource = SettingsLocalDataSource(
        AppSettingsDao(harness.db, clock: harness.clock),
      );

      await harness.db.customStatement(
        'INSERT INTO app_settings (key, value, updated_at) VALUES '
        "('${SettingsKeys.currency}', 'usd', 1), "
        "('${SettingsKeys.themeMode}', 'bogus', 1)",
      );

      final settings = await datasource.read();
      expect(settings.currency, CurrencyCode.usd);
      expect(settings.themeMode, AppSettings.defaults.themeMode);
    });
  });

  group('watch', () {
    test('emits on write', () async {
      final datasource = make();
      final emissions = <AppSettings>[];
      final sub = datasource.watch().listen(emissions.add);

      await pumpEventQueue();
      await datasource.write(
        AppSettings.defaults.copyWith(themeMode: AppThemeMode.dark),
      );
      await pumpEventQueue();
      await sub.cancel();

      expect(emissions.first, AppSettings.defaults);
      expect(emissions.last.themeMode, AppThemeMode.dark);
    });
  });
}
