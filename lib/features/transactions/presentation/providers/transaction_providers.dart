import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/di/injection.dart';
import 'package:ledgerly/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:ledgerly/features/transactions/domain/usecases/save_transaction.dart';
import 'package:ledgerly/features/transactions/domain/usecases/search_transactions.dart';
import 'package:ledgerly/features/transactions/domain/usecases/watch_transactions.dart';

/// Thin bridge between get_it and Riverpod for the transaction use cases.
///
/// See the categories bridge for why these are plain, non-disposed providers:
/// the use cases are stateless, and the disposables are the notifiers.
final watchDayTransactionsProvider = Provider<WatchDayTransactions>(
  (_) => getIt<WatchDayTransactions>(),
);

/// Bridge for [WatchPeriodTransactions].
final watchPeriodTransactionsProvider = Provider<WatchPeriodTransactions>(
  (_) => getIt<WatchPeriodTransactions>(),
);

/// Bridge for [WatchPeriodDailyTotals].
final watchPeriodDailyTotalsProvider = Provider<WatchPeriodDailyTotals>(
  (_) => getIt<WatchPeriodDailyTotals>(),
);

/// Bridge for [WatchPeriodCategoryTotals].
final watchPeriodCategoryTotalsProvider = Provider<WatchPeriodCategoryTotals>(
  (_) => getIt<WatchPeriodCategoryTotals>(),
);

/// Bridge for [WatchPeriodTotal].
final watchPeriodTotalProvider = Provider<WatchPeriodTotal>(
  (_) => getIt<WatchPeriodTotal>(),
);

/// Backward-compatible alias for [watchPeriodTransactionsProvider].
final watchMonthTransactionsProvider = watchPeriodTransactionsProvider;

/// Backward-compatible alias for [watchPeriodDailyTotalsProvider].
final watchMonthDailyTotalsProvider = watchPeriodDailyTotalsProvider;

/// Backward-compatible alias for [watchPeriodCategoryTotalsProvider].
final watchMonthCategoryTotalsProvider = watchPeriodCategoryTotalsProvider;

/// Backward-compatible alias for [watchPeriodTotalProvider].
final watchMonthTotalProvider = watchPeriodTotalProvider;

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

/// Bridge for [SearchTransactions].
final searchTransactionsProvider = Provider<SearchTransactions>(
  (_) => getIt<SearchTransactions>(),
);
