import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/categories_dao.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/recurring/data/datasources/recurring_local_datasource.dart';
import 'package:ledgerly/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:ledgerly/features/recurring/data/services/in_app_recurring_notification_service.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_frequency.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';

void main() {
  late AppDatabase db;
  late InAppRecurringNotificationService notificationService;
  late RecurringLocalDataSource dataSource;
  late RecurringRepositoryImpl repository;
  late String testCategoryId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    notificationService = InAppRecurringNotificationService();
    dataSource = RecurringLocalDataSourceImpl(
      db,
      notificationService: notificationService,
    );
    repository = RecurringRepositoryImpl(dataSource);

    testCategoryId = await CategoriesDao(db).insert(
      name: 'Bills',
      iconKey: 'receipt',
      colorValue: 0xFF123456,
      kind: 'expense',
    );
  });

  tearDown(() async {
    notificationService.dispose();
    await db.close();
  });

  final sampleItem = RecurringTransaction(
    id: 'rec-wifi',
    categoryId: '', // will be set in test
    amount: const Money.minor(35000, CurrencyCode.mmk),
    direction: TransactionDirection.expense,
    frequency: RecurringFrequency.monthly,
    startDate: LocalDate(2026, 10, 1),
    nextDueDate: LocalDate(2026, 10, 1),
    autoAdd: true,
    note: 'Fiber Internet',
    createdAt: 1000,
    updatedAt: 1000,
  );

  test('save and get recurring transaction', () async {
    final item = sampleItem.copyWith(categoryId: testCategoryId);
    await repository.save(item);

    final retrieved = await repository.getById(item.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.id, item.id);
    expect(retrieved.amountMinor, 35000);
    expect(retrieved.note, 'Fiber Internet');
    expect(retrieved.frequency, RecurringFrequency.monthly);
  });

  test('watchAll streams recurring transactions', () async {
    final item = sampleItem.copyWith(categoryId: testCategoryId);
    await repository.save(item);

    final list = await repository.watchAll().first;
    expect(list, hasLength(1));
    expect(list.single.id, item.id);
  });

  test('skipNextDueDate advances nextDueDate by frequency', () async {
    final item = sampleItem.copyWith(categoryId: testCategoryId);
    await repository.save(item);

    await repository.skipNextDueDate(item.id);

    final updated = await repository.getById(item.id);
    expect(updated?.nextDueDate, LocalDate(2026, 11, 1));
  });

  test('setArchived toggles archived state', () async {
    final item = sampleItem.copyWith(categoryId: testCategoryId);
    await repository.save(item);

    await repository.setArchived(item.id, true);
    final activeList = await repository.watchAll(includeArchived: false).first;
    expect(activeList, isEmpty);

    final allList = await repository.watchAll(includeArchived: true).first;
    expect(allList, hasLength(1));
    expect(allList.single.isArchived, isTrue);
  });

  test('delete soft-deletes the row', () async {
    final item = sampleItem.copyWith(categoryId: testCategoryId);
    await repository.save(item);

    await repository.delete(item.id);
    final itemAfter = await repository.getById(item.id);
    expect(itemAfter, isNull);
  });

  test(
    'processDueTransactions generates real transaction for autoAdd item',
    () async {
      final item = sampleItem.copyWith(
        categoryId: testCategoryId,
        nextDueDate: LocalDate(2026, 10, 5),
      );
      await repository.save(item);

      // Process up to 2026-10-10
      final result = await repository.processDueTransactions(
        targetDate: LocalDate(2026, 10, 10),
      );

      expect(result.generatedCount, 1);
      expect(result.pendingCount, 0);

      final createdTxn = result.generatedTransactions.single;
      expect(createdTxn.categoryId, testCategoryId);
      expect(createdTxn.amountMinor, 35000);
      expect(createdTxn.date, LocalDate(2026, 10, 5));

      // Next due date should have moved to Nov 5
      final updatedRule = await repository.getById(item.id);
      expect(updatedRule?.nextDueDate, LocalDate(2026, 11, 5));
      expect(updatedRule?.lastGeneratedDate, LocalDate(2026, 10, 5));
    },
  );

  test(
    'processDueTransactions queues pending for autoAdd == false item',
    () async {
      final manualItem = sampleItem.copyWith(
        id: 'rec-manual',
        categoryId: testCategoryId,
        nextDueDate: LocalDate(2026, 10, 5),
        autoAdd: false,
      );
      await repository.save(manualItem);

      final result = await repository.processDueTransactions(
        targetDate: LocalDate(2026, 10, 10),
      );

      expect(result.generatedCount, 0);
      expect(result.pendingCount, 1);
      expect(result.pendingRecurring.single.id, 'rec-manual');

      // Due reminder should have been dispatched
      expect(
        notificationService.activeReminders.containsKey('rec-manual'),
        isTrue,
      );
    },
  );
}
