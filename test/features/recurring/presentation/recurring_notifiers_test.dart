import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_frequency.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/usecases/delete_recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/usecases/get_recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/usecases/process_due_recurring.dart';
import 'package:ledgerly/features/recurring/domain/usecases/save_recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/usecases/set_recurring_archived.dart';
import 'package:ledgerly/features/recurring/domain/usecases/skip_recurring_occurrence.dart';
import 'package:ledgerly/features/recurring/domain/usecases/watch_recurring_transactions.dart';
import 'package:ledgerly/features/recurring/presentation/providers/recurring_providers.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';

import '../domain/recurring_usecases_test.dart';

void main() {
  late FakeRecurringRepository repo;
  late ProviderContainer container;

  final sampleItem = RecurringTransaction(
    id: 'rec-1',
    categoryId: 'cat-1',
    amount: const Money.minor(10000, CurrencyCode.mmk),
    direction: TransactionDirection.expense,
    frequency: RecurringFrequency.monthly,
    startDate: LocalDate(2026, 1, 1),
    nextDueDate: LocalDate(2026, 2, 1),
    autoAdd: true,
    isArchived: false,
    createdAt: 1000,
    updatedAt: 1000,
  );

  setUp(() {
    repo = FakeRecurringRepository();
    container = ProviderContainer(
      overrides: [
        saveRecurringTransactionUseCaseProvider.overrideWithValue(
          SaveRecurringTransaction(repo),
        ),
        deleteRecurringTransactionUseCaseProvider.overrideWithValue(
          DeleteRecurringTransaction(repo),
        ),
        setRecurringArchivedUseCaseProvider.overrideWithValue(
          SetRecurringArchived(repo),
        ),
        getRecurringTransactionUseCaseProvider.overrideWithValue(
          GetRecurringTransaction(repo),
        ),
        watchRecurringTransactionsUseCaseProvider.overrideWithValue(
          WatchRecurringTransactions(repo),
        ),
        skipRecurringOccurrenceUseCaseProvider.overrideWithValue(
          SkipRecurringOccurrence(repo),
        ),
        processDueRecurringUseCaseProvider.overrideWithValue(
          ProcessDueRecurring(repo),
        ),
        currencyProvider.overrideWith((ref) => CurrencyCode.mmk),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('RecurringFormNotifier', () {
    test('initializes for create with default values', () {
      final notifier = container.read(recurringFormNotifierProvider.notifier);
      notifier.initForCreate(categoryId: 'cat-default');

      final state = container.read(recurringFormNotifierProvider);
      expect(state.isEditing, isFalse);
      expect(state.categoryId, 'cat-default');
      expect(state.frequency, RecurringFrequency.monthly);
      expect(state.autoAdd, isTrue);
      expect(state.hasEndDate, isFalse);
      expect(state.direction, TransactionDirection.expense);
    });

    test('initializes for edit from existing transaction', () {
      final notifier = container.read(recurringFormNotifierProvider.notifier);
      notifier.initForEdit(sampleItem);

      final state = container.read(recurringFormNotifierProvider);
      expect(state.isEditing, isTrue);
      expect(state.id, 'rec-1');
      expect(state.amountMinor, 10000);
      expect(state.categoryId, 'cat-1');
      expect(state.direction, TransactionDirection.expense);
      expect(state.frequency, RecurringFrequency.monthly);
    });

    test('validates required category and positive amount', () async {
      final notifier = container.read(recurringFormNotifierProvider.notifier);
      notifier.initForCreate();
      notifier.setAmountMinor(0);
      notifier.setCategory('');

      final saved = await notifier.save();
      expect(saved, isFalse);

      final state = container.read(recurringFormNotifierProvider);
      expect(state.fieldErrors['amount'], isNotNull);
      expect(state.fieldErrors['category'], isNotNull);
    });

    test('validates end date not before start date', () async {
      final notifier = container.read(recurringFormNotifierProvider.notifier);
      notifier.initForCreate(categoryId: 'cat-1');
      notifier.setAmountMinor(5000);
      notifier.setStartDate(LocalDate(2026, 5, 10));
      notifier.setHasEndDate(true);
      notifier.setEndDate(LocalDate(2026, 5, 5));

      final saved = await notifier.save();
      expect(saved, isFalse);

      final state = container.read(recurringFormNotifierProvider);
      expect(state.fieldErrors['endDate'], isNotNull);
    });

    test('saves successfully with valid data', () async {
      final notifier = container.read(recurringFormNotifierProvider.notifier);
      notifier.initForCreate(categoryId: 'cat-rent');
      notifier.setAmountMinor(250000);
      notifier.setFrequency(RecurringFrequency.monthly);
      notifier.setStartDate(LocalDate(2026, 10, 1));
      notifier.setNote('Monthly Rent');

      final saved = await notifier.save();
      expect(saved, isTrue);

      final all = await repo.getAllActive();
      expect(all, hasLength(1));
      expect(all.first.amountMinor, 250000);
      expect(all.first.categoryId, 'cat-rent');
      expect(all.first.note, 'Monthly Rent');
    });
  });

  group('RecurringSchedulerNotifier', () {
    test('runs scheduler and sets lastResult', () async {
      await repo.save(
        sampleItem.copyWith(nextDueDate: LocalDate(2026, 10, 10)),
      );

      final notifier = container.read(
        recurringSchedulerNotifierProvider.notifier,
      );
      final result = await notifier.runScheduler(
        targetDate: LocalDate(2026, 10, 14),
      );

      expect(result.generatedCount, 1);
      final state = container.read(recurringSchedulerNotifierProvider);
      expect(state.lastResult?.generatedCount, 1);
      expect(state.isProcessing, isFalse);
    });

    test('skips occurrence', () async {
      await repo.save(sampleItem);
      final notifier = container.read(
        recurringSchedulerNotifierProvider.notifier,
      );

      await notifier.skipOccurrence('rec-1');
      final updated = await repo.getById('rec-1');
      expect(updated?.nextDueDate, LocalDate(2026, 3, 1));
    });

    test('pauses and resumes rule', () async {
      await repo.save(sampleItem);
      final notifier = container.read(
        recurringSchedulerNotifierProvider.notifier,
      );

      await notifier.setArchived('rec-1', true);
      var item = await repo.getById('rec-1');
      expect(item?.isArchived, isTrue);

      await notifier.setArchived('rec-1', false);
      item = await repo.getById('rec-1');
      expect(item?.isArchived, isFalse);
    });

    test('deletes rule', () async {
      await repo.save(sampleItem);
      final notifier = container.read(
        recurringSchedulerNotifierProvider.notifier,
      );

      await notifier.delete('rec-1');
      final item = await repo.getById('rec-1');
      expect(item?.deletedAt, isNotNull);
    });
  });
}
