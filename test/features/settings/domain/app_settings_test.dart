import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';

/// `AppSettings` and its two enums — the value semantics the whole settings
/// feature rests on.
///
/// The important behaviours here are the ones an `==` or a `copyWith` getting
/// wrong would silently break elsewhere: the Settings page decides whether to
/// save by comparing snapshots, so a bad `==` would either skip a real write or
/// issue a pointless one.
void main() {
  group('AppSettings.defaults', () {
    test('is MMK, system theme, Monday-first, device locale', () {
      const defaults = AppSettings.defaults;
      expect(defaults.currency, CurrencyCode.mmk);
      expect(defaults.themeMode, AppThemeMode.system);
      expect(defaults.weekStart, WeekStart.monday);
      expect(defaults.localeCode, isNull);
    });
  });

  group('copyWith', () {
    test('replaces only the named field', () {
      final base = AppSettings.defaults.copyWith(currency: CurrencyCode.usd);
      expect(base.currency, CurrencyCode.usd);
      expect(base.themeMode, AppThemeMode.system);
      expect(base.weekStart, WeekStart.monday);
      expect(base.localeCode, isNull);
    });

    test('sets a locale code', () {
      final updated = AppSettings.defaults.copyWith(localeCode: 'my');
      expect(updated.localeCode, 'my');
    });

    test('cannot clear a locale code — that is what clearLocale is for', () {
      final withLocale = AppSettings.defaults.copyWith(localeCode: 'ja');
      // `copyWith(localeCode: null)` is indistinguishable from "not supplied",
      // so it must leave the existing value alone rather than clearing it.
      final attempted = withLocale.copyWith(themeMode: AppThemeMode.dark);
      expect(attempted.localeCode, 'ja');
    });

    test('clearLocale drops the code and keeps everything else', () {
      final withLocale = AppSettings.defaults.copyWith(
        localeCode: 'my',
        themeMode: AppThemeMode.dark,
        currency: CurrencyCode.jpy,
      );
      final cleared = withLocale.clearLocale();

      expect(cleared.localeCode, isNull);
      expect(cleared.themeMode, AppThemeMode.dark);
      expect(cleared.currency, CurrencyCode.jpy);
      expect(cleared.weekStart, WeekStart.monday);
    });
  });

  group('equality', () {
    test('equal when every field matches', () {
      const a = AppSettings(
        currency: CurrencyCode.usd,
        themeMode: AppThemeMode.dark,
        weekStart: WeekStart.sunday,
        localeCode: 'ja',
      );
      const b = AppSettings(
        currency: CurrencyCode.usd,
        themeMode: AppThemeMode.dark,
        weekStart: WeekStart.sunday,
        localeCode: 'ja',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differs when any single field differs', () {
      const base = AppSettings.defaults;
      expect(base, isNot(equals(base.copyWith(currency: CurrencyCode.eur))));
      expect(base, isNot(equals(base.copyWith(themeMode: AppThemeMode.light))));
      expect(base, isNot(equals(base.copyWith(weekStart: WeekStart.sunday))));
      expect(base, isNot(equals(base.copyWith(localeCode: 'en'))));
    });

    test('a null locale differs from an explicit one', () {
      const followDevice = AppSettings.defaults;
      final explicit = AppSettings.defaults.copyWith(localeCode: 'en');
      expect(followDevice, isNot(equals(explicit)));
    });
  });

  group('AppThemeMode.tryParse', () {
    test('round-trips every declared value', () {
      for (final mode in AppThemeMode.values) {
        expect(AppThemeMode.tryParse(mode.name), mode);
      }
    });

    test('returns null for an unknown value rather than defaulting', () {
      // A value written by a future build that added a fourth mode must not be
      // silently reinterpreted as `system`.
      expect(AppThemeMode.tryParse('sepia'), isNull);
      expect(AppThemeMode.tryParse(''), isNull);
    });
  });

  group('WeekStart', () {
    test('maps to the matching DateTime weekday', () {
      expect(WeekStart.monday.dateTimeWeekday, DateTime.monday);
      expect(WeekStart.sunday.dateTimeWeekday, DateTime.sunday);
    });

    test('round-trips every declared value', () {
      for (final start in WeekStart.values) {
        expect(WeekStart.tryParse(start.name), start);
      }
    });

    test('returns null for an unknown value', () {
      expect(WeekStart.tryParse('friday'), isNull);
    });
  });
}
