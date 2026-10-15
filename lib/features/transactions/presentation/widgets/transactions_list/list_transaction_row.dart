import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/app_overflow_menu.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:material_ui/material_ui.dart';

/// What the list row's overflow menu can do — the swipe-free alternative.
enum TransactionMenuAction { edit, delete }

/// A dismissible and actionable row for a single transaction.
///
/// Extracted from `transactions_list_page.dart` (`docs/Conventions.md` §1).
/// Named `ListTransactionRow` (not `TransactionRow`) so it never collides with
/// the calendar day-list row of the same role.
class ListTransactionRow extends ConsumerWidget {
  /// Creates a [ListTransactionRow].
  const ListTransactionRow({
    required this.transaction,
    required this.onDelete,
    super.key,
  });

  /// The transaction this row renders.
  final Transaction transaction;

  /// Called after a delete swipe completes.
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
        child: Icon(AppIcons.edit, color: colors.brandPrimary),
      ),
      secondaryBackground: Container(
        color: colors.moneyOutSubtle,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Icon(AppIcons.destructive, color: colors.moneyOut),
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
            AppOverflowMenu<TransactionMenuAction>(
              cancelLabel: strings('actionCancel'),
              onSelected: (action) => switch (action) {
                TransactionMenuAction.edit => _editTransaction(context),
                TransactionMenuAction.delete => onDelete(),
              },
              items: <OverflowMenuItem<TransactionMenuAction>>[
                OverflowMenuItem<TransactionMenuAction>(
                  value: TransactionMenuAction.edit,
                  label: strings('transactionEdit'),
                ),
                OverflowMenuItem<TransactionMenuAction>(
                  value: TransactionMenuAction.delete,
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

  void _editTransaction(BuildContext context) {
    unawaited(
      context.pushNamed(
        AppRoutes.transactionEditName,
        pathParameters: <String, String>{'id': transaction.id},
      ),
    );
  }
}
