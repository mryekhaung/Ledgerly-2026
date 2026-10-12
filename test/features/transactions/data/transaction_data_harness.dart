import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:ledgerly/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';

/// Shared harness for the transaction data-layer tests.
///
/// Mirrors the category harness: the real Drift datasource against an in-memory
/// database, with the clock and id generator injected so an assertion can name
/// an exact id or timestamp instead of pattern-matching a UUID.
class TransactionDataHarness {
  TransactionDataHarness._(
    this.db,
    this.clock,
    this.datasource,
    this.repository,
  );

  /// Builds a harness over [db], generating ids as `tx-0`, `tx-1`, …
  ///
  /// The `tx-` prefix is deliberate: a stray category id leaking into a
  /// transaction column would then be visible in the assertion output instead of
  /// looking like a perfectly valid transaction id.
  factory TransactionDataHarness.over(
    AppDatabase db, {
    int startMillis = 1000,
  }) {
    final clock = FixedClock(startMillis);
    var counter = 0;
    final datasource = TransactionLocalDataSource(
      db,
      clock: clock,
      idGenerator: () => 'tx-${counter++}',
    );
    return TransactionDataHarness._(
      db,
      clock,
      datasource,
      TransactionRepositoryImpl(datasource),
    );
  }

  final AppDatabase db;
  final FixedClock clock;
  final TransactionLocalDataSource datasource;
  final TransactionRepositoryImpl repository;

  /// Closes the database. Registered with `addTearDown` by the test.
  Future<void> dispose() => db.close();
}

/// Inserts a category row directly, bypassing the category feature.
///
/// The transaction tests are about transactions; wiring in the category
/// datasource would make a transaction failure harder to attribute. A raw insert
/// also lets a test reference a `category_id` that no category owns, which is
/// the realistic shape of an orphaned row.
Future<void> insertRawCategory(
  AppDatabase db, {
  required String id,
  String name = 'Uncategorised',
}) => db.customStatement(
  'INSERT INTO categories '
  '(id, name, icon_key, color_value, kind, sort_order, is_archived, '
  'is_default, created_at, updated_at) '
  "VALUES (?, ?, 'tag', 4278190080, 'expense', 0, 0, 0, 1, 1)",
  [id, name],
);

/// Builds a draft, defaulting every field a test does not care about.
///
/// Money defaults to `MMK` because its exponent is 0: a test that only means
/// "one thousand units" cannot be quietly wrong about a minor-unit conversion.
TransactionDraft txDraft({
  String categoryId = 'cat-1',
  int amountMinor = 1000,
  CurrencyCode currency = CurrencyCode.mmk,
  TransactionDirection direction = TransactionDirection.expense,
  int year = 2026,
  int month = 3,
  int day = 14,
  String? note,
}) => (
  categoryId: categoryId,
  amount: Money.minor(amountMinor, currency),
  direction: direction,
  date: LocalDate(year, month, day),
  note: note,
);

/// Asserts [result] holds a value and returns it, failing with the actual
/// [Failure] otherwise.
///
/// `result.valueOrNull!` would surface a null-check crash instead of the failure
/// that actually happened.
T expectSuccess<T>(Result<T> result) {
  if (result case Success<T>(:final value)) return value;
  throw StateError('Expected a Success but got: ${result.failureOrNull}');
}
