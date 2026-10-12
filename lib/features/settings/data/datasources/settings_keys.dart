/// The storage keys in the `app_settings` table.
///
/// Grouped in one place so a read and a write can never disagree on a string
/// literal, and so a grep for a stray `'currency'` finds nothing. Changing a key
/// here is a **breaking** change to existing installs — the old row would be
/// orphaned and the preference would silently revert to its default — so keys are
/// treated as append-only.
///
/// Spec: `docs/DataModel.md` §7.
abstract final class SettingsKeys {
  const SettingsKeys._();

  /// `CurrencyCode.name`, e.g. `mmk`.
  static const String currency = 'currency';

  /// `AppThemeMode.name`, e.g. `system`.
  static const String themeMode = 'theme_mode';

  /// `WeekStart.name`, e.g. `monday`.
  static const String weekStart = 'week_start';

  /// BCP-47 tag, e.g. `my`. Absent means "follow the device".
  static const String locale = 'locale';
}
