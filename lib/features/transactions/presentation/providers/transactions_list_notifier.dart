import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_filter.dart';
import 'package:ledgerly/features/transactions/presentation/providers/transaction_providers.dart';

/// State for the paginated transactions list page.
class TransactionsListState {
  const TransactionsListState({
    this.items = const <Transaction>[],
    this.filter = const TransactionFilter.empty(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  /// The currently loaded transactions.
  final List<Transaction> items;

  /// The active search query and filter criteria.
  final TransactionFilter filter;

  /// True during the first fetch or when changing filters.
  final bool isLoading;

  /// True while fetching the next page of results.
  final bool isLoadingMore;

  /// Whether there are more pages available to fetch.
  final bool hasMore;

  /// Error message if the search failed.
  final String? error;

  TransactionsListState copyWith({
    List<Transaction>? items,
    TransactionFilter? filter,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return TransactionsListState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier managing search, filters, and infinite-scroll pagination.
class TransactionsListNotifier extends Notifier<TransactionsListState> {
  static const int pageSize = 20;

  @override
  TransactionsListState build() {
    scheduleMicrotask(loadInitial);
    return const TransactionsListState(isLoading: true);
  }

  /// Fetches the first page of results matching the current filter.
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final search = ref.read(searchTransactionsProvider);
    final result = await search((
      filter: state.filter,
      limit: pageSize,
      offset: 0,
    ));

    if (!ref.mounted) return;

    result.fold(
      onSuccess: (transactions) {
        state = state.copyWith(
          items: transactions,
          isLoading: false,
          hasMore: transactions.length >= pageSize,
          clearError: true,
        );
      },
      onErr: (failure) {
        state = state.copyWith(isLoading: false, error: failure.toString());
      },
    );
  }

  /// Fetches the next page of results and appends to the list.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final search = ref.read(searchTransactionsProvider);
    final result = await search((
      filter: state.filter,
      limit: pageSize,
      offset: state.items.length,
    ));

    if (!ref.mounted) return;

    result.fold(
      onSuccess: (newTransactions) {
        final updatedItems = <Transaction>[...state.items, ...newTransactions];
        state = state.copyWith(
          items: updatedItems,
          isLoadingMore: false,
          hasMore: newTransactions.length >= pageSize,
        );
      },
      onErr: (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.toString());
      },
    );
  }

  /// Updates the search query text and re-queries.
  void search(String query) {
    final trimmed = query.trim();
    if (state.filter.searchQuery == trimmed) return;
    final newFilter = state.filter.copyWith(
      searchQuery: trimmed,
      clearSearchQuery: trimmed.isEmpty,
    );
    applyFilter(newFilter);
  }

  /// Applies a new [TransactionFilter] and restarts pagination from offset 0.
  void applyFilter(TransactionFilter newFilter) {
    state = state.copyWith(filter: newFilter);
    unawaited(loadInitial());
  }

  /// Clears all active filters and search query.
  void clearFilter() {
    state = state.copyWith(filter: const TransactionFilter.empty());
    unawaited(loadInitial());
  }

  /// Removes an item immediately from local state upon deletion.
  void removeLocalItem(String id) {
    final updated = state.items.where((t) => t.id != id).toList();
    state = state.copyWith(items: updated);
  }

  /// Refreshes the transactions list.
  Future<void> refresh() => loadInitial();
}

/// Provider for [TransactionsListNotifier].
final transactionsListProvider =
    NotifierProvider.autoDispose<
      TransactionsListNotifier,
      TransactionsListState
    >(TransactionsListNotifier.new);
