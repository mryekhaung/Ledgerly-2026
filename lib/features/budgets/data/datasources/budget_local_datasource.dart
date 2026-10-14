import 'dart:async';

import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/budgets_dao.dart';
import 'package:ledgerly/core/database/daos/categories_dao.dart';
import 'package:ledgerly/core/database/daos/transactions_dao.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/features/budgets/data/mappers/budget_mapper.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_progress.dart';

abstract interface class BudgetLocalDataSource {
  Stream<List<Budget>> watchBudgets({
    String? periodId,
    bool includeArchived = false,
  });

  Future<Budget?> getBudget(String id);

  Future<Budget> saveBudget({required Budget budget, bool isNew = false});

  Future<void> deleteBudget(String id);

  Future<void> setBudgetArchived(String id, bool isArchived);

  Future<bool> hasBudgetForCategory({
    String? categoryId,
    String? periodId,
    String? excludingId,
  });

  Stream<List<BudgetProgress>> watchBudgetProgress(BudgetPeriod period);

  Future<List<BudgetProgress>> getBudgetProgress(BudgetPeriod period);
}

class BudgetLocalDataSourceImpl implements BudgetLocalDataSource {
  const BudgetLocalDataSourceImpl({
    required this.budgetsDao,
    required this.transactionsDao,
    required this.categoriesDao,
  });

  final BudgetsDao budgetsDao;
  final TransactionsDao transactionsDao;
  final CategoriesDao categoriesDao;

  @override
  Stream<List<Budget>> watchBudgets({
    String? periodId,
    bool includeArchived = false,
  }) {
    return budgetsDao
        .watchAll(periodId: periodId, includeArchived: includeArchived)
        .map((rows) => rows.map(BudgetMapper.toEntity).toList());
  }

  @override
  Future<Budget?> getBudget(String id) async {
    final row = await budgetsDao.findById(id);
    return row != null ? BudgetMapper.toEntity(row) : null;
  }

  @override
  Future<Budget> saveBudget({
    required Budget budget,
    bool isNew = false,
  }) async {
    if (isNew) {
      final id = await budgetsDao.insert(
        id: budget.id.isEmpty ? null : budget.id,
        categoryId: budget.categoryId,
        periodId: budget.periodId,
        amountMinor: budget.amountMinor,
        currency: budget.currency.name,
        alertThreshold: budget.alertThreshold,
        sortOrder: budget.sortOrder,
        isArchived: budget.isArchived,
      );
      return budget.copyWith(id: id);
    } else {
      await budgetsDao.updateById(
        budget.id,
        categoryId: budget.categoryId,
        clearCategoryId: budget.categoryId == null,
        periodId: budget.periodId,
        clearPeriodId: budget.periodId == null,
        amountMinor: budget.amountMinor,
        currency: budget.currency.name,
        alertThreshold: budget.alertThreshold,
        sortOrder: budget.sortOrder,
        isArchived: budget.isArchived,
      );
    }
    return budget;
  }

  @override
  Future<void> deleteBudget(String id) async {
    await budgetsDao.softDelete(id);
  }

  @override
  Future<void> setBudgetArchived(String id, bool isArchived) async {
    await budgetsDao.setArchived(id, isArchived);
  }

  @override
  Future<bool> hasBudgetForCategory({
    String? categoryId,
    String? periodId,
    String? excludingId,
  }) async {
    final row = await budgetsDao.findByCategoryAndPeriod(
      categoryId: categoryId,
      periodId: periodId,
      excludingId: excludingId,
    );
    return row != null;
  }

  @override
  Stream<List<BudgetProgress>> watchBudgetProgress(BudgetPeriod period) {
    return _StreamCombiner3<
          List<BudgetRow>,
          List<CategoryTotalRow>,
          List<Category>,
          List<BudgetProgress>
        >(
          budgetsDao.watchAll(periodId: period.id),
          transactionsDao.watchPeriodCategoryTotals(period),
          categoriesDao.watchAll(),
          (budgetRows, categoryTotals, categories) {
            return _buildProgressList(
              budgetRows: budgetRows.map(BudgetMapper.toEntity).toList(),
              categoryTotals: categoryTotals,
              categories: categories,
              period: period,
            );
          },
        )
        .stream;
  }

  @override
  Future<List<BudgetProgress>> getBudgetProgress(BudgetPeriod period) async {
    final stream = watchBudgetProgress(period);
    return stream.first;
  }

  List<BudgetProgress> _buildProgressList({
    required List<Budget> budgetRows,
    required List<CategoryTotalRow> categoryTotals,
    required List<Category> categories,
    required BudgetPeriod period,
  }) {
    final categoryTotalsMap = <String, int>{};
    var totalExpensesMinor = 0;

    for (final ct in categoryTotals) {
      if (ct.direction == 'expense') {
        categoryTotalsMap[ct.categoryId] = ct.totalMinor;
        totalExpensesMinor += ct.totalMinor;
      }
    }

    final categoriesMap = <String, Category>{};
    for (final cat in categories) {
      categoriesMap[cat.id] = cat;
    }

    final progressList = <BudgetProgress>[];

    for (final budget in budgetRows) {
      if (budget.isTotalBudget) {
        progressList.add(
          BudgetProgress(
            budget: budget,
            spentMinor: totalExpensesMinor,
            period: period,
            categoryName: null,
            categoryIcon: null,
            categoryColor: null,
          ),
        );
      } else {
        final cat = categoriesMap[budget.categoryId];
        final spent = categoryTotalsMap[budget.categoryId] ?? 0;
        progressList.add(
          BudgetProgress(
            budget: budget,
            spentMinor: spent,
            period: period,
            categoryName: cat?.name,
            categoryIcon: cat?.iconKey,
            categoryColor: cat?.colorValue,
          ),
        );
      }
    }

    // Sort: Total budget first, then by sortOrder
    progressList.sort((a, b) {
      if (a.budget.isTotalBudget && !b.budget.isTotalBudget) return -1;
      if (!a.budget.isTotalBudget && b.budget.isTotalBudget) return 1;
      return a.budget.sortOrder.compareTo(b.budget.sortOrder);
    });

    return progressList;
  }
}

/// Helper to combine 3 streams cleanly without memory leaks or lint violations.
class _StreamCombiner3<A, B, C, R> {
  _StreamCombiner3(this._streamA, this._streamB, this._streamC, this._combiner);

  final Stream<A> _streamA;
  final Stream<B> _streamB;
  final Stream<C> _streamC;
  final R Function(A a, B b, C c) _combiner;

  late final StreamController<R> _controller = StreamController<R>(
    onListen: _onListen,
    onCancel: _onCancel,
  );

  Stream<R> get stream => _controller.stream;

  A? _lastA;
  B? _lastB;
  C? _lastC;
  bool _hasA = false;
  bool _hasB = false;
  bool _hasC = false;

  StreamSubscription<A>? _subA;
  StreamSubscription<B>? _subB;
  StreamSubscription<C>? _subC;

  void _emitIfReady() {
    if (_hasA && _hasB && _hasC && !_controller.isClosed) {
      _controller.add(_combiner(_lastA as A, _lastB as B, _lastC as C));
    }
  }

  void _onListen() {
    _subA = _streamA.listen((a) {
      _lastA = a;
      _hasA = true;
      _emitIfReady();
    }, onError: _controller.addError);
    _subB = _streamB.listen((b) {
      _lastB = b;
      _hasB = true;
      _emitIfReady();
    }, onError: _controller.addError);
    _subC = _streamC.listen((c) {
      _lastC = c;
      _hasC = true;
      _emitIfReady();
    }, onError: _controller.addError);
  }

  Future<void> _onCancel() async {
    await Future.wait([
      if (_subA != null) _subA!.cancel(),
      if (_subB != null) _subB!.cancel(),
      if (_subC != null) _subC!.cancel(),
    ]);
    await _controller.close();
  }
}
