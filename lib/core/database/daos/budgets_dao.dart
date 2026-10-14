import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/database/tables/budgets.dart';
import 'package:ledgerly/core/database/uuid.dart';

part 'budgets_dao.g.dart';

/// Data access for [Budgets]. Spec: `docs/DataModel.md` §8.
@DriftAccessor(tables: [Budgets])
class BudgetsDao extends DatabaseAccessor<AppDatabase> with _$BudgetsDaoMixin {
  BudgetsDao(super.db, {this.clock = const Clock()});

  final Clock clock;

  /// Live budgets ordered by sort order, optionally filtered by period.
  Stream<List<BudgetRow>> watchAll({
    String? periodId,
    bool includeArchived = false,
  }) {
    return (select(budgets)
          ..where((t) {
            var pred = t.deletedAt.isNull();
            if (!includeArchived) {
              pred = pred & t.isArchived.equals(false);
            }
            if (periodId != null) {
              pred = pred & (t.periodId.isNull() | t.periodId.equals(periodId));
            }
            return pred;
          })
          ..orderBy([
            (t) => OrderingTerm(expression: t.isArchived),
            (t) => OrderingTerm(expression: t.sortOrder),
          ]))
        .watch();
  }

  Future<BudgetRow?> findById(String id) {
    return (select(
      budgets,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
  }

  Future<BudgetRow?> findByCategoryAndPeriod({
    String? categoryId,
    String? periodId,
    String? excludingId,
  }) {
    return (select(budgets)..where((t) {
          var pred = t.deletedAt.isNull();
          if (categoryId == null) {
            pred = pred & t.categoryId.isNull();
          } else {
            pred = pred & t.categoryId.equals(categoryId);
          }

          if (periodId == null) {
            pred = pred & t.periodId.isNull();
          } else {
            pred = pred & t.periodId.equals(periodId);
          }

          if (excludingId != null) {
            pred = pred & t.id.equals(excludingId).not();
          }
          return pred;
        }))
        .getSingleOrNull();
  }

  Future<String> insert({
    String? id,
    String? categoryId,
    String? periodId,
    required int amountMinor,
    required String currency,
    double alertThreshold = 0.8,
    int? sortOrder,
    bool isArchived = false,
    int? nowUtcMillis,
  }) async {
    final newId = (id != null && id.isNotEmpty) ? id : generateUuid();
    final now = nowUtcMillis ?? clock.nowUtcMillis();
    await into(budgets).insert(
      BudgetsCompanion.insert(
        id: Value(newId),
        categoryId: Value(categoryId),
        periodId: Value(periodId),
        amountMinor: amountMinor,
        currency: currency,
        alertThreshold: Value(alertThreshold),
        sortOrder: Value(sortOrder ?? await _nextSortOrder()),
        isArchived: Value(isArchived),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return newId;
  }

  Future<bool> updateById(
    String id, {
    String? categoryId,
    bool clearCategoryId = false,
    String? periodId,
    bool clearPeriodId = false,
    int? amountMinor,
    String? currency,
    double? alertThreshold,
    int? sortOrder,
    bool? isArchived,
  }) async {
    final now = clock.nowUtcMillis();
    final count = await (update(budgets)..where((t) => t.id.equals(id))).write(
      BudgetsCompanion(
        categoryId: clearCategoryId
            ? const Value(null)
            : (categoryId != null ? Value(categoryId) : const Value.absent()),
        periodId: clearPeriodId
            ? const Value(null)
            : (periodId != null ? Value(periodId) : const Value.absent()),
        amountMinor: amountMinor != null
            ? Value(amountMinor)
            : const Value.absent(),
        currency: currency != null ? Value(currency) : const Value.absent(),
        alertThreshold: alertThreshold != null
            ? Value(alertThreshold)
            : const Value.absent(),
        sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
        isArchived: isArchived != null
            ? Value(isArchived)
            : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
    return count > 0;
  }

  Future<bool> softDelete(String id) async {
    final now = clock.nowUtcMillis();
    final count =
        await (update(
          budgets,
        )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
          BudgetsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
        );
    return count > 0;
  }

  Future<bool> setArchived(String id, bool isArchived) async {
    final now = clock.nowUtcMillis();
    final count =
        await (update(
          budgets,
        )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
          BudgetsCompanion(
            isArchived: Value(isArchived),
            updatedAt: Value(now),
          ),
        );
    return count > 0;
  }

  Future<void> reorder(List<String> orderedIds) async {
    final now = clock.nowUtcMillis();
    await transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (update(budgets)..where((t) => t.id.equals(orderedIds[i]))).write(
          BudgetsCompanion(sortOrder: Value(i), updatedAt: Value(now)),
        );
      }
    });
  }

  Future<int> _nextSortOrder() async {
    final maxExp = budgets.sortOrder.max();
    final query = selectOnly(budgets)
      ..where(budgets.deletedAt.isNull())
      ..addColumns([maxExp]);
    final result = await query.map((row) => row.read(maxExp)).getSingle();
    return (result ?? -1) + 1;
  }
}
