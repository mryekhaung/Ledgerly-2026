import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/di/injection.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/period_calculator.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/domain/usecases/load_settings.dart';
import 'package:ledgerly/features/settings/domain/usecases/save_settings.dart';
import 'package:ledgerly/features/settings/domain/usecases/watch_settings.dart';

/// Thin bridge between get_it and Riverpod for the settings use cases.
///
/// `docs/Architecture.md` §5: presentation state lives in Riverpod; the use-case
/// instances come from the locator. Plain `Provider`s (not auto-disposed) —
/// a use case is stateless, so rebuilding one per screen allocates for nothing.
final loadSettingsProvider = Provider<LoadSettings>(
  (_) => getIt<LoadSettings>(),
);

/// Bridge for [WatchSettings].
final watchSettingsProvider = Provider<WatchSettings>(
  (_) => getIt<WatchSettings>(),
);

/// Bridge for [SaveSettings].
final saveSettingsProvider = Provider<SaveSettings>(
  (_) => getIt<SaveSettings>(),
);

/// The live preferences, as an `AsyncValue`.
///
/// **`keepAlive`, not `autoDispose`.** This is the one provider that *every*
/// screen depends on — the currency on every amount, the theme on the whole
/// tree, the locale on every string. An auto-disposing provider would re-read
/// the table during a route transition and briefly emit the default, which would
/// flash MMK over a USD amount. App-wide state is exactly the documented
/// exception to the autoDispose default (`docs/Agent.md` §6).
///
/// A stream error collapses to the defaults rather than surfacing a failure: the
/// app must still launch and be usable if preferences cannot be read, and
/// `MaterialApp` cannot await an error state anyway.
final settingsProvider = StreamProvider<AppSettings>((ref) {
  final stream = ref.watch(watchSettingsProvider).call(const NoParams());
  return stream.map(
    (result) => result.fold(
      onSuccess: (settings) => settings,
      onErr: (_) => AppSettings.defaults,
    ),
  );
});

/// The current preferences synchronously, defaulting while the first read lands.
///
/// Every reader that just needs *a* currency or *a* week start uses this, so no
/// call site has to render a loading state for a value that always exists in
/// practice (SQLite read of four rows, tens of milliseconds).
final currentSettingsProvider = Provider<AppSettings>(
  (ref) => ref.watch(settingsProvider).value ?? AppSettings.defaults,
);

/// The currency the app is denominated in.
///
/// Kept as its own provider (rather than every amount reading
/// [currentSettingsProvider]) so a widget depends on exactly what it uses: an
/// amount repaints on a currency change but not on a week-start change.
final currencyProvider = Provider<CurrencyCode>(
  (ref) => ref.watch(currentSettingsProvider).currency,
  name: 'currency',
);

/// The first day of the calendar week.
final weekStartProvider = Provider<WeekStart>(
  (ref) => ref.watch(currentSettingsProvider).weekStart,
  name: 'weekStart',
);

/// The theme preference. `app.dart` maps this onto `MaterialApp.themeMode`.
final themeModeProvider = Provider<AppThemeMode>(
  (ref) => ref.watch(currentSettingsProvider).themeMode,
  name: 'themeMode',
);

/// The explicit language tag, or null to follow the device.
final localeCodeProvider = Provider<String?>(
  (ref) => ref.watch(currentSettingsProvider).localeCode,
  name: 'localeCode',
);

/// The day of the month (1–28) on which each budget period begins.
final monthStartDayProvider = Provider<int>(
  (ref) => ref.watch(currentSettingsProvider).monthStartDay,
  name: 'monthStartDay',
);

/// The calculator deriving budget periods from the stored [monthStartDayProvider].
final periodCalculatorProvider = Provider<PeriodCalculator>(
  (ref) => PeriodCalculator(ref.watch(monthStartDayProvider)),
  name: 'periodCalculator',
);

/// Writes preferences and returns the stored snapshot.
///
/// A function provider, not a state notifier: the stream is the single source of
/// truth, so a notifier holding its own copy would be a second one to keep in
/// sync. Callers `ref.read(saveSettingsProvider)((settings: …, partial: false))`
/// and let [settingsProvider] emit the result.
final saveSettingsActionProvider =
    Provider<Future<Result<AppSettings>> Function(SaveSettingsParams)>(
      (ref) => ref.read(saveSettingsProvider).call,
      name: 'saveSettings',
    );
