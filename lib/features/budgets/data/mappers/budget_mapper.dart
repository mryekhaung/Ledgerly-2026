import 'package:drift/drift.dart' show Value;
import 'package:ledgerly/core/database/app_database.dart' as db;
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget.dart';

/// Translates between Drift's [db.BudgetRow] row class and the pure-Dart [Budget] domain entity.
abstract final class BudgetMapper {
  const BudgetMapper._();

  /// Converts a Drift database row to domain [Budget].
  static Budget toEntity(db.BudgetRow row) {
    return Budget(
      id: row.id,
      categoryId: row.categoryId,
      periodId: row.periodId,
      amountMinor: row.amountMinor,
      currency: CurrencyCode.tryParse(row.currency) ?? CurrencyCode.mmk,
      alertThreshold: row.alertThreshold,
      sortOrder: row.sortOrder,
      isArchived: row.isArchived,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  /// Converts a domain [Budget] entity to Drift insert companion.
  static db.BudgetsCompanion toInsertCompanion(
    Budget budget, {
    required int nowUtcMillis,
  }) {
    return db.BudgetsCompanion.insert(
      id: Value(budget.id),
      categoryId: Value(budget.categoryId),
      periodId: Value(budget.periodId),
      amountMinor: budget.amountMinor,
      currency: budget.currency.name,
      alertThreshold: Value(budget.alertThreshold),
      sortOrder: Value(budget.sortOrder),
      isArchived: Value(budget.isArchived),
      createdAt: budget.createdAt > 0 ? budget.createdAt : nowUtcMillis,
      updatedAt: nowUtcMillis,
    );
  }

  /// Converts a domain [Budget] entity to Drift update companion.
  static db.BudgetsCompanion toUpdateCompanion(
    Budget budget, {
    required int nowUtcMillis,
  }) {
    return db.BudgetsCompanion(
      categoryId: Value(budget.categoryId),
      periodId: Value(budget.periodId),
      amountMinor: Value(budget.amountMinor),
      currency: Value(budget.currency.name),
      alertThreshold: Value(budget.alertThreshold),
      sortOrder: Value(budget.sortOrder),
      isArchived: Value(budget.isArchived),
      updatedAt: Value(nowUtcMillis),
    );
  }
}
