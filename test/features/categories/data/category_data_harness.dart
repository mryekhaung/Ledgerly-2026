import 'package:ledgerly/features/categories/data/datasources/category_local_datasource.dart';
import 'package:ledgerly/features/categories/data/repositories/category_repository_impl.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/result/result.dart';

/// Shared harness for the category data-layer tests.
///
/// Wires the real Drift datasource against an in-memory database and hands back
/// the repository under test. The id generator is injected so an assertion can
/// name an exact id rather than pattern-matching a UUID.
///
/// `Clock` and `idGenerator` are injected here rather than read from globals so a
/// test that asserts on `updatedAt` or an id is deterministic.
class CategoryDataHarness {
  CategoryDataHarness._(this.db, this.clock, this.datasource, this.repository);

  /// Builds a harness over [db], generating ids as `id-0`, `id-1`, …
  factory CategoryDataHarness.over(AppDatabase db, {int startMillis = 1000}) {
    final clock = FixedClock(startMillis);
    var counter = 0;
    final datasource = CategoryLocalDataSource(
      db,
      clock: clock,
      idGenerator: () => 'id-${counter++}',
    );
    return CategoryDataHarness._(
      db,
      clock,
      datasource,
      CategoryRepositoryImpl(datasource),
    );
  }

  final AppDatabase db;
  final FixedClock clock;
  final CategoryLocalDataSource datasource;
  final CategoryRepositoryImpl repository;

  /// Closes the database. Registered with `addTearDown` by the test.
  Future<void> dispose() => db.close();
}

/// Asserts [result] holds a value and returns it, failing the test otherwise.
///
/// Keeps a data test's happy path to one line and its failure message useful —
/// `result.valueOrNull!` would report a null-check crash instead of the actual
/// [Failure].
T expectSuccess<T>(Result<T> result) {
  if (result case Success<T>(:final value)) return value;
  final failure = result.failureOrNull;
  throw StateError('Expected a Success but got: $failure');
}
