import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/di/injection.dart';
import 'package:ledgerly/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:ledgerly/features/transactions/domain/usecases/save_transaction.dart';
import 'package:ledgerly/features/transactions/domain/usecases/watch_transactions.dart';

/// Thin bridge between get_it and Riverpod for the transaction use cases.
///
/// See the categories bridge for why these are plain, non-disposed providers:
/// the use cases are stateless, and the disposables are the notifiers.
final watchDayTransactionsProvider = Provider<WatchDayTransactions>(
  (_) => getIt<WatchDayTransactions>(),
);

/// Bridge for [WatchMonthTransactions].
final watchMonthTransactionsProvider = Provider<WatchMonthTransactions>(
  (_) => getIt<WatchMonthTransactions>(),
);

/// Bridge for [WatchMonthDailyTotals].
final watchMonthDailyTotalsProvider = Provider<WatchMonthDailyTotals>(
  (_) => getIt<WatchMonthDailyTotals>(),
);

/// Bridge for [WatchMonthCategoryTotals].
final watchMonthCategoryTotalsProvider = Provider<WatchMonthCategoryTotals>(
  (_) => getIt<WatchMonthCategoryTotals>(),
);

/// Bridge for [WatchMonthTotal].
final watchMonthTotalProvider = Provider<WatchMonthTotal>(
  (_) => getIt<WatchMonthTotal>(),
);

/// Bridge for [WatchDayTotal].
final watchDayTotalProvider = Provider<WatchDayTotal>(
  (_) => getIt<WatchDayTotal>(),
);

/// Bridge for [GetTransaction].
final getTransactionProvider = Provider<GetTransaction>(
  (_) => getIt<GetTransaction>(),
);

/// Bridge for [SaveTransaction].
final saveTransactionProvider = Provider<SaveTransaction>(
  (_) => getIt<SaveTransaction>(),
);

/// Bridge for [DeleteTransaction].
final deleteTransactionProvider = Provider<DeleteTransaction>(
  (_) => getIt<DeleteTransaction>(),
);

/// Bridge for [RestoreTransaction].
final restoreTransactionProvider = Provider<RestoreTransaction>(
  (_) => getIt<RestoreTransaction>(),
);
