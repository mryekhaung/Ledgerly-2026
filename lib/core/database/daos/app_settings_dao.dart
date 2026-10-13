import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/database/tables/app_settings.dart';

part 'app_settings_dao.g.dart';

/// Data access for [AppSettings] — the app-wide preference key–value store.
///
/// Spec: `docs/DataModel.md` §7.
///
/// Unlike the feature DAOs there is **no soft-delete filter**, because this
/// table has no `deletedAt`: a preference's absence *is* its cleared state.
///
/// **Naming note:** the write is `put` rather than `insert`/`upsert`. Drift's
/// `into()` builder already exposes `insertOnConflictUpdate`, but wrapping it
/// keeps the "one row per key, always overwritten" contract in the DAO where a
/// reader of this class can see it.
@DriftAccessor(tables: [AppSettings])
class AppSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$AppSettingsDaoMixin {
  AppSettingsDao(super.db, {this.clock = const Clock()});

  final Clock clock;

  /// Every stored preference, as raw key→value pairs.
  ///
  /// The repository decodes these into [AppSettings]; nothing above the data
  /// layer should have to know the storage keys.
  Future<Map<String, String>> readAll() async {
    final rows = await select(appSettings).get();
    return <String, String>{for (final row in rows) row.key: row.value};
  }

  /// Emits the full preference map on every write.
  ///
  /// This is what makes a Settings toggle repaint the app immediately: the
  /// provider that drives `MaterialApp` watches this stream.
  Stream<Map<String, String>> watchAll() => select(appSettings).watch().map(
    (rows) => <String, String>{for (final row in rows) row.key: row.value},
  );

  /// Reads one preference, or null when it has never been written.
  Future<String?> read(String key) async {
    final row = await (select(
      appSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// Inserts or overwrites [key] with [value].
  Future<void> put({required String key, required String value}) =>
      into(appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          key: key,
          value: value,
          updatedAt: clock.nowUtcMillis(),
        ),
      );

  /// Writes several preferences in one transaction, so a multi-field save
  /// cannot half-apply.
  Future<void> putAll(Map<String, String> values) => transaction(() async {
    for (final entry in values.entries) {
      await put(key: entry.key, value: entry.value);
    }
  });

  /// Removes one preference, returning to the built-in default.
  Future<void> remove(String key) =>
      (delete(appSettings)..where((t) => t.key.equals(key))).go();
}
