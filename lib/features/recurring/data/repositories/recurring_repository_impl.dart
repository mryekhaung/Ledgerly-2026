import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/recurring/data/datasources/recurring_local_datasource.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_process_result.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/repositories/recurring_repository.dart';

/// Implementation of [RecurringRepository] communicating with [RecurringLocalDataSource].
class RecurringRepositoryImpl implements RecurringRepository {
  const RecurringRepositoryImpl(this._dataSource);

  final RecurringLocalDataSource _dataSource;

  @override
  Stream<List<RecurringTransaction>> watchAll({bool includeArchived = false}) {
    return _dataSource.watchAll(includeArchived: includeArchived);
  }

  @override
  Future<List<RecurringTransaction>> getAllActive() {
    return _dataSource.getAllActive();
  }

  @override
  Future<RecurringTransaction?> getById(String id) {
    return _dataSource.findById(id);
  }

  @override
  Future<void> save(RecurringTransaction item) {
    return _dataSource.save(item);
  }

  @override
  Future<void> delete(String id) {
    return _dataSource.delete(id);
  }

  @override
  Future<void> setArchived(String id, bool isArchived) {
    return _dataSource.setArchived(id, isArchived);
  }

  @override
  Future<void> skipNextDueDate(String id) {
    return _dataSource.skipNextDueDate(id);
  }

  @override
  Future<RecurringProcessResult> processDueTransactions({
    LocalDate? targetDate,
  }) {
    return _dataSource.processDueTransactions(targetDate: targetDate);
  }
}
