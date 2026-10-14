import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/features/goals/data/mappers/savings_goal_mapper.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';

abstract class SavingsGoalsLocalDataSource {
  Stream<List<SavingsGoal>> watchAll({bool includeArchived = false});

  Future<SavingsGoal?> findById(String id);

  Future<String> save(SavingsGoal goal);

  Future<void> addContribution({
    required String goalId,
    required int amountMinor,
    String? fromAccountId,
    String? note,
  });

  Future<void> withdraw({
    required String goalId,
    required int amountMinor,
    String? toAccountId,
    String? note,
  });

  Future<void> setArchived({required String id, required bool isArchived});

  Future<void> delete(String id);
}

class SavingsGoalsLocalDataSourceImpl implements SavingsGoalsLocalDataSource {
  const SavingsGoalsLocalDataSourceImpl(
    this._db, {
    this.mapper = const SavingsGoalMapper(),
  });

  final AppDatabase _db;
  final SavingsGoalMapper mapper;

  @override
  Stream<List<SavingsGoal>> watchAll({bool includeArchived = false}) {
    return _db.savingsGoalsDao
        .watchAll(includeArchived: includeArchived)
        .map((rows) => rows.map(mapper.toDomain).toList());
  }

  @override
  Future<SavingsGoal?> findById(String id) async {
    final row = await _db.savingsGoalsDao.findById(id);
    return row == null ? null : mapper.toDomain(row);
  }

  @override
  Future<String> save(SavingsGoal goal) async {
    final existing = await _db.savingsGoalsDao.findById(goal.id);
    final companion = mapper.toCompanion(goal);
    if (existing == null) {
      return _db.savingsGoalsDao.insertRow(companion);
    } else {
      await _db.savingsGoalsDao.updateById(goal.id, companion);
      return goal.id;
    }
  }

  @override
  Future<void> addContribution({
    required String goalId,
    required int amountMinor,
    String? fromAccountId,
    String? note,
  }) async {
    final existing = await _db.savingsGoalsDao.findById(goalId);
    if (existing == null) return;
    final newAmount = existing.currentAmountMinor + amountMinor;
    await _db.savingsGoalsDao.updateCurrentAmount(goalId, newAmount);
  }

  @override
  Future<void> withdraw({
    required String goalId,
    required int amountMinor,
    String? toAccountId,
    String? note,
  }) async {
    final existing = await _db.savingsGoalsDao.findById(goalId);
    if (existing == null) return;
    final newAmount = (existing.currentAmountMinor - amountMinor).clamp(
      0,
      1 << 62,
    );
    await _db.savingsGoalsDao.updateCurrentAmount(goalId, newAmount);
  }

  @override
  Future<void> setArchived({required String id, required bool isArchived}) {
    return _db.savingsGoalsDao.setArchived(id, isArchived);
  }

  @override
  Future<void> delete(String id) {
    return _db.savingsGoalsDao.softDelete(id);
  }
}
