import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/di/injection.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/goals/domain/entities/savings_goal.dart';
import 'package:ledgerly/features/goals/domain/repositories/savings_goals_repository.dart';
import 'package:ledgerly/features/goals/domain/usecases/add_goal_contribution.dart';
import 'package:ledgerly/features/goals/domain/usecases/delete_savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/get_savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/save_savings_goal.dart';
import 'package:ledgerly/features/goals/domain/usecases/set_goal_archived.dart';
import 'package:ledgerly/features/goals/domain/usecases/watch_savings_goals.dart';
import 'package:ledgerly/features/goals/domain/usecases/withdraw_from_goal.dart';

// --- Dependency Injection Bridges ---

final goalsRepositoryProvider = Provider<SavingsGoalsRepository>((ref) {
  return getIt<SavingsGoalsRepository>();
});

final watchSavingsGoalsProvider = Provider<WatchSavingsGoals>((ref) {
  return getIt<WatchSavingsGoals>();
});

final getSavingsGoalProvider = Provider<GetSavingsGoal>((ref) {
  return getIt<GetSavingsGoal>();
});

final saveSavingsGoalProvider = Provider<SaveSavingsGoal>((ref) {
  return getIt<SaveSavingsGoal>();
});

final addGoalContributionProvider = Provider<AddGoalContribution>((ref) {
  return getIt<AddGoalContribution>();
});

final withdrawFromGoalProvider = Provider<WithdrawFromGoal>((ref) {
  return getIt<WithdrawFromGoal>();
});

final setGoalArchivedProvider = Provider<SetGoalArchived>((ref) {
  return getIt<SetGoalArchived>();
});

final deleteSavingsGoalProvider = Provider<DeleteSavingsGoal>((ref) {
  return getIt<DeleteSavingsGoal>();
});

// --- Stream Providers ---

final goalsListStreamProvider = StreamProvider<List<SavingsGoal>>((ref) {
  final watch = ref.watch(watchSavingsGoalsProvider);
  return watch(const WatchSavingsGoalsParams(includeArchived: false));
});

final allGoalsStreamProvider = StreamProvider<List<SavingsGoal>>((ref) {
  final watch = ref.watch(watchSavingsGoalsProvider);
  return watch(const WatchSavingsGoalsParams(includeArchived: true));
});

final activeGoalsProvider = Provider<AsyncValue<List<SavingsGoal>>>((ref) {
  final asyncGoals = ref.watch(goalsListStreamProvider);
  return asyncGoals.whenData(
    (goals) => goals.where((g) => !g.isCompleted && !g.isArchived).toList(),
  );
});

final completedGoalsProvider = Provider<AsyncValue<List<SavingsGoal>>>((ref) {
  final asyncGoals = ref.watch(goalsListStreamProvider);
  return asyncGoals.whenData(
    (goals) => goals.where((g) => g.isCompleted && !g.isArchived).toList(),
  );
});

final archivedGoalsProvider = Provider<AsyncValue<List<SavingsGoal>>>((ref) {
  final asyncGoals = ref.watch(allGoalsStreamProvider);
  return asyncGoals.whenData(
    (goals) => goals.where((g) => g.isArchived).toList(),
  );
});

final goalByIdProvider = FutureProvider.family<SavingsGoal?, String>((
  ref,
  id,
) async {
  final getGoal = ref.watch(getSavingsGoalProvider);
  final result = await getGoal(GetSavingsGoalParams(id: id));
  return result.valueOrNull;
});

// --- Goal Form State & Notifier ---

class GoalFormState {
  const GoalFormState({
    this.id,
    this.name = '',
    this.targetAmountMinor = 0,
    this.currentAmountMinor = 0,
    this.currency = CurrencyCode.mmk,
    this.targetDate,
    this.accountId,
    this.iconKey = 'savings',
    this.colorValue = 0xFF2E7D32,
    this.notes,
    this.isSubmitting = false,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  final String? id;
  final String name;
  final int targetAmountMinor;
  final int currentAmountMinor;
  final CurrencyCode currency;
  final LocalDate? targetDate;
  final String? accountId;
  final String iconKey;
  final int colorValue;
  final String? notes;
  final bool isSubmitting;
  final String? errorMessage;
  final Map<String, String> fieldErrors;

  bool get isEditMode => id != null;

  GoalFormState copyWith({
    String? id,
    String? name,
    int? targetAmountMinor,
    int? currentAmountMinor,
    CurrencyCode? currency,
    LocalDate? Function()? targetDate,
    String? Function()? accountId,
    String? iconKey,
    int? colorValue,
    String? Function()? notes,
    bool? isSubmitting,
    String? Function()? errorMessage,
    Map<String, String>? fieldErrors,
  }) {
    return GoalFormState(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmountMinor: targetAmountMinor ?? this.targetAmountMinor,
      currentAmountMinor: currentAmountMinor ?? this.currentAmountMinor,
      currency: currency ?? this.currency,
      targetDate: targetDate != null ? targetDate() : this.targetDate,
      accountId: accountId != null ? accountId() : this.accountId,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      notes: notes != null ? notes() : this.notes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

class GoalFormNotifier extends Notifier<GoalFormState> {
  @override
  GoalFormState build() => const GoalFormState();

  void init(SavingsGoal? existing) {
    if (existing == null) {
      state = const GoalFormState();
      return;
    }
    state = GoalFormState(
      id: existing.id,
      name: existing.name,
      targetAmountMinor: existing.targetAmount.amountMinor,
      currentAmountMinor: existing.currentAmount.amountMinor,
      currency: existing.targetAmount.currency,
      targetDate: existing.targetDate,
      accountId: existing.accountId,
      iconKey: existing.iconKey,
      colorValue: existing.colorValue,
      notes: existing.notes,
    );
  }

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setTargetAmount(int amountMinor) {
    state = state.copyWith(targetAmountMinor: amountMinor);
  }

  void setCurrentAmount(int amountMinor) {
    state = state.copyWith(currentAmountMinor: amountMinor);
  }

  void setCurrency(CurrencyCode currency) {
    state = state.copyWith(currency: currency);
  }

  void setTargetDate(LocalDate? date) {
    state = state.copyWith(targetDate: () => date);
  }

  void setAccountId(String? accountId) {
    state = state.copyWith(accountId: () => accountId);
  }

  void setIconKey(String iconKey) {
    state = state.copyWith(iconKey: iconKey);
  }

  void setColorValue(int colorValue) {
    state = state.copyWith(colorValue: colorValue);
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: () => notes);
  }

  Future<bool> submit() async {
    state = state.copyWith(isSubmitting: true, errorMessage: () => null);

    final now = DateTime.now().toUtc();
    final goal = SavingsGoal(
      id: state.id ?? '',
      name: state.name.trim(),
      targetAmount: Money.minor(state.targetAmountMinor, state.currency),
      currentAmount: Money.minor(state.currentAmountMinor, state.currency),
      targetDate: state.targetDate,
      accountId: state.accountId,
      iconKey: state.iconKey,
      colorValue: state.colorValue,
      notes: state.notes?.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final saveUseCase = ref.read(saveSavingsGoalProvider);
    final result = await saveUseCase(SaveSavingsGoalParams(goal: goal));

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(isSubmitting: false);
        return true;
      },
      onErr: (failure) {
        if (failure is ValidationFailure) {
          state = state.copyWith(
            isSubmitting: false,
            fieldErrors: failure.fieldErrors,
            errorMessage: () => failure.message,
          );
        } else {
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: () => failure.message,
          );
        }
        return false;
      },
    );
  }
}

final goalFormProvider = NotifierProvider<GoalFormNotifier, GoalFormState>(
  GoalFormNotifier.new,
);
