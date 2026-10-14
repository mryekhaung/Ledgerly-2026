import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/features/accounts/presentation/providers/account_providers.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:material_ui/material_ui.dart';

/// Hero summary card displaying the user's total net worth across active accounts.
class NetWorthCard extends ConsumerWidget {
  const NetWorthCard({
    required this.onTransfer,
    required this.onAddAccount,
    super.key,
  });

  final VoidCallback onTransfer;
  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final netWorth = ref.watch(totalNetWorthProvider);
    final currency = ref.watch(currencyProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.account_balance,
                    size: 18,
                    color: colors.brandPrimary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    strings('accountsNetWorth'),
                    style: AppTypography.textTheme(colors).labelLarge?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.brandSubtle,
                  borderRadius: AppRadius.borderSm,
                ),
                child: Text(
                  currency.name.toUpperCase(),
                  style: AppTypography.overline.copyWith(
                    color: colors.brandPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AmountText(
            Money.minor(netWorth, currency),
            style: AmountStyle.display,
            signed: netWorth < 0,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTransfer,
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: Text(strings('accountsTransferButton')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.border),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.borderMd,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddAccount,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(strings('accountsAddButton')),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brandPrimary,
                    foregroundColor: colors.textOnBrand,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.borderMd,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
