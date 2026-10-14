import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_progress.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_status.dart';
import 'package:ledgerly/features/budgets/domain/usecases/delete_budget.dart';
import 'package:ledgerly/features/budgets/domain/usecases/get_budget.dart';
import 'package:ledgerly/features/budgets/domain/usecases/save_budget.dart';
import 'package:ledgerly/features/budgets/domain/usecases/set_budget_archived.dart';
import 'package:ledgerly/features/budgets/domain/usecases/watch_budget_progress.dart';
import 'package:ledgerly/features/budgets/domain/usecases/watch_budgets.dart';
import 'package:ledgerly/features/budgets/domain/validators/budget_validators.dart';
import 'package:ledgerly/features/budgets/presentation/providers/budget_providers.dart';

import '../domain/budget_usecases_test.dart';

void main() {
  late FakeBudgetRepository repo;
  late ProviderContainer container;

  const testBudget = Budget(
    id: 'b-1',
    categoryId: 'cat-food',
    periodId: '2026-10',
    amountMinor: 20000000,
    currency: CurrencyCode.mmk,
    alertThreshold: 0.8,
    sortOrder: 0,
    isArchived: false,
    createdAt: 1000,
    updatedAt: 1000,
  );

  setUp(() {
    repo = FakeBudgetRepository();
    container = ProviderContainer(
      overrides: [
        saveBudgetUseCaseProvider.overrideWithValue(SaveBudget(repo)),
        deleteBudgetUseCaseProvider.overrideWithValue(DeleteBudget(repo)),
        setBudgetArchivedUseCaseProvider.overrideWithValue(
          SetBudgetArchived(repo),
        ),
        getBudgetUseCaseProvider.overrideWithValue(GetBudget(repo)),
        watchBudgetsUseCaseProvider.overrideWithValue(WatchBudgets(repo)),
        watchBudgetProgressUseCaseProvider.overrideWithValue(
          WatchBudgetProgress(repo),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('BudgetPeriodNotifier', () {
    test('initializes with current period and supports previous and next', () {
      final notifier = container.read(budgetPeriodProvider.notifier);
      final initial = container.read(budgetPeriodProvider);
      expect(initial, isNotNull);

      notifier.next();
      final next = container.read(budgetPeriodProvider);
      expect(next.start.isAfter(initial.start), isTrue);

      notifier.previous();
      final back = container.read(budgetPeriodProvider);
      expect(back.start, initial.start);

      final customPeriod = BudgetPeriod(
        start: LocalDate(2027, 1, 1),
        end: LocalDate(2027, 1, 31),
      );
      notifier.jumpTo(customPeriod);
      expect(container.read(budgetPeriodProvider).id, '2027-01');
    });
  });

  group('BudgetFormNotifier', () {
    test('initializes new form with defaults', () {
      final notifier = container.read(budgetFormNotifierProvider.notifier);
      notifier.initialise(
        defaultCurrency: CurrencyCode.usd,
        currentPeriodId: '2026-10',
      );

      final state = container.read(budgetFormNotifierProvider);
      expect(state.isNew, isTrue);
      expect(state.currency, CurrencyCode.usd);
      expect(state.periodId, '2026-10');
      expect(state.isTotalBudget, isTrue);
      expect(state.amountMinor, 0);
      expect(state.alertThreshold, 0.8);
    });

    test('initializes from existing budget', () {
      final notifier = container.read(budgetFormNotifierProvider.notifier);
      notifier.initialise(budget: testBudget);

      final state = container.read(budgetFormNotifierProvider);
      expect(state.isNew, isFalse);
      expect(state.id, 'b-1');
      expect(state.categoryId, 'cat-food');
      expect(state.isTotalBudget, isFalse);
      expect(state.amountMinor, 20000000);
      expect(state.alertThreshold, 0.8);
    });

    test('validates non-positive amount on save', () async {
      final notifier = container.read(budgetFormNotifierProvider.notifier);
      notifier.initialise(budget: testBudget);
      notifier.setAmountMinor(0);

      final success = await notifier.save();
      expect(success, isFalse);

      final state = container.read(budgetFormNotifierProvider);
      expect(state.fieldErrors['amount'], BudgetValidators.amountInvalid);
      expect(state.isSaving, isFalse);
    });

    test('validates threshold outside valid range on save', () async {
      final notifier = container.read(budgetFormNotifierProvider.notifier);
      notifier.initialise(budget: testBudget);
      notifier.setAlertThreshold(0.05); // < 0.1

      final success = await notifier.save();
      expect(success, isFalse);

      final state = container.read(budgetFormNotifierProvider);
      expect(state.fieldErrors['threshold'], BudgetValidators.thresholdInvalid);
    });

    test('saves valid budget successfully', () async {
      final notifier = container.read(budgetFormNotifierProvider.notifier);
      notifier.initialise(
        defaultCurrency: CurrencyCode.mmk,
        currentPeriodId: '2026-10',
      );
      notifier.setAmountMinor(50000000);
      notifier.setCategory('cat-food');
      notifier.setAlertThreshold(0.85);

      final success = await notifier.save();
      expect(success, isTrue);

      final state = container.read(budgetFormNotifierProvider);
      expect(state.isSaved, isTrue);
      expect(state.fieldErrors, isEmpty);
      expect(repo.budgets.length, 1);
      final saved = repo.budgets.values.first;
      expect(saved.amountMinor, 50000000);
      expect(saved.categoryId, 'cat-food');
      expect(saved.alertThreshold, 0.85);
    });
  });

  group('BudgetActionNotifier', () {
    test('deleteBudget deletes budget', () async {
      repo.budgets['b-1'] = testBudget;
      final notifier = container.read(budgetActionNotifierProvider.notifier);

      final success = await notifier.deleteBudget('b-1');
      expect(success, isTrue);
      expect(repo.budgets['b-1']?.deletedAt, isNotNull);
    });

    test('setArchived toggles archived status', () async {
      repo.budgets['b-1'] = testBudget;
      final notifier = container.read(budgetActionNotifierProvider.notifier);

      final success = await notifier.setArchived('b-1', true);
      expect(success, isTrue);
      expect(repo.budgets['b-1']?.isArchived, isTrue);
    });
  });

  group('Budget derived progress providers', () {
    test('totalBudgetProgressProvider and categoryBudgetProgressListProvider split correctly', () async {
      final period = BudgetPeriod(
        start: LocalDate(2026, 10, 1),
        end: LocalDate(2026, 10, 31),
      );

      const totalBudget = Budget(
        id: 'b-total',
        categoryId: null,
        periodId: '2026-10',
        amountMinor: 100000000,
        currency: CurrencyCode.mmk,
        alertThreshold: 0.8,
        sortOrder: 0,
        isArchived: false,
        createdAt: 1000,
        updatedAt: 1000,
      );

      final totalProg = BudgetProgress(
        budget: totalBudget,
        spentMinor: 40000000,
        period: period,
      );

      final catProg = BudgetProgress(
        budget: testBudget,
        spentMinor: 15000000,
        period: period,
        categoryName: 'Food',
      );

      repo.progressList.addAll([totalProg, catProg]);

      // Override budgetProgressStreamProvider directly with dummy stream
      final testContainer = ProviderContainer(
        overrides: [
          budgetProgressStreamProvider.overrideWith(
            (ref) => Stream.value([totalProg, catProg]),
          ),
        ],
      );
      addTearDown(testContainer.dispose);

      final sub = testContainer.listen(budgetProgressStreamProvider, (_, _) {});
      addTearDown(sub.close);
      await testContainer.read(budgetProgressStreamProvider.future);

      final total = testContainer.read(totalBudgetProgressProvider);
      expect(total?.budget.id, 'b-total');
      expect(total?.isTotalBudget, isTrue);
      expect(total?.status, BudgetStatus.safe);

      final catList = testContainer.read(categoryBudgetProgressListProvider);
      expect(catList.length, 1);
      expect(catList.first.budget.id, 'b-1');
      expect(catList.first.isCategoryBudget, isTrue);
    });
  });
}
