// `drift` exports a SQL `isNull` that collides with the matcher of the same
// name from `flutter_test`. Only the matcher is used here, so the SQL operator
// is hidden.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/app_settings_dao.dart';
import 'package:ledgerly/core/database/daos/clock.dart';

/// The `app_settings` DAO — the persistence half of the settings feature.
///
/// Two behaviours matter beyond "it stores a string": the write must be an
/// **upsert** (a preference is set more than once in a session), and `watchAll`
/// must emit on every write, because that stream is what repaints the app when
/// the theme changes.
void main() {
  late FixedClock clock;
  late AppDatabase db;
  late AppSettingsDao dao;

  setUp(() {
    clock = FixedClock(1000);
    db = AppDatabase(NativeDatabase.memory());
    dao = AppSettingsDao(db, clock: clock);
    addTearDown(db.close);
  });

  group('read', () {
    test('an empty table reads back an empty map', () async {
      expect(await dao.readAll(), isEmpty);
    });

    test('a missing key reads null', () async {
      expect(await dao.read('theme_mode'), isNull);
    });

    test('reads back exactly what was written', () async {
      await dao.put(key: 'currency', value: 'usd');
      expect(await dao.read('currency'), 'usd');
      expect(await dao.readAll(), {'currency': 'usd'});
    });
  });

  group('put', () {
    test('is an upsert — a second write replaces, not duplicates', () async {
      await dao.put(key: 'currency', value: 'usd');
      clock.advance(const Duration(seconds: 1));
      await dao.put(key: 'currency', value: 'jpy');

      final all = await dao.readAll();
      expect(all.length, 1);
      expect(all['currency'], 'jpy');
    });

    test('bumps updatedAt on rewrite', () async {
      await dao.put(key: 'currency', value: 'usd');
      final first = await db
          .customSelect(
            'SELECT updated_at FROM app_settings WHERE key = ?',
            variables: const [Variable<String>('currency')],
          )
          .getSingle();

      clock.advance(const Duration(seconds: 5));
      await dao.put(key: 'currency', value: 'jpy');
      final second = await db
          .customSelect(
            'SELECT updated_at FROM app_settings WHERE key = ?',
            variables: const [Variable<String>('currency')],
          )
          .getSingle();

      expect(
        second.read<int>('updated_at'),
        greaterThan(first.read<int>('updated_at')),
      );
    });
  });

  group('putAll', () {
    test('writes every pair', () async {
      await dao.putAll({'currency': 'usd', 'theme_mode': 'dark'});
      expect(await dao.readAll(), {
        'currency': 'usd',
        'theme_mode': 'dark',
      });
    });

    test('an empty map is a no-op', () async {
      await dao.putAll(const <String, String>{});
      expect(await dao.readAll(), isEmpty);
    });
  });

  group('remove', () {
    test('deletes only the named key', () async {
      await dao.putAll({'currency': 'usd', 'theme_mode': 'dark'});
      await dao.remove('theme_mode');

      expect(await dao.readAll(), {'currency': 'usd'});
      expect(await dao.read('theme_mode'), isNull);
    });

    test('removing a missing key is a no-op, not an error', () async {
      await dao.remove('nothing_here');
      expect(await dao.readAll(), isEmpty);
    });
  });

  group('watchAll', () {
    test('emits the empty map first, then each write', () async {
      final emissions = <Map<String, String>>[];
      final sub = dao.watchAll().listen(emissions.add);

      // Let the initial (empty) emission land before mutating.
      await pumpEventQueue();
      await dao.put(key: 'currency', value: 'usd');
      await pumpEventQueue();
      await dao.put(key: 'theme_mode', value: 'dark');
      await pumpEventQueue();

      await sub.cancel();

      expect(emissions.first, isEmpty);
      expect(emissions.last, {'currency': 'usd', 'theme_mode': 'dark'});
      // At least the initial emission plus one per write — drift may coalesce,
      // so assert the endpoints and the count floor rather than an exact list.
      expect(emissions.length, greaterThanOrEqualTo(3));
    });
  });
}
