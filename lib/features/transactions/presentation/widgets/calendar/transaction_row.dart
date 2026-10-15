import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/app_overflow_menu.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:material_ui/material_ui.dart';

/// One transaction in the day list.
///
/// Direct manipulation: swipe **left** to delete (a 5-second undo snack bar
/// follows, because the delete is *soft* — the same tombstone a v0.4 sync will
/// propagate, so the undo is honest rather than decorative) and swipe **right**
/// to edit, on top of the existing tap-to-edit. A trailing overflow menu
/// mirrors both actions for keyboard and screen-reader users, who cannot
/// perform a swipe (`docs/Roadmap.md` Phase 1).
///
/// Extracted from `calendar_page.dart` (`docs/Conventions.md` §1).
class TransactionRow extends ConsumerWidget {
  /// Creates a [TransactionRow].
  const TransactionRow({
    required this.transaction,
    required this.onRemoved,
    required this.onRestored,
    super.key,
  });

  /// The transaction this row renders.
  final Transaction transaction;

  /// Adds `transaction.id` to the parent's locally-dismissed set when a delete
  /// swipe completes, so the row leaves the tree before the provider stream
  /// confirms the soft delete.
  final ValueChanged<String> onRemoved;

  /// Removes `transaction.id` from that set when an undo restores it, letting
  /// the row reappear from the provider data.
  final ValueChanged<String> onRestored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);
    final category = ref
        .watch(categoryByIdProvider(transaction.categoryId))
        .value;

    return Dismissible(
      key: ValueKey<String>(transaction.id),
      direction: DismissDirection.horizontal,
      // Swiping right (start → end) edits: navigate, then snap back so the row
      // never disappears for an action that keeps it.
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          unawaited(_editTransaction(context, transaction));
          return false;
        }
        return true;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onRemoved(transaction.id);
          unawaited(_deleteTransaction(context, ref, transaction));
        }
      },
      background: _SwipeAffordance(
        alignStart: true,
        icon: AppIcons.edit,
        label: strings('transactionEdit'),
        color: colors.brandSubtle,
        iconColor: colors.brandPrimary,
      ),
      secondaryBackground: _SwipeAffordance(
        alignStart: false,
        icon: AppIcons.destructive,
        label: strings('actionDelete'),
        color: colors.moneyOutSubtle,
        iconColor: colors.moneyOut,
      ),
      child: ListTile(
        onTap: () => unawaited(_editTransaction(context, transaction)),
        leading: category == null
            ? const SizedBox.square(dimension: 40)
            : CategoryGem(
                colorValue: category.colorValue,
                iconKey: category.iconKey,
                size: CategoryGemSize.md,
              ),
        title: Text(
          category?.name ?? transaction.categoryId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: transaction.note == null
            ? null
            : Text(
                transaction.note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // The amount is capped, not flexible. `ListTile` asserts when the
            // trailing "consumes the entire tile width", and a `Flexible` child
            // does exactly that — it expands to fill the slot, so at 360 px with
            // a 2.0 text scale the tile threw. A `ConstrainedBox` instead lets
            // the amount take its natural width when there is room and shrink to
            // the cap (where the built-in `ellipsis` takes over) when there is
            // not. The cap is a share of the window so it tracks the size class
            // rather than assuming a phone width.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.4,
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
            const SizedBox(width: AppSpacing.xs),
            AppOverflowMenu<TransactionAction>(
              cancelLabel: strings('actionCancel'),
              onSelected: (action) => switch (action) {
                TransactionAction.edit => unawaited(
                  _editTransaction(context, transaction),
                ),
                TransactionAction.delete => unawaited(
                  _deleteTransaction(context, ref, transaction),
                ),
              },
              items: <OverflowMenuItem<TransactionAction>>[
                OverflowMenuItem<TransactionAction>(
                  value: TransactionAction.edit,
                  label: strings('transactionEdit'),
                ),
                OverflowMenuItem<TransactionAction>(
                  value: TransactionAction.delete,
                  label: strings('actionDelete'),
                  destructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTransaction(BuildContext context, Transaction transaction) {
    return context.pushNamed(
      AppRoutes.transactionEditName,
      pathParameters: <String, String>{'id': transaction.id},
    );
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    final strings = AppStrings.of(context);
    // A destructive action buzzes before the snack bar is read, so deleting
    // feels different from tapping a row.
    AppFeedback.destructive();
    final result = await ref.read(deleteTransactionProvider).call((
      id: transaction.id,
    ));
    if (!context.mounted) return;

    if (result.isErr) {
      AppFeedback.failure(context, message: strings('stateErrorBody'));
      // A failed delete must not leave the row hidden.
      onRestored(transaction.id);
      return;
    }

    AppFeedback.undoable(
      context,
      message: strings('transactionDeleted'),
      undoLabel: undoLabelFor(context),
      onUndo: () => _restoreTransaction(context, ref, transaction),
    );
  }

  Future<void> _restoreTransaction(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    final result = await ref.read(restoreTransactionProvider).call((
      id: transaction.id,
    ));
    if (!context.mounted) return;

    if (result.isSuccess) {
      onRestored(transaction.id);
      AppFeedback.success();
    } else {
      AppFeedback.failure(
        context,
        message: AppStrings.of(context)('stateErrorBody'),
      );
    }
  }
}

/// The colored panel revealed behind a transaction row as it is swiped.
///
/// One instance per swipe direction: the edit affordance on the start side, the
/// delete affordance on the end side. Kept tiny and declarative so both
/// backgrounds share one painter.
class _SwipeAffordance extends StatelessWidget {
  const _SwipeAffordance({
    required this.alignStart,
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
  });

  final bool alignStart;
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
    alignment: alignStart
        ? AlignmentDirectional.centerStart
        : AlignmentDirectional.centerEnd,
    color: color,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignStart
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: <Widget>[
        Icon(icon, color: iconColor),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: iconColor),
        ),
      ],
    ),
  );
}

/// What the row's overflow menu can do — the swipe-free alternative.
enum TransactionAction { edit, delete }
