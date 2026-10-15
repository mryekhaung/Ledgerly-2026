import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/money/money_formatter.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/presentation/account_catalog.dart';
import 'package:material_ui/material_ui.dart';

/// From/to account selectors with a swap button.
///
/// Extracted from `transfer_page.dart` (`docs/Conventions.md` §1).
class TransferAccountsSection extends StatelessWidget {
  /// Creates a [TransferAccountsSection].
  const TransferAccountsSection({
    required this.accounts,
    required this.fromAccountId,
    required this.toAccountId,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onSwap,
    super.key,
  });

  /// All selectable accounts.
  final List<Account> accounts;

  /// The source account id.
  final String fromAccountId;

  /// The destination account id.
  final String toAccountId;

  /// Called with the new source id.
  final ValueChanged<String> onFromChanged;

  /// Called with the new destination id.
  final ValueChanged<String> onToChanged;

  /// Called to swap source and destination.
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return AppCard(
      border: Border.all(color: colors.border),
      child: Column(
        children: <Widget>[
          // From Account Dropdown
          Row(
            children: <Widget>[
              Icon(AppIcons.increase, size: 20, color: colors.moneyOut),
              const SizedBox(width: AppSpacing.sm),
              Text(
                strings('accountsTransferFrom'),
                style: AppTypography.label.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<String>(
            initialValue: fromAccountId.isEmpty ? null : fromAccountId,
            decoration: const InputDecoration(),
            items: accounts.map((a) {
              return DropdownMenuItem<String>(
                value: a.id,
                child: AccountDropdownRow(account: a),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) onFromChanged(val);
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Swap Button
          Center(
            child: IconButton.filledTonal(
              icon: const Icon(AppIcons.sort, size: 20),
              tooltip: strings('accountsTransferSwap'),
              onPressed: onSwap,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // To Account Dropdown
          Row(
            children: <Widget>[
              Icon(AppIcons.decrease, size: 20, color: colors.moneyIn),
              const SizedBox(width: AppSpacing.sm),
              Text(
                strings('accountsTransferTo'),
                style: AppTypography.label.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<String>(
            initialValue: toAccountId.isEmpty ? null : toAccountId,
            decoration: const InputDecoration(),
            items: accounts.map((a) {
              return DropdownMenuItem<String>(
                value: a.id,
                child: AccountDropdownRow(account: a),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) onToChanged(val);
            },
          ),
        ],
      ),
    );
  }
}

/// One account row inside the from/to dropdowns.
///
/// Balances render through [MoneyFormatter] (§5.4 — the only component allowed
/// to turn money into text, via `AmountText` elsewhere), never as raw minor
/// units.
class AccountDropdownRow extends StatelessWidget {
  /// Creates an [AccountDropdownRow].
  const AccountDropdownRow({required this.account, super.key});

  /// The account to render.
  final Account account;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final balance = MoneyFormatter(
      locale: Localizations.localeOf(context).toLanguageTag(),
    ).format(Money.minor(account.currentBalanceMinor, account.currency));

    return Row(
      children: <Widget>[
        Icon(
          AccountIcons.iconFor(account.iconKey),
          size: 18,
          color: Color(account.colorValue),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(account.name),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '($balance)',
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
      ],
    );
  }
}
