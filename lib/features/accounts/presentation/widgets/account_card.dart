import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/presentation/account_catalog.dart';
import 'package:material_ui/material_ui.dart';

/// Card displaying an account's name, type, icon, and current balance.
class AccountCard extends ConsumerWidget {
  const AccountCard({
    required this.account,
    this.onTap,
    this.onEdit,
    this.onTransfer,
    this.onArchiveToggle,
    this.onDelete,
    super.key,
  });

  final Account account;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onTransfer;
  final VoidCallback? onArchiveToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final iconData = AccountIcons.iconFor(account.iconKey);
    final accountColor = Color(account.colorValue);

    final typeLabel = switch (account.type.name) {
      'cash' => strings('accountTypeCash'),
      'bank' => strings('accountTypeBank'),
      'credit' => strings('accountTypeCredit'),
      'savings' => strings('accountTypeSavings'),
      'ewallet' => strings('accountTypeEwallet'),
      _ => account.type.name,
    };

    return Card(
      color: colors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderLg,
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap ?? onEdit,
        borderRadius: AppRadius.borderLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              // Icon with colored circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accountColor.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(iconData, color: accountColor, size: 22),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title and Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            account.name,
                            style: AppTypography.textTheme(colors).titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (account.isArchived) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceSubtle,
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: Text(
                              strings('accountsArchivedTab'),
                              // `caption` (11) is the §3 floor; this badge used
                              // to sit at 10. A dedicated `Badge` component
                              // (docs/Roadmap.md Phase 3.5 C) would own this.
                              style: AppTypography.caption.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        Text(
                          typeLabel,
                          style: AppTypography.label.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        if (!account.includeInTotal) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            AppIcons.conceal,
                            size: 13,
                            color: colors.textTertiary,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Current Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AmountText(
                    Money.minor(account.currentBalanceMinor, account.currency),
                    style: AmountStyle.row,
                    signed: account.currentBalanceMinor < 0,
                  ),
                ],
              ),

              // Overflow Menu
              PopupMenuButton<String>(
                icon: Icon(
                  AppIcons.more,
                  color: colors.textTertiary,
                  size: 20,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMd,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                    case 'transfer':
                      onTransfer?.call();
                    case 'archive':
                      onArchiveToggle?.call();
                    case 'delete':
                      onDelete?.call();
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  PopupMenuItem(
                    value: 'transfer',
                    child: Row(
                      children: <Widget>[
                        const Icon(AppIcons.transfer, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text(strings('accountsTransferButton')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: <Widget>[
                        const Icon(AppIcons.edit, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text(strings('accountsEditTitle')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: <Widget>[
                        Icon(
                          account.isArchived
                              ? AppIcons.unarchive
                              : AppIcons.archive,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          account.isArchived
                              ? strings('accountUnarchiveSuccess')
                              : strings('accountArchiveSuccess'),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: <Widget>[
                        Icon(
                          AppIcons.destructive,
                          size: 18,
                          color: colors.warning,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          strings('accountsDelete'),
                          style: AppTypography.body.copyWith(
                            color: colors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
