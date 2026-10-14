import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/database/tables/savings_goals.dart';
import 'package:ledgerly/core/database/uuid.dart';

part 'savings_goals_dao.g.dart';

/// Data access for [SavingsGoals]. Spec: `docs/Roadmap.md` Phase 3 Item 4.
@DriftAccessor(tables: [SavingsGoals])
class SavingsGoalsDao extends DatabaseAccessor<AppDatabase>
    with _$SavingsGoalsDaoMixin {
  SavingsGoalsDao(super.db, {this.clock = const Clock()});

  final Clock clock;

  /// Watch live savings goals, ordered by sort order and creation date.
  Stream<List<SavingsGoalRow>> watchAll({bool includeArchived = false}) {
    return (select(savingsGoals)
          ..where((t) {
            final notDeleted = t.deletedAt.isNull();
            if (includeArchived) {
              return notDeleted;
            }
            return notDeleted & t.isArchived.equals(false);
          })
          ..orderBy([
            (t) => OrderingTerm(expression: t.isArchived),
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Find a specific savings goal by its [id].
  Future<SavingsGoalRow?> findById(String id) {
    return (select(
      savingsGoals,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
  }

  /// Insert a new savings goal.
  Future<String> insertRow(SavingsGoalsCompanion companion) async {
    final id = companion.id.present ? companion.id.value : generateUuid();
    final now = clock.nowUtcMillis();
    await into(savingsGoals).insert(
      companion.copyWith(
        id: Value(id),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return id;
  }

  /// Update an existing goal by [id].
  Future<void> updateById(String id, SavingsGoalsCompanion companion) async {
    final now = clock.nowUtcMillis();
    await (update(savingsGoals)..where((t) => t.id.equals(id))).write(
      companion.copyWith(updatedAt: Value(now)),
    );
  }

  /// Update the current saved amount of a goal.
  Future<void> updateCurrentAmount(String id, int newCurrentAmountMinor) async {
    final now = clock.nowUtcMillis();
    await (update(savingsGoals)..where((t) => t.id.equals(id))).write(
      SavingsGoalsCompanion(
        currentAmountMinor: Value(newCurrentAmountMinor),
        updatedAt: Value(now),
      ),
    );
  }

  /// Soft-delete a goal by [id].
  Future<void> softDelete(String id) async {
    final now = clock.nowUtcMillis();
    await (update(savingsGoals)..where((t) => t.id.equals(id))).write(
      SavingsGoalsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// Archive or unarchive a goal by [id].
  Future<void> setArchived(String id, bool isArchived) async {
    final now = clock.nowUtcMillis();
    await (update(savingsGoals)..where((t) => t.id.equals(id))).write(
      SavingsGoalsCompanion(
        isArchived: Value(isArchived),
        updatedAt: Value(now),
      ),
    );
  }
}
