import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/app_database.dart' hide Transaction;
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/recurring/data/mappers/recurring_mapper.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_process_result.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/services/recurring_notification_service.dart';
import 'package:ledgerly/features/transactions/data/mappers/transaction_mapper.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';

abstract class RecurringLocalDataSource {
  Stream<List<RecurringTransaction>> watchAll({bool includeArchived = false});

  Future<List<RecurringTransaction>> getAllActive();

  Future<RecurringTransaction?> findById(String id);

  Future<void> save(RecurringTransaction item);

  Future<void> delete(String id);

  Future<void> setArchived(String id, bool isArchived);

  Future<void> skipNextDueDate(String id);

  Future<RecurringProcessResult> processDueTransactions({
    LocalDate? targetDate,
  });
}

class RecurringLocalDataSourceImpl implements RecurringLocalDataSource {
  RecurringLocalDataSourceImpl(
    this._db, {
    required this.notificationService,
    this.clock = const Clock(),
  });

  final AppDatabase _db;
  final RecurringNotificationService notificationService;
  final Clock clock;

  @override
  Stream<List<RecurringTransaction>> watchAll({bool includeArchived = false}) {
    return _db.recurringDao
        .watchAll(includeArchived: includeArchived)
        .map((rows) => rows.map(RecurringMapper.toEntity).toList());
  }

  @override
  Future<List<RecurringTransaction>> getAllActive() async {
    final rows = await _db.recurringDao.watchAll(includeArchived: false).first;
    return rows.map(RecurringMapper.toEntity).toList();
  }

  @override
  Future<RecurringTransaction?> findById(String id) async {
    final row = await _db.recurringDao.findById(id);
    return row == null ? null : RecurringMapper.toEntity(row);
  }

  @override
  Future<void> save(RecurringTransaction item) async {
    final existing = await _db.recurringDao.findById(item.id);
    final companion = RecurringMapper.toCompanion(item);
    if (existing == null) {
      await _db.recurringDao.insertRow(companion);
    } else {
      await _db.recurringDao.updateById(item.id, companion);
    }
  }

  @override
  Future<void> delete(String id) async {
    await _db.recurringDao.softDelete(id);
    await notificationService.cancelReminder(id);
  }

  @override
  Future<void> setArchived(String id, bool isArchived) async {
    await _db.recurringDao.setArchived(id, isArchived);
    if (isArchived) {
      await notificationService.cancelReminder(id);
    }
  }

  @override
  Future<void> skipNextDueDate(String id) async {
    final row = await _db.recurringDao.findById(id);
    if (row == null) return;
    final entity = RecurringMapper.toEntity(row);
    final next = entity.frequency.nextDate(entity.nextDueDate);
    await _db.recurringDao.updateById(
      id,
      RecurringTransactionsCompanion(
        nextDueDate: Value(next),
        updatedAt: Value(clock.nowUtcMillis()),
      ),
    );
  }

  @override
  Future<RecurringProcessResult> processDueTransactions({
    LocalDate? targetDate,
  }) async {
    final today =
        targetDate ??
        LocalDate.fromDateTime(
          DateTime.fromMillisecondsSinceEpoch(
            clock.nowUtcMillis(),
            isUtc: true,
          ),
        );
    final dueRows = await _db.recurringDao.getActiveDue(today);

    final generated = <Transaction>[];
    final pending = <RecurringTransaction>[];

    for (final row in dueRows) {
      var currentDueDate = row.nextDueDate;
      final frequency = RecurringMapper.toEntity(row).frequency;
      var lastGenDate = row.lastGeneratedDate;
      var isArchived = row.isArchived;

      // Handle catch-up loop (in case app was not opened for multiple periods)
      while (!currentDueDate.isAfter(today) && !isArchived) {
        // Expiration check
        if (row.endDate != null && currentDueDate.isAfter(row.endDate!)) {
          isArchived = true;
          break;
        }

        if (row.autoAdd) {
          // Generate a real transaction
          final txnId = await _db.transactionsDao.insert(
            categoryId: row.categoryId,
            accountId: row.accountId,
            amountMinor: row.amountMinor,
            currency: row.currency,
            direction: row.direction,
            date: currentDueDate,
            note: row.note,
          );
          final txnRow = await _db.transactionsDao.findById(txnId);
          if (txnRow != null) {
            generated.add(TransactionMapper.toEntity(txnRow));
          }

          lastGenDate = currentDueDate;
          currentDueDate = frequency.nextDate(currentDueDate);

          // If next occurrence exceeds end date, archive
          if (row.endDate != null && currentDueDate.isAfter(row.endDate!)) {
            isArchived = true;
          }
        } else {
          // Requires user confirmation
          pending.add(
            RecurringMapper.toEntity(row).copyWith(nextDueDate: currentDueDate),
          );
          break;
        }
      }

      // Update recurring rule row
      await _db.recurringDao.updateById(
        row.id,
        RecurringTransactionsCompanion(
          nextDueDate: Value(currentDueDate),
          lastGeneratedDate: Value(lastGenDate),
          isArchived: Value(isArchived),
          updatedAt: Value(clock.nowUtcMillis()),
        ),
      );
    }

    // Trigger notifications if needed
    if (generated.isNotEmpty) {
      await notificationService.showGeneratedNotification(
        count: generated.length,
        summary: 'Generated ${generated.length} recurring transaction(s)',
      );
    }

    for (final item in pending) {
      await notificationService.showDueReminder(
        id: item.id,
        title: 'Recurring transaction due',
        body:
            '${item.amount.amountMinor} ${item.currency.code.toUpperCase()} is due on ${item.nextDueDate}',
      );
    }

    return RecurringProcessResult(
      generatedTransactions: generated,
      pendingRecurring: pending,
    );
  }
}
