import 'package:drift/drift.dart';

/// Key–value store for app-wide preferences.
///
/// **Why a table and not `shared_preferences`:** SQLite is already the app's
/// source of truth (`docs/Architecture.md` ADR #1), and Drift gives us
/// `watch()` for free — flipping the theme in Settings repaints the whole app
/// reactively, with no restart and no change-notifier plumbing. A key–value
/// table also needs no migration per new preference: adding a setting is a new
/// *row*, not a new column, so the schema stays at v2 forever.
///
/// Not a `CommonColumns` table on purpose: preferences are not user *data*.
/// They are never soft-deleted, never sorted, never archived, and never synced
/// to the remote store in v0.4 — a device's theme choice should not travel to
/// another device. Losing the id/sortOrder/archive columns makes that explicit.
///
/// Spec: `docs/DataModel.md` §7.
@TableIndex(name: 'idx_settings_key', columns: {#key})
class AppSettings extends Table {
  /// The preference name, e.g. `currency` (`SettingsKeys`). Primary key, so a
  /// write is always an upsert on exactly one row per preference.
  TextColumn get key => text().withLength(min: 1, max: 64)();

  /// The serialized value. Everything is encoded as text —
  /// `CurrencyCode.usd.name`, `ThemeMode.dark.name`, `'2024-01-01'` — so the
  /// table has one column and a new preference never changes the schema. The
  /// `SettingsRepository` owns the encode/decode and rejects anything it cannot
  /// round-trip rather than silently defaulting.
  TextColumn get value => text()();

  /// UTC epoch milliseconds of the last write. Useful for debugging a value
  /// that "did not stick" and for a future "reset everything" audit trail.
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
