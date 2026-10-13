import 'package:ledgerly/core/database/daos/app_settings_dao.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/features/settings/data/datasources/settings_keys.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';

/// Reads and writes preferences in the local SQLite database.
///
/// Owns **every** Drift type and every storage key, so nothing above it — the
/// repository, use cases, providers — knows how a preference is spelled on disk
/// (`docs/Architecture.md` §4).
///
/// It returns domain entities rather than a raw map so the decode runs once per
/// read, at the boundary, and the rest of the app only ever sees a validated
/// [AppSettings].
class SettingsLocalDataSource {
  SettingsLocalDataSource(this._dao);

  final AppSettingsDao _dao;

  /// The current preferences, decoded.
  Future<AppSettings> read() async => _decode(await _dao.readAll());

  /// Emits preferences on every write.
  Stream<AppSettings> watch() => _dao.watchAll().map(_decode);

  /// Persists [settings] in full.
  ///
  /// Writes every key, including ones equal to their default, rather than
  /// diffing: the table is four rows, an upsert each is cheaper than the
  /// comparison logic, and "the user explicitly chose the default" is
  /// information worth keeping (it survives the default changing in a future
  /// release).
  Future<void> write(AppSettings settings) => _dao
      .putAll(<String, String>{
        SettingsKeys.currency: settings.currency.name,
        SettingsKeys.themeMode: settings.themeMode.name,
        SettingsKeys.weekStart: settings.weekStart.name,
        SettingsKeys.monthStartDay: settings.monthStartDay.toString(),
        // The locale is the one key that is *removed* when null, because an absent
        // row is how "follow the device" is stored — see [_decode].
        ...switch (settings.localeCode) {
          final String code => <String, String>{SettingsKeys.locale: code},
          _ => const <String, String>{},
        },
      })
      .then((_) async {
        if (settings.localeCode == null) {
          await _dao.remove(SettingsKeys.locale);
        }
      });

  /// Decodes a raw key→value map into [AppSettings].
  ///
  /// **Unknown value → default, not a failure.** A preference written by a newer
  /// build (say a fourth theme mode) or corrupted on disk must not brick launch:
  /// the worst case is the app falls back to the default for that one field and
  /// the user re-picks it. That is a far better outcome than an error screen the
  /// user cannot dismiss, which is what throwing here would produce.
  AppSettings _decode(Map<String, String> raw) {
    const defaults = AppSettings.defaults;
    final locale = raw[SettingsKeys.locale];
    final rawDay = raw[SettingsKeys.monthStartDay];
    final parsedDay = rawDay != null ? int.tryParse(rawDay) : null;
    final monthStartDay =
        (parsedDay != null && parsedDay >= 1 && parsedDay <= 28)
        ? parsedDay
        : defaults.monthStartDay;

    return AppSettings(
      currency:
          _enumOr(CurrencyCode.values, raw[SettingsKeys.currency]) ??
          defaults.currency,
      themeMode:
          AppThemeMode.tryParse(raw[SettingsKeys.themeMode] ?? '') ??
          defaults.themeMode,
      weekStart:
          WeekStart.tryParse(raw[SettingsKeys.weekStart] ?? '') ??
          defaults.weekStart,
      // An empty string decodes to null too, so a blank row cannot shadow the
      // device locale with "no locale at all".
      localeCode: (locale == null || locale.isEmpty) ? null : locale,
      monthStartDay: monthStartDay,
    );
  }

  /// Finds the value of `T.values` whose `name` equals [name].
  ///
  /// A tiny generic helper so [CurrencyCode] — which has no `tryParse(name)` for
  /// enum names, only for ISO codes — reads the same way the other two enums do.
  static T? _enumOr<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
