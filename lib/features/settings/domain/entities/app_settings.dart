import 'package:ledgerly/core/money/currency_code.dart';

/// The theme preference.
///
/// A domain enum, **not** Flutter's `ThemeMode`: `domain/` must stay pure Dart
/// (`docs/Agent.md` §3.1, enforced by the CI `banned-imports` job). The
/// presentation layer maps this to `ThemeMode` in one place.
enum AppThemeMode {
  /// Follow the OS setting. The default.
  system,

  light,

  dark;

  /// Resolves from a stored [name], or null when the value is unrecognized.
  ///
  /// Returning null rather than defaulting is deliberate: a value written by a
  /// future version that added a fourth mode must not silently become `system`.
  static AppThemeMode? tryParse(String value) {
    for (final mode in AppThemeMode.values) {
      if (mode.name == value) return mode;
    }
    return null;
  }
}

/// Which day a week begins on — drives the calendar grid's column order.
///
/// Only the two real-world conventions are offered. `monday` is the default
/// because the calendar was built Monday-first (`MonthGridLayout`), and because
/// ISO 8601 and most of the app's target markets use it.
enum WeekStart {
  monday(DateTime.monday),
  sunday(DateTime.sunday);

  const WeekStart(this.dateTimeWeekday);

  /// The matching `DateTime` weekday constant (1 = Monday, 7 = Sunday).
  ///
  /// `intl`'s `DateFormat` and Flutter's `MaterialLocalizations` both speak this
  /// numbering, so the conversion lives here once instead of at each call site.
  final int dateTimeWeekday;

  /// Resolves from a stored [name], or null when unrecognized.
  static WeekStart? tryParse(String value) {
    for (final start in WeekStart.values) {
      if (start.name == value) return start;
    }
    return null;
  }
}

/// The user's app-wide preferences, resolved into one immutable value.
///
/// The Settings page edits this; `app.dart` reads it to drive
/// `MaterialApp.themeMode` / `.locale`; the transaction form and calendar read
/// `currency` and `weekStart`. Loading it once into a single object means those
/// readers cannot disagree mid-session, which a set of independent lookups
/// could.
///
/// Spec: `docs/DataModel.md` §7.
final class AppSettings {
  /// Creates a settings snapshot.
  const AppSettings({
    required this.currency,
    required this.themeMode,
    required this.weekStart,
    this.localeCode,
    this.monthStartDay = 1,
  }) : assert(
         monthStartDay >= 1 && monthStartDay <= 28,
         'monthStartDay must be 1..28 (docs/DataModel.md §8).',
       );

  /// The defaults for a fresh install, and the fallback when a stored value is
  /// unreadable.
  ///
  /// MMK + Monday-first mirrors the primary market; `system` theme respects the
  /// OS; a null locale follows the device; month start day 1 is the standard
  /// calendar month.
  static const AppSettings defaults = AppSettings(
    currency: CurrencyCode.mmk,
    themeMode: AppThemeMode.system,
    weekStart: WeekStart.monday,
    monthStartDay: 1,
  );

  /// The currency every amount is denominated in.
  final CurrencyCode currency;

  /// Light / dark / follow the OS.
  final AppThemeMode themeMode;

  /// First column of the calendar grid.
  final WeekStart weekStart;

  /// BCP-47 language tag (`en`, `my`, `ja`), or null to follow the device.
  ///
  /// Nullable and a `String` rather than a `Locale`: `domain/` does not import
  /// Flutter, and "no explicit choice" is a real third state that must survive a
  /// round-trip (`Locale('en')` cannot express it).
  final String? localeCode;

  /// Day of the month (1–28) on which each budget period begins.
  ///
  /// 1 represents a standard calendar month (the default). Any other day
  /// (e.g. 10th) represents a pay-cycle month (e.g. Oct 10 – Nov 9).
  final int monthStartDay;

  /// A copy with the given fields replaced.
  ///
  /// [localeCode] is settable to null explicitly via [clearLocale] rather than
  /// here, because `copyWith(localeCode: null)` is indistinguishable from "not
  /// supplied" — a footgun that would make "follow the device" unselectable once
  /// a language had been chosen.
  AppSettings copyWith({
    CurrencyCode? currency,
    AppThemeMode? themeMode,
    WeekStart? weekStart,
    String? localeCode,
    int? monthStartDay,
  }) => AppSettings(
    currency: currency ?? this.currency,
    themeMode: themeMode ?? this.themeMode,
    weekStart: weekStart ?? this.weekStart,
    localeCode: localeCode ?? this.localeCode,
    monthStartDay: monthStartDay ?? this.monthStartDay,
  );

  /// A copy that follows the device locale again.
  AppSettings clearLocale() => AppSettings(
    currency: currency,
    themeMode: themeMode,
    weekStart: weekStart,
    monthStartDay: monthStartDay,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.currency == currency &&
      other.themeMode == themeMode &&
      other.weekStart == weekStart &&
      other.localeCode == localeCode &&
      other.monthStartDay == monthStartDay;

  @override
  int get hashCode =>
      Object.hash(currency, themeMode, weekStart, localeCode, monthStartDay);

  @override
  String toString() =>
      'AppSettings(currency: ${currency.code}, themeMode: ${themeMode.name}, '
      'weekStart: ${weekStart.name}, localeCode: $localeCode, '
      'monthStartDay: $monthStartDay)';
}
