import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
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
import 'package:material_ui/material_ui.dart';

enum _TransactionMenuAction { edit, delete }

/// Searchable and filterable transactions list with infinite scroll.
class TransactionsListPage extends ConsumerStatefulWidget {
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
      MaterialPageRoute<Category>(
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
              const Icon(Icons.tune),
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
      body: SafeArea(
        child: ConstrainedPane(
          maxWidth: AppSpacing.proseMaxWidth,
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
                    prefixIcon: const Icon(Icons.search, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
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
              _FilterChipsBar(
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
              icon: Icons.search_off,
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
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator.adaptive()),
            );
          }

          final transaction = state.items[index];
          return _TransactionRow(
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

/// Horizontal scrollable bar with active filter chips.
class _FilterChipsBar extends ConsumerWidget {
  const _FilterChipsBar({
    required this.filter,
    required this.onDirectionSelected,
    required this.onPickCategory,
    required this.onClearCategory,
    required this.onOpenFilterSheet,
    required this.onClearAll,
  });

  final TransactionFilter filter;
  final ValueChanged<TransactionDirection?> onDirectionSelected;
  final VoidCallback onPickCategory;
  final VoidCallback onClearCategory;
  final VoidCallback onOpenFilterSheet;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);

    Category? selectedCategory;
    if (filter.categoryId case final id?) {
      selectedCategory = ref.watch(categoryByIdProvider(id)).value;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: ResponsiveInsets.pageHorizontal(context)
          .copyWith(top: AppSpacing.xs, bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          // Direction Chips
          FilterChip(
            label: Text(strings('filterAll')),
            selected: filter.direction == null,
            onSelected: (_) => onDirectionSelected(null),
          ),
          const SizedBox(width: AppSpacing.xs),
          FilterChip(
            label: Text(strings('filterExpense')),
            selected: filter.direction == TransactionDirection.expense,
            onSelected: (selected) {
              onDirectionSelected(
                selected ? TransactionDirection.expense : null,
              );
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          FilterChip(
            label: Text(strings('filterIncome')),
            selected: filter.direction == TransactionDirection.income,
            onSelected: (selected) {
              onDirectionSelected(
                selected ? TransactionDirection.income : null,
              );
            },
          ),
          const SizedBox(width: AppSpacing.xs),

          // Category Chip
          if (selectedCategory case final cat?) ...<Widget>[
            InputChip(
              avatar: CategoryGem(
                colorValue: cat.colorValue,
                iconKey: cat.iconKey,
                size: CategoryGemSize.sm,
              ),
              label: Text(cat.name),
              selected: true,
              onDeleted: onClearCategory,
              onPressed: onPickCategory,
            ),
          ] else ...<Widget>[
            ActionChip(
              avatar: const Icon(Icons.category_outlined, size: 16),
              label: Text(strings('filterCategory')),
              onPressed: onPickCategory,
            ),
          ],
          const SizedBox(width: AppSpacing.xs),

          // Date Range Chip
          ActionChip(
            avatar: const Icon(Icons.calendar_today_outlined, size: 16),
            label: Text(
              filter.startDate != null || filter.endDate != null
                  ? '${filter.startDate?.toString() ?? '...'} ~ ${filter.endDate?.toString() ?? '...'}'
                  : strings('filterDateRange'),
            ),
            backgroundColor:
                (filter.startDate != null || filter.endDate != null)
                ? colors.brandSubtle
                : null,
            onPressed: onOpenFilterSheet,
          ),
          const SizedBox(width: AppSpacing.xs),

          // Amount Chip
          if (filter.minAmountMinor != null ||
              filter.maxAmountMinor != null) ...<Widget>[
            ActionChip(
              avatar: const Icon(Icons.attach_money, size: 16),
              label: Text(
                '${filter.minAmountMinor ?? 0} ~ ${filter.maxAmountMinor ?? '∞'}',
              ),
              backgroundColor: colors.brandSubtle,
              onPressed: onOpenFilterSheet,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],

          // Clear all button if any filter active
          if (filter.isActive) ...<Widget>[
            ActionChip(
              avatar: const Icon(Icons.close, size: 16),
              label: Text(strings('filterClearAll')),
              onPressed: onClearAll,
            ),
          ],
        ],
      ),
    );
  }
}

/// A dismissible and actionable row for a single transaction.
class _TransactionRow extends ConsumerWidget {
  const _TransactionRow({
    required this.transaction,
    required this.onDelete,
    super.key,
  });

  final Transaction transaction;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale);
    final category = ref
        .watch(categoryByIdProvider(transaction.categoryId))
        .value;

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _editTransaction(context);
          return false;
        }
        return true;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        color: colors.brandSubtle,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Icon(Icons.edit, color: colors.brandPrimary),
      ),
      secondaryBackground: Container(
        color: colors.moneyOutSubtle,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Icon(Icons.delete_outline, color: colors.moneyOut),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        onTap: () => _editTransaction(context),
        leading: category == null
            ? const SizedBox.square(dimension: 36)
            : CategoryGem(
                colorValue: category.colorValue,
                iconKey: category.iconKey,
                size: CategoryGemSize.md,
              ),
        title: Text(
          category?.name ?? transaction.categoryId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (transaction.note case final note?) ...<Widget>[
              Text(
                note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
            ],
            Text(
              dateFormat.format(transaction.date.toDateTime()),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.35,
              ),
              child: AmountText(
                transaction.amount,
                style: AmountStyle.row,
                signed: true,
                color: transaction.direction == TransactionDirection.income
                    ? colors.moneyIn
                    : colors.moneyOut,
              ),
            ),
            PopupMenuButton<_TransactionMenuAction>(
              icon: Icon(Icons.more_horiz, color: colors.textSecondary),
              onSelected: (action) => switch (action) {
                _TransactionMenuAction.edit => _editTransaction(context),
                _TransactionMenuAction.delete => onDelete(),
              },
              itemBuilder: (context) =>
                  <PopupMenuEntry<_TransactionMenuAction>>[
                    PopupMenuItem<_TransactionMenuAction>(
                      value: _TransactionMenuAction.edit,
                      child: Text(strings('transactionEdit')),
                    ),
                    PopupMenuItem<_TransactionMenuAction>(
                      value: _TransactionMenuAction.delete,
                      child: Text(strings('actionDelete')),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  void _editTransaction(BuildContext context) {
    unawaited(
      context.pushNamed(
        AppRoutes.transactionEditName,
        pathParameters: <String, String>{'id': transaction.id},
      ),
    );
  }
}
