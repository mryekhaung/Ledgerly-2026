import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/core/widgets/app_skeleton.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_filter.dart';
import 'package:ledgerly/features/transactions/presentation/pages/category_picker_page.dart';
import 'package:ledgerly/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:ledgerly/features/transactions/presentation/providers/transactions_list_notifier.dart';
import 'package:ledgerly/features/transactions/presentation/widgets/transaction_filter_sheet.dart';
import 'package:ledgerly/features/transactions/presentation/widgets/transactions_list/filter_chips_bar.dart';
import 'package:ledgerly/features/transactions/presentation/widgets/transactions_list/list_transaction_row.dart';
import 'package:material_ui/material_ui.dart';

/// Searchable and filterable transactions list with infinite scroll.
///
/// Composition root only: chips and rows live in `widgets/transactions_list/`
/// (`docs/Conventions.md` §1).
class TransactionsListPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const TransactionsListPage({super.key});

  @override
  ConsumerState<TransactionsListPage> createState() =>
      _TransactionsListPageState();
}

class _TransactionsListPageState extends ConsumerState<TransactionsListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      unawaited(ref.read(transactionsListProvider.notifier).loadMore());
    }
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(transactionsListProvider.notifier).search(text);
      }
    });
  }

  void _openFilterSheet(TransactionFilter filter) {
    unawaited(
      TransactionFilterSheet.show(
        context: context,
        initialFilter: filter,
        onApply: (newFilter) {
          ref.read(transactionsListProvider.notifier).applyFilter(newFilter);
        },
      ),
    );
  }

  Future<void> _pickCategory(TransactionFilter currentFilter) async {
    final kind = currentFilter.direction == TransactionDirection.income
        ? CategoryKind.income
        : CategoryKind.expense;

    final chosen = await Navigator.of(context).push<Category>(
      cupertino.CupertinoPageRoute<Category>(
        builder: (_) => CategoryPickerPage(
          kind: kind,
          selectedId: currentFilter.categoryId,
        ),
      ),
    );

    if (chosen != null && mounted) {
      ref
          .read(transactionsListProvider.notifier)
          .applyFilter(currentFilter.copyWith(categoryId: chosen.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);
    final state = ref.watch(transactionsListProvider);
    final notifier = ref.read(transactionsListProvider.notifier);

    return AppScaffold(
      title: strings('transactionsTitle'),
      actions: <Widget>[
        IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              const Icon(AppIcons.tune),
              if (state.filter.isActive)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.brandPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          tooltip: strings('filterTitle'),
          onPressed: () => _openFilterSheet(state.filter),
        ),
      ],
      useSafeArea: false,
      // Declared on the scaffold so the title lines up with the column it caps
      // (`AppScaffold.contentMaxWidth`).
      contentMaxWidth: AppSpacing.proseMaxWidth,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Search input
            Padding(
              padding: ResponsiveInsets.pageHorizontal(context)
                  .copyWith(top: AppSpacing.sm, bottom: AppSpacing.xs),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: strings('transactionsSearchHint'),
                  prefixIcon: const Icon(AppIcons.search, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(AppIcons.close, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            notifier.search('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colors.surfaceSubtle,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.borderMd,
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.borderMd,
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
              ),
            ),

            // Filter chips bar
            FilterChipsBar(
              filter: state.filter,
              onDirectionSelected: (direction) {
                notifier.applyFilter(
                  state.filter.copyWith(
                    direction: direction,
                    clearDirection: direction == null,
                  ),
                );
              },
              onPickCategory: () => _pickCategory(state.filter),
              onClearCategory: () {
                notifier.applyFilter(
                  state.filter.copyWith(clearCategoryId: true),
                );
              },
              onOpenFilterSheet: () => _openFilterSheet(state.filter),
              onClearAll: () {
                _searchController.clear();
                notifier.clearFilter();
              },
            ),

            const Divider(height: 1),

            // Transaction list body
            Expanded(child: _buildBody(context, state, notifier)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TransactionsListState state,
    TransactionsListNotifier notifier,
  ) {
    final strings = AppStrings.of(context);

    if (state.isLoading) {
      return const Center(child: LoadingPlaceholder());
    }

    if (state.items.isEmpty) {
      return RefreshIndicator.adaptive(
        onRefresh: notifier.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
            StatePlaceholder(
              icon: AppIcons.searchOff,
              title: strings('transactionsNoResultsTitle'),
              body: strings('transactionsNoResultsBody'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh: notifier.refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveInsets.pageHorizontal(context)
            .copyWith(top: AppSpacing.sm, bottom: AppSpacing.xl),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            // The next page is loading: keep the list's own rhythm rather than
            // dropping a spinner into the flow (docs/Design.md §5.11).
            return const AppSkeletonList(
              rows: 3,
              rowHeight: AppRowHeight.twoLine,
            );
          }

          final transaction = state.items[index];
          return ListTransactionRow(
            key: ValueKey(transaction.id),
            transaction: transaction,
            onDelete: () => _deleteTransaction(transaction),
          );
        },
      ),
    );
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final strings = AppStrings.of(context);
    final notifier = ref.read(transactionsListProvider.notifier);
    final restore = ref.read(restoreTransactionProvider);

    notifier.removeLocalItem(transaction.id);
    AppFeedback.destructive();

    final result = await ref.read(deleteTransactionProvider).call((
      id: transaction.id,
    ));

    if (!mounted) return;

    if (result.isErr) {
      AppFeedback.failure(context, message: strings('stateErrorBody'));
      unawaited(notifier.refresh());
      return;
    }

    AppFeedback.undoable(
      context,
      message: strings('transactionDeleted'),
      undoLabel: undoLabelFor(context),
      onUndo: () async {
        final restoreResult = await restore.call((id: transaction.id));
        if (restoreResult.isSuccess) {
          unawaited(notifier.refresh());
          AppFeedback.success();
        } else if (mounted) {
          AppFeedback.failure(context, message: strings('stateErrorBody'));
        }
      },
    );
  }
}
