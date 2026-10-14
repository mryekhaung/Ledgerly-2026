import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_progress.dart';
import 'package:ledgerly/features/budgets/domain/repositories/budget_repository.dart';
import 'package:ledgerly/features/budgets/domain/usecases/delete_budget.dart';
import 'package:ledgerly/features/budgets/domain/usecases/get_budget.dart';
import 'package:ledgerly/features/budgets/domain/usecases/get_budget_progress.dart';
import 'package:ledgerly/features/budgets/domain/usecases/save_budget.dart';
import 'package:ledgerly/features/budgets/domain/usecases/set_budget_archived.dart';
import 'package:ledgerly/features/budgets/domain/usecases/watch_budget_progress.dart';
import 'package:ledgerly/features/budgets/domain/usecases/watch_budgets.dart';

class FakeBudgetRepository implements BudgetRepository {
  final Map<String, Budget> budgets = {};
  final StreamController<List<Budget>> _controller =
      StreamController<List<Budget>>.broadcast();

  final List<BudgetProgress> progressList = [];

  void emit() {
    _controller.add(budgets.values.toList());
  }

  @override
  Stream<Result<List<Budget>>> watchBudgets({
    String? periodId,
    bool includeArchived = false,
  }) {
    return _controller.stream.map((list) {
      final filtered = list.where((b) {
        if (b.deletedAt != null) return false;
        if (!includeArchived && b.isArchived) return false;
        if (periodId != null && b.periodId != null && b.periodId != periodId) {
          return false;
        }
        return true;
      }).toList();
      return Success(filtered);
    });
  }

  @override
  Future<Result<Budget>> getBudget(String id) async {
    final b = budgets[id];
    if (b == null || b.deletedAt != null) {
      return const Err(NotFoundFailure('Budget not found'));
    }
    return Success(b);
  }

  @override
  Future<Result<Budget>> saveBudget({
    required Budget budget,
    bool isNew = false,
  }) async {
    budgets[budget.id] = budget;
    emit();
    return Success(budget);
  }

  @override
  Future<Result<void>> deleteBudget(String id) async {
    final b = budgets[id];
    if (b != null) {
      budgets[id] = b.copyWith(deletedAt: 123456789);
      emit();
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> setBudgetArchived(String id, bool isArchived) async {
    final b = budgets[id];
    if (b != null) {
      budgets[id] = b.copyWith(isArchived: isArchived);
      emit();
    }
    return const Success(null);
  }

  @override
  Future<Result<bool>> hasBudgetForCategory({
    String? categoryId,
    String? periodId,
    String? excludingId,
  }) async {
    final exists = budgets.values.any(
      (b) =>
          b.id != excludingId &&
          b.deletedAt == null &&
          b.categoryId == categoryId &&
          b.periodId == periodId,
    );
    return Success(exists);
  }

  @override
  Stream<Result<List<BudgetProgress>>> watchBudgetProgress(
    BudgetPeriod period,
  ) {
    return Stream.value(Success(progressList));
  }

  @override
  Future<Result<List<BudgetProgress>>> getBudgetProgress(
    BudgetPeriod period,
  ) async {
    return Success(progressList);
  }
}

void main() {
  group('Budget Use Cases', () {
    late FakeBudgetRepository repo;

    setUp(() {
      repo = FakeBudgetRepository();
    });

    const testBudget = Budget(
      id: 'b-1',
      categoryId: 'cat-food',
      amountMinor: 300000,
      currency: CurrencyCode.mmk,
      alertThreshold: 0.8,
      sortOrder: 0,
      isArchived: false,
      createdAt: 1000,
      updatedAt: 1000,
    );

    test('WatchBudgets streams active budgets', () async {
      final useCase = WatchBudgets(repo);
      final futureList = useCase(const WatchBudgetsParams()).first;

      repo.budgets[testBudget.id] = testBudget;
      repo.emit();

      final res = await futureList;
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull?.length, 1);
      expect(res.valueOrNull?.first.id, 'b-1');
    });

    test('GetBudget returns budget or not found failure', () async {
      final useCase = GetBudget(repo);

      final notFound = await useCase('b-none');
      expect(notFound.isErr, isTrue);

      repo.budgets[testBudget.id] = testBudget;
      final found = await useCase('b-1');
      expect(found.isSuccess, isTrue);
      expect(found.valueOrNull?.id, 'b-1');
    });

    test('SaveBudget validates amount and duplicates', () async {
      final useCase = SaveBudget(repo);

      // Non-positive amount
      final invalidAmount = await useCase(
        SaveBudgetParams(
          budget: testBudget.copyWith(amountMinor: 0),
          isNew: true,
        ),
      );
      expect(invalidAmount.isErr, isTrue);

      // Valid save
      final saved = await useCase(
        const SaveBudgetParams(budget: testBudget, isNew: true),
      );
      expect(saved.isSuccess, isTrue);

      // Duplicate save
      final duplicate = await useCase(
        SaveBudgetParams(budget: testBudget.copyWith(id: 'b-2'), isNew: true),
      );
      expect(duplicate.isErr, isTrue);
    });

    test('DeleteBudget and SetBudgetArchived modify state', () async {
      repo.budgets[testBudget.id] = testBudget;

      final archiveUseCase = SetBudgetArchived(repo);
      await archiveUseCase(
        const SetBudgetArchivedParams(id: 'b-1', isArchived: true),
      );
      expect(repo.budgets['b-1']?.isArchived, isTrue);

      final deleteUseCase = DeleteBudget(repo);
      await deleteUseCase('b-1');
      expect(repo.budgets['b-1']?.isDeleted, isTrue);
    });

    test(
      'WatchBudgetProgress and GetBudgetProgress delegate to repository',
      () async {
        final period = BudgetPeriod(
          start: LocalDate(2026, 10, 1),
          end: LocalDate(2026, 10, 31),
        );
        repo.progressList.add(
          BudgetProgress(
            budget: testBudget,
            spentMinor: 150000,
            period: period,
          ),
        );

        final watchUseCase = WatchBudgetProgress(repo);
        final streamRes = await watchUseCase(period).first;
        expect(streamRes.valueOrNull?.length, 1);
        expect(streamRes.valueOrNull?.first.spentMinor, 150000);

        final getUseCase = GetBudgetProgress(repo);
        final getRes = await getUseCase(period);
        expect(getRes.valueOrNull?.length, 1);
      },
    );
  });
}
