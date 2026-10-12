import 'package:flutter_test/flutter_test.dart';

import 'db_harness.dart';

/// Covers `AccountsDao` against a real in-memory SQLite database.
///
/// Accounts have no UI until Phase 3, but the DAO ships in v1 so
/// `transactions.accountId` has a real counterpart. What matters here is the one
/// thing that makes `accounts` different from every other table: its money column
/// is **signed**. A refactor that "tidies away" that inconsistency would silently
/// break overdrawn and credit accounts, so the sign is pinned explicitly.
void main() {
  group('AccountsDao.insert', () {
    test('should_assign_a_uuid_and_append_to_the_end', () async {
      final h = useDbHarness();
      final first = await h.accounts.insert(
        name: 'Wallet',
        type: 'cash',
        currency: 'mmk',
        openingBalanceMinor: 0,
        iconKey: 'wallet',
        colorValue: 0xFF5A8FE8,
      );
      final second = await h.accounts.insert(
        name: 'KBZ Bank',
        type: 'bank',
        currency: 'mmk',
        openingBalanceMinor: 0,
        iconKey: 'account_balance',
        colorValue: 0xFF6FB98F,
      );

      expect(first.length, 36, reason: 'a UUIDv4 string');
      expect((await h.accounts.findById(first))!.sortOrder, 0);
      expect((await h.accounts.findById(second))!.sortOrder, 1);
    });

    test('should_keep_a_negative_opening_balance_signed', () async {
      // The reason `openingBalanceMinor` is the only signed money column in the
      // schema (`docs/DataModel.md` §4): a credit card opens in debt, and a
      // balance is a *position*, not a movement.
      final h = useDbHarness();
      final id = await h.accounts.insert(
        name: 'Credit Card',
        type: 'credit',
        currency: 'mmk',
        openingBalanceMinor: -250000,
        iconKey: 'credit_card',
        colorValue: 0xFFE85A7F,
      );

      expect((await h.accounts.findById(id))!.openingBalanceMinor, -250000);
      expect(
        await rawValue(h.db, 'accounts', 'opening_balance_minor', id),
        -250000,
      );
    });

    test('should_stamp_timestamps_and_default_include_in_total', () async {
      final h = useDbHarness(startMillis: 77);
      final id = await h.accounts.insert(
        name: 'Wallet',
        type: 'cash',
        currency: 'mmk',
        openingBalanceMinor: 0,
        iconKey: 'wallet',
        colorValue: 1,
      );

      final row = (await h.accounts.findById(id))!;
      expect(row.createdAt, 77);
      expect(row.updatedAt, 77);
      expect(row.deletedAt, isNull);
      expect(row.isArchived, isFalse);
      expect(
        row.includeInTotal,
        isTrue,
        reason: 'the column default; a closed card is opted out explicitly',
      );
    });
  });

  group('AccountsDao.watchAll', () {
    test('should_order_by_archive_then_sort_order', () async {
      final h = useDbHarness();
      final second = await h.accounts.insert(
        name: 'B',
        type: 'cash',
        currency: 'mmk',
        openingBalanceMinor: 0,
        iconKey: 'x',
        colorValue: 1,
        sortOrder: 1,
      );
      final first = await h.accounts.insert(
        name: 'A',
        type: 'cash',
        currency: 'mmk',
        openingBalanceMinor: 0,
        iconKey: 'x',
        colorValue: 1,
        sortOrder: 0,
      );
      // An archived row sorts last even though its sortOrder is smallest.
      final archived = await h.accounts.insert(
        name: 'Closed Card',
        type: 'credit',
        currency: 'mmk',
        openingBalanceMinor: 0,
        iconKey: 'x',
        colorValue: 1,
        sortOrder: -10,
        isArchived: true,
      );

      final ids = (await h.accounts.watchAll().first).map((a) => a.id).toList();
      expect(ids, [first, second, archived]);
    });

    test('should_exclude_a_soft_deleted_row', () async {
      final h = useDbHarness();
      final keep = await h.accounts.insert(
        name: 'Wallet',
        type: 'cash',
        currency: 'mmk',
        openingBalanceMinor: 0,
        iconKey: 'x',
        colorValue: 1,
      );
      final drop = await h.accounts.insert(
        name: 'Old Bank',
        type: 'bank',
        currency: 'mmk',
        openingBalanceMinor: 0,
        iconKey: 'x',
        colorValue: 1,
      );
      await h.accounts.softDelete(drop);

      final ids = (await h.accounts.watchAll().first).map((a) => a.id).toList();
      expect(ids, [keep]);
    });
  });

  group('AccountsDao.updateById', () {
    test(
      'should_rewrite_the_opening_balance_and_bump_updated_at_only',
      () async {
        final h = useDbHarness(startMillis: 100);
        final id = await h.accounts.insert(
          name: 'Wallet',
          type: 'cash',
          currency: 'mmk',
          openingBalanceMinor: 1000,
          iconKey: 'wallet',
          colorValue: 1,
        );
        h.clock.advance(const Duration(seconds: 2));

        await h.accounts.updateById(
          id,
          name: 'Cash',
          openingBalanceMinor: -500,
        );

        final row = (await h.accounts.findById(id))!;
        expect(row.name, 'Cash');
        expect(row.openingBalanceMinor, -500);
        expect(row.updatedAt, 2100);
        expect(row.createdAt, 100, reason: 'createdAt is never rewritten');
        expect(row.iconKey, 'wallet', reason: 'an omitted field is untouched');
      },
    );

    test('should_toggle_include_in_total', () async {
      final h = useDbHarness();
      final id = await h.accounts.insert(
        name: 'Closed Card',
        type: 'credit',
        currency: 'mmk',
        openingBalanceMinor: 0,
        iconKey: 'x',
        colorValue: 1,
      );

      await h.accounts.updateById(id, includeInTotal: false);

      expect((await h.accounts.findById(id))!.includeInTotal, isFalse);
    });
  });

  group('AccountsDao.setArchived', () {
    test('should_retire_from_pickers_without_deleting', () async {
      // Archiving and soft-deleting are different operations
      // (`docs/DataModel.md` §4): an archived card still shows in the account
      // list and still counts in history, it just stops being offered.
      final h = useDbHarness(startMillis: 100);
      final id = await h.accounts.insert(
        name: 'Closed Card',
        type: 'credit',
        currency: 'mmk',
        openingBalanceMinor: 0,
        iconKey: 'x',
        colorValue: 1,
      );
      h.clock.advance(const Duration(seconds: 3));

      await h.accounts.setArchived(id, isArchived: true);

      final row = (await h.accounts.findById(id))!;
      expect(row.isArchived, isTrue);
      expect(row.deletedAt, isNull, reason: 'archiving is not deleting');
      expect(row.updatedAt, 3100);
      expect(
        (await h.accounts.watchAll().first).single.id,
        id,
        reason: 'an archived account stays in the list, sorted last',
      );
    });

    test('should_unarchive', () async {
      final h = useDbHarness();
      final id = await h.accounts.insert(
        name: 'Closed Card',
        type: 'credit',
        currency: 'mmk',
        openingBalanceMinor: 0,
        iconKey: 'x',
        colorValue: 1,
        isArchived: true,
      );

      await h.accounts.setArchived(id, isArchived: false);

      expect((await h.accounts.findById(id))!.isArchived, isFalse);
    });
  });

  group('AccountsDao.softDelete', () {
    test('should_hide_the_row_without_removing_it', () async {
      final h = useDbHarness(startMillis: 100);
      final id = await h.accounts.insert(
        name: 'Wallet',
        type: 'cash',
        currency: 'mmk',
        openingBalanceMinor: 0,
        iconKey: 'x',
        colorValue: 1,
      );
      h.clock.advance(const Duration(milliseconds: 1));

      await h.accounts.softDelete(id);

      expect(await h.accounts.findById(id), isNull);
      expect(await h.accounts.watchAll().first, isEmpty);
      expect(
        await physicalRowCount(h.db, h.db.accounts),
        1,
        reason:
            'soft delete is an UPDATE (ADR #4) — the row stays for sync/undo',
      );
      expect(await rawValue(h.db, 'accounts', 'deleted_at', id), 101);
    });
  });
}
