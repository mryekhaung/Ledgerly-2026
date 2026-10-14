import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/di/injection.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_progress.dart';
import 'package:ledgerly/features/budgets/domain/usecases/delete_budget.dart';
import 'package:ledgerly/features/budgets/domain/usecases/get_budget.dart';
import 'package:ledgerly/features/budgets/domain/usecases/get_budget_progress.dart';
import 'package:ledgerly/features/budgets/domain/usecases/save_budget.dart';
import 'package:ledgerly/features/budgets/domain/usecases/set_budget_archived.dart';
import 'package:ledgerly/features/budgets/domain/usecases/watch_budget_progress.dart';
import 'package:ledgerly/features/budgets/domain/usecases/watch_budgets.dart';
import 'package:ledgerly/features/budgets/domain/validators/budget_validators.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';

// --- Bridge Providers ---

final watchBudgetsUseCaseProvider = Provider<WatchBudgets>(
  (_) => getIt<WatchBudgets>(),
);

final getBudgetUseCaseProvider = Provider<GetBudget>((_) => getIt<GetBudget>());

final saveBudgetUseCaseProvider = Provider<SaveBudget>(
  (_) => getIt<SaveBudget>(),
);

final deleteBudgetUseCaseProvider = Provider<DeleteBudget>(
  (_) => getIt<DeleteBudget>(),
);

final setBudgetArchivedUseCaseProvider = Provider<SetBudgetArchived>(
  (_) => getIt<SetBudgetArchived>(),
);

final watchBudgetProgressUseCaseProvider = Provider<WatchBudgetProgress>(
  (_) => getIt<WatchBudgetProgress>(),
);

final getBudgetProgressUseCaseProvider = Provider<GetBudgetProgress>(
  (_) => getIt<GetBudgetProgress>(),
);

// --- Period Notifier ---

/// Active budget period browsed on the Budgets page.
final budgetPeriodProvider =
    NotifierProvider<BudgetPeriodNotifier, BudgetPeriod>(
      BudgetPeriodNotifier.new,
    );

class BudgetPeriodNotifier extends Notifier<BudgetPeriod> {
  @override
  BudgetPeriod build() {
    final calculator = ref.watch(periodCalculatorProvider);
    final today = LocalDate.fromDateTime(DateTime.now());
    return calculator.containing(today);
  }

  void previous() {
    final calculator = ref.read(periodCalculatorProvider);
    state = calculator.previous(state);
  }

  void next() {
    final calculator = ref.read(periodCalculatorProvider);
    state = calculator.next(state);
  }

  void jumpTo(BudgetPeriod period) {
    state = period;
  }
}

// --- Live Progress Streams ---

/// Reactive stream of progress for all budgets in the current period.
final budgetProgressStreamProvider =
    StreamProvider.autoDispose<List<BudgetProgress>>((ref) {
      final period = ref.watch(budgetPeriodProvider);
      final useCase = ref.watch(watchBudgetProgressUseCaseProvider);

      return useCase(period).map(
        (result) => result.fold(
          onSuccess: (list) => list,
          onErr: (_) => const <BudgetProgress>[],
        ),
      );
    });

/// Overall total period budget progress, or null if no overall cap was set.
final totalBudgetProgressProvider = Provider.autoDispose<BudgetProgress?>((
  ref,
) {
  final list = ref.watch(budgetProgressStreamProvider).value ?? const [];
  return list.where((p) => p.isTotalBudget).firstOrNull;
});

/// List of category-specific budget progresses for the active period.
final categoryBudgetProgressListProvider =
    Provider.autoDispose<List<BudgetProgress>>((ref) {
      final list = ref.watch(budgetProgressStreamProvider).value ?? const [];
      return list.where((p) => p.isCategoryBudget).toList();
    });

/// Stream of all active (non-archived) budget configurations.
final budgetsListStreamProvider = StreamProvider.autoDispose<List<Budget>>((
  ref,
) {
  final useCase = ref.watch(watchBudgetsUseCaseProvider);
  return useCase(const WatchBudgetsParams()).map(
    (result) =>
        result.fold(onSuccess: (list) => list, onErr: (_) => const <Budget>[]),
  );
});

// --- Action Notifier ---

final budgetActionNotifierProvider =
    NotifierProvider.autoDispose<BudgetActionNotifier, AsyncValue<void>>(
      BudgetActionNotifier.new,
    );

class BudgetActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> deleteBudget(String id) async {
    state = const AsyncValue.loading();
    final useCase = ref.read(deleteBudgetUseCaseProvider);
    final result = await useCase(id);
    return result.fold(
      onSuccess: (_) {
        state = const AsyncValue.data(null);
        return true;
      },
      onErr: (f) {
        state = AsyncValue.error(f, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> setArchived(String id, bool isArchived) async {
    state = const AsyncValue.loading();
    final useCase = ref.read(setBudgetArchivedUseCaseProvider);
    final result = await useCase(
      SetBudgetArchivedParams(id: id, isArchived: isArchived),
    );
    return result.fold(
      onSuccess: (_) {
        state = const AsyncValue.data(null);
        return true;
      },
      onErr: (f) {
        state = AsyncValue.error(f, StackTrace.current);
        return false;
      },
    );
  }
}

// --- Form State & Notifier ---

class BudgetFormState {
  const BudgetFormState({
    this.id,
    this.categoryId,
    this.periodId,
    this.amountMinor = 0,
    this.currency = CurrencyCode.mmk,
    this.alertThreshold = 0.8,
    this.sortOrder = 0,
    this.isArchived = false,
    this.isNew = true,
    this.isSaving = false,
    this.errorMessage,
    this.isSaved = false,
    this.fieldErrors = const {},
  });

  final String? id;
  final String? categoryId;
  final String? periodId;
  final int amountMinor;
  final CurrencyCode currency;
  final double alertThreshold;
  final int sortOrder;
  final bool isArchived;
  final bool isNew;
  final bool isSaving;
  final String? errorMessage;
  final bool isSaved;
  final Map<String, String> fieldErrors;

  bool get isTotalBudget => categoryId == null;

  BudgetFormState copyWith({
    String? id,
    String? categoryId,
    bool clearCategoryId = false,
    String? periodId,
    bool clearPeriodId = false,
    int? amountMinor,
    CurrencyCode? currency,
    double? alertThreshold,
    int? sortOrder,
    bool? isArchived,
    bool? isNew,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool? isSaved,
    Map<String, String>? fieldErrors,
  }) {
    return BudgetFormState(
      id: id ?? this.id,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      periodId: clearPeriodId ? null : (periodId ?? this.periodId),
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      isNew: isNew ?? this.isNew,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSaved: isSaved ?? this.isSaved,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

final budgetFormNotifierProvider =
    NotifierProvider.autoDispose<BudgetFormNotifier, BudgetFormState>(
      BudgetFormNotifier.new,
    );

class BudgetFormNotifier extends Notifier<BudgetFormState> {
  @override
  BudgetFormState build() => const BudgetFormState();

  void initialise({
    Budget? budget,
    CurrencyCode? defaultCurrency,
    String? currentPeriodId,
  }) {
    if (budget != null) {
      state = BudgetFormState(
        id: budget.id,
        categoryId: budget.categoryId,
        periodId: budget.periodId,
        amountMinor: budget.amountMinor,
        currency: budget.currency,
        alertThreshold: budget.alertThreshold,
        sortOrder: budget.sortOrder,
        isArchived: budget.isArchived,
        isNew: false,
      );
    } else {
      state = BudgetFormState(
        currency: defaultCurrency ?? CurrencyCode.mmk,
        periodId: currentPeriodId,
        isNew: true,
      );
    }
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(
      categoryId: categoryId,
      clearCategoryId: categoryId == null,
      fieldErrors: Map.of(state.fieldErrors)..remove('category'),
    );
  }

  void setAmountMinor(int amountMinor) {
    state = state.copyWith(
      amountMinor: amountMinor,
      fieldErrors: Map.of(state.fieldErrors)..remove('amount'),
    );
  }

  void setAlertThreshold(double threshold) {
    state = state.copyWith(
      alertThreshold: threshold,
      fieldErrors: Map.of(state.fieldErrors)..remove('threshold'),
    );
  }

  void setPeriodId(String? periodId) {
    state = state.copyWith(periodId: periodId, clearPeriodId: periodId == null);
  }

  Future<bool> save() async {
    final fieldErrors = <String, String>{};

    final amountErr = BudgetValidators.validateAmount(state.amountMinor);
    if (amountErr != null) {
      fieldErrors['amount'] = amountErr;
    }

    final thresholdErr = BudgetValidators.validateThreshold(
      state.alertThreshold,
    );
    if (thresholdErr != null) {
      fieldErrors['threshold'] = thresholdErr;
    }

    if (fieldErrors.isNotEmpty) {
      state = state.copyWith(
        fieldErrors: fieldErrors,
        errorMessage: fieldErrors.values.first,
      );
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    final budget = Budget(
      id: state.id ?? '',
      categoryId: state.categoryId,
      periodId: state.periodId,
      amountMinor: state.amountMinor,
      currency: state.currency,
      alertThreshold: state.alertThreshold,
      sortOrder: state.sortOrder,
      isArchived: state.isArchived,
      createdAt: 0,
      updatedAt: 0,
    );

    final useCase = ref.read(saveBudgetUseCaseProvider);
    final result = await useCase(
      SaveBudgetParams(budget: budget, isNew: state.isNew),
    );

    return result.fold(
      onSuccess: (saved) {
        state = state.copyWith(isSaving: false, isSaved: true);
        return true;
      },
      onErr: (failure) {
        state = state.copyWith(isSaving: false, errorMessage: failure.message);
        return false;
      },
    );
  }
}
