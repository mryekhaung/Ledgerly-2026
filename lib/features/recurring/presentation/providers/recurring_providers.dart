import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/di/injection.dart';
import 'package:ledgerly/core/database/uuid.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_frequency.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_process_result.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/usecases/delete_recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/usecases/get_recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/usecases/process_due_recurring.dart';
import 'package:ledgerly/features/recurring/domain/usecases/save_recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/usecases/set_recurring_archived.dart';
import 'package:ledgerly/features/recurring/domain/usecases/skip_recurring_occurrence.dart';
import 'package:ledgerly/features/recurring/domain/usecases/watch_recurring_transactions.dart';
import 'package:ledgerly/features/recurring/domain/validators/recurring_validators.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';

// --- Bridge Providers ---

final watchRecurringTransactionsUseCaseProvider =
    Provider<WatchRecurringTransactions>(
      (_) => getIt<WatchRecurringTransactions>(),
    );

final getRecurringTransactionUseCaseProvider =
    Provider<GetRecurringTransaction>((_) => getIt<GetRecurringTransaction>());

final saveRecurringTransactionUseCaseProvider =
    Provider<SaveRecurringTransaction>(
      (_) => getIt<SaveRecurringTransaction>(),
    );

final deleteRecurringTransactionUseCaseProvider =
    Provider<DeleteRecurringTransaction>(
      (_) => getIt<DeleteRecurringTransaction>(),
    );

final setRecurringArchivedUseCaseProvider = Provider<SetRecurringArchived>(
  (_) => getIt<SetRecurringArchived>(),
);

final skipRecurringOccurrenceUseCaseProvider =
    Provider<SkipRecurringOccurrence>((_) => getIt<SkipRecurringOccurrence>());

final processDueRecurringUseCaseProvider = Provider<ProcessDueRecurring>(
  (_) => getIt<ProcessDueRecurring>(),
);

// --- Data Streams & State Providers ---

/// Stream of all live recurring transaction rules (including paused ones).
final recurringListStreamProvider =
    StreamProvider.autoDispose<List<RecurringTransaction>>((ref) {
      final useCase = ref.watch(watchRecurringTransactionsUseCaseProvider);
      return useCase(includeArchived: true);
    });

/// List of currently active (non-paused) recurring transactions.
final activeRecurringListProvider =
    Provider.autoDispose<List<RecurringTransaction>>((ref) {
      final listAsync = ref.watch(recurringListStreamProvider);
      final list = listAsync.value ?? const <RecurringTransaction>[];
      return list.where((t) => t.isActive).toList();
    });

/// List of paused/archived recurring transactions.
final pausedRecurringListProvider =
    Provider.autoDispose<List<RecurringTransaction>>((ref) {
      final listAsync = ref.watch(recurringListStreamProvider);
      final list = listAsync.value ?? const <RecurringTransaction>[];
      return list.where((t) => t.isArchived && t.deletedAt == null).toList();
    });

/// List of recurring transactions due on or before today.
final dueRecurringListProvider =
    Provider.autoDispose<List<RecurringTransaction>>((ref) {
      final active = ref.watch(activeRecurringListProvider);
      final today = LocalDate.fromDateTime(DateTime.now());
      return active.where((t) => t.isDue(today)).toList();
    });

// --- Recurring Form State & Notifier ---

final class RecurringFormState {
  const RecurringFormState({
    required this.categoryId,
    required this.amountMinor,
    required this.currency,
    required this.direction,
    required this.frequency,
    required this.startDate,
    required this.autoAdd,
    this.id,
    this.accountId,
    this.endDate,
    this.hasEndDate = false,
    this.note,
    this.isSubmitting = false,
    this.errorMessage,
    this.fieldErrors = const <String, String>{},
  });

  final String? id;
  final String categoryId;
  final String? accountId;
  final int amountMinor;
  final CurrencyCode currency;
  final TransactionDirection direction;
  final RecurringFrequency frequency;
  final LocalDate startDate;
  final LocalDate? endDate;
  final bool hasEndDate;
  final bool autoAdd;
  final String? note;
  final bool isSubmitting;
  final String? errorMessage;
  final Map<String, String> fieldErrors;

  bool get isEditing => id != null;

  RecurringFormState copyWith({
    String? id,
    String? categoryId,
    String? accountId,
    bool clearAccountId = false,
    int? amountMinor,
    CurrencyCode? currency,
    TransactionDirection? direction,
    RecurringFrequency? frequency,
    LocalDate? startDate,
    LocalDate? endDate,
    bool clearEndDate = false,
    bool? hasEndDate,
    bool? autoAdd,
    String? note,
    bool clearNote = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    Map<String, String>? fieldErrors,
  }) {
    return RecurringFormState(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      direction: direction ?? this.direction,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      hasEndDate: hasEndDate ?? this.hasEndDate,
      autoAdd: autoAdd ?? this.autoAdd,
      note: clearNote ? null : (note ?? this.note),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

class RecurringFormNotifier extends Notifier<RecurringFormState> {
  @override
  RecurringFormState build() {
    final currency = ref.watch(currencyProvider);
    final today = LocalDate.fromDateTime(DateTime.now());
    return RecurringFormState(
      categoryId: '',
      amountMinor: 0,
      currency: currency,
      direction: TransactionDirection.expense,
      frequency: RecurringFrequency.monthly,
      startDate: today,
      autoAdd: true,
    );
  }

  void initForCreate({
    String? categoryId,
    TransactionDirection direction = TransactionDirection.expense,
  }) {
    final currency = ref.read(currencyProvider);
    final today = LocalDate.fromDateTime(DateTime.now());
    state = RecurringFormState(
      categoryId: categoryId ?? '',
      amountMinor: 0,
      currency: currency,
      direction: direction,
      frequency: RecurringFrequency.monthly,
      startDate: today,
      autoAdd: true,
    );
  }

  void initForEdit(RecurringTransaction item) {
    state = RecurringFormState(
      id: item.id,
      categoryId: item.categoryId,
      accountId: item.accountId,
      amountMinor: item.amountMinor,
      currency: item.currency,
      direction: item.direction,
      frequency: item.frequency,
      startDate: item.startDate,
      endDate: item.endDate,
      hasEndDate: item.endDate != null,
      autoAdd: item.autoAdd,
      note: item.note,
    );
  }

  void setCategory(String categoryId) {
    state = state.copyWith(categoryId: categoryId, clearError: true);
  }

  void setAccount(String? accountId) {
    state = state.copyWith(
      accountId: accountId,
      clearAccountId: accountId == null,
      clearError: true,
    );
  }

  void setAmountMinor(int minor) {
    state = state.copyWith(amountMinor: minor, clearError: true);
  }

  void setCurrency(CurrencyCode currency) {
    state = state.copyWith(currency: currency);
  }

  void setDirection(TransactionDirection direction) {
    state = state.copyWith(direction: direction);
  }

  void setFrequency(RecurringFrequency frequency) {
    state = state.copyWith(frequency: frequency);
  }

  void setStartDate(LocalDate date) {
    state = state.copyWith(startDate: date, clearError: true);
  }

  void setEndDate(LocalDate? date) {
    state = state.copyWith(
      endDate: date,
      clearEndDate: date == null,
      clearError: true,
    );
  }

  void setHasEndDate(bool hasEnd) {
    state = state.copyWith(
      hasEndDate: hasEnd,
      clearEndDate: !hasEnd,
      clearError: true,
    );
  }

  void setAutoAdd(bool autoAdd) {
    state = state.copyWith(autoAdd: autoAdd);
  }

  void setNote(String? note) {
    state = state.copyWith(note: note, clearNote: note == null);
  }

  /// Validates inputs and saves the recurring transaction rule.
  Future<bool> save() async {
    final fieldErrors = <String, String>{};

    final categoryError = RecurringValidators.validateCategory(
      state.categoryId,
    );
    if (categoryError != null) {
      fieldErrors['category'] = categoryError;
    }

    final amountError = RecurringValidators.validateAmount(state.amountMinor);
    if (amountError != null) {
      fieldErrors['amount'] = amountError;
    }

    final dateError = RecurringValidators.validateDates(
      state.startDate,
      state.hasEndDate ? state.endDate : null,
    );
    if (dateError != null) {
      fieldErrors['dates'] = dateError;
      fieldErrors['endDate'] = dateError;
    }

    if (fieldErrors.isNotEmpty) {
      state = state.copyWith(
        fieldErrors: fieldErrors,
        errorMessage: fieldErrors.values.first,
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final saveUseCase = ref.read(saveRecurringTransactionUseCaseProvider);

      final nextDue = state.isEditing
          ? state
                .startDate // will preserve existing if not modified
          : state.startDate;

      final item = RecurringTransaction(
        id: state.id ?? generateUuid(),
        categoryId: state.categoryId,
        accountId: state.accountId,
        amount: Money.minor(state.amountMinor, state.currency),
        direction: state.direction,
        frequency: state.frequency,
        startDate: state.startDate,
        endDate: state.hasEndDate ? state.endDate : null,
        nextDueDate: nextDue,
        autoAdd: state.autoAdd,
        note: state.note,
        createdAt: now,
        updatedAt: now,
      );

      await saveUseCase(item);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }
}

final recurringFormNotifierProvider =
    NotifierProvider.autoDispose<RecurringFormNotifier, RecurringFormState>(
      RecurringFormNotifier.new,
    );

// --- Scheduler Actions Notifier ---

final class RecurringSchedulerState {
  const RecurringSchedulerState({
    this.isProcessing = false,
    this.lastResult,
    this.errorMessage,
  });

  final bool isProcessing;
  final RecurringProcessResult? lastResult;
  final String? errorMessage;
}

class RecurringSchedulerNotifier extends Notifier<RecurringSchedulerState> {
  @override
  RecurringSchedulerState build() => const RecurringSchedulerState();

  /// Runs the recurring transaction scheduler on app open / resume or manual trigger.
  Future<RecurringProcessResult> runScheduler({LocalDate? targetDate}) async {
    state = const RecurringSchedulerState(isProcessing: true);
    try {
      final processUseCase = ref.read(processDueRecurringUseCaseProvider);
      final result = await processUseCase(targetDate: targetDate);
      state = RecurringSchedulerState(isProcessing: false, lastResult: result);
      return result;
    } catch (e) {
      state = RecurringSchedulerState(
        isProcessing: false,
        errorMessage: e.toString(),
      );
      return RecurringProcessResult.empty;
    }
  }

  /// Skips the next occurrence date for [id].
  Future<void> skipOccurrence(String id) async {
    final skipUseCase = ref.read(skipRecurringOccurrenceUseCaseProvider);
    await skipUseCase(id);
  }

  /// Pauses or resumes the recurring rule [id].
  Future<void> setArchived(String id, bool isArchived) async {
    final setArchivedUseCase = ref.read(setRecurringArchivedUseCaseProvider);
    await setArchivedUseCase(id: id, isArchived: isArchived);
  }

  /// Deletes the recurring rule [id].
  Future<void> delete(String id) async {
    final deleteUseCase = ref.read(deleteRecurringTransactionUseCaseProvider);
    await deleteUseCase(id);
  }
}

final recurringSchedulerNotifierProvider =
    NotifierProvider<RecurringSchedulerNotifier, RecurringSchedulerState>(
      RecurringSchedulerNotifier.new,
    );
