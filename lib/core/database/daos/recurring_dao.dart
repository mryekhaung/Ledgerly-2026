import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/database/tables/recurring_transactions.dart';
import 'package:ledgerly/core/database/uuid.dart';
import 'package:ledgerly/core/utils/local_date.dart';

part 'recurring_dao.g.dart';

/// Data access for [RecurringTransactions]. Spec: `docs/Roadmap.md` Phase 3 Item 3.
@DriftAccessor(tables: [RecurringTransactions])
class RecurringDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringDaoMixin {
  RecurringDao(super.db, {this.clock = const Clock()});

  final Clock clock;

  /// Watch live recurring transaction rules, ordered by next due date.
  Stream<List<RecurringTransactionRow>> watchAll({
    bool includeArchived = false,
  }) {
    return (select(recurringTransactions)
          ..where((t) {
            final notDeleted = t.deletedAt.isNull();
            if (includeArchived) {
              return notDeleted;
            }
            return notDeleted & t.isArchived.equals(false);
          })
          ..orderBy([
            (t) => OrderingTerm(expression: t.isArchived),
            (t) => OrderingTerm(expression: t.nextDueDate),
          ]))
        .watch();
  }

  /// Get all active recurring transaction rules that are due on or before [upToDate].
  Future<List<RecurringTransactionRow>> getActiveDue(LocalDate upToDate) {
    return (select(recurringTransactions)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                t.isArchived.equals(false) &
                t.nextDueDate.isSmallerOrEqualValue(upToDate.value),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.nextDueDate)]))
        .get();
  }

  /// Find a specific recurring rule by its [id].
  Future<RecurringTransactionRow?> findById(String id) {
    return (select(
      recurringTransactions,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
  }

  /// Insert a new recurring transaction rule.
  Future<String> insertRow(RecurringTransactionsCompanion companion) async {
    final id = companion.id.present ? companion.id.value : generateUuid();
    final now = clock.nowUtcMillis();
    await into(recurringTransactions).insert(
      companion.copyWith(
        id: Value(id),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return id;
  }

  /// Update an existing recurring rule by [id].
  Future<void> updateById(
    String id,
    RecurringTransactionsCompanion companion,
  ) async {
    final now = clock.nowUtcMillis();
    await (update(recurringTransactions)..where((t) => t.id.equals(id))).write(
      companion.copyWith(updatedAt: Value(now)),
    );
  }

  /// Soft-delete a recurring rule by [id].
  Future<void> softDelete(String id) async {
    final now = clock.nowUtcMillis();
    await (update(recurringTransactions)..where((t) => t.id.equals(id))).write(
      RecurringTransactionsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Pause or unpause a recurring rule by [id].
  Future<void> setArchived(String id, bool isArchived) async {
    final now = clock.nowUtcMillis();
    await (update(recurringTransactions)..where((t) => t.id.equals(id))).write(
      RecurringTransactionsCompanion(
        isArchived: Value(isArchived),
        updatedAt: Value(now),
      ),
    );
  }
}
