import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/features/accounts/presentation/account_catalog.dart';
import 'package:material_ui/material_ui.dart';

/// Live preview of the account being created/edited.
///
/// Extracted from `account_form_page.dart` (`docs/Conventions.md` §1).
/// §5.2: previews are `AppCard`s, not bespoke containers.
class AccountPreviewCard extends StatelessWidget {
  /// Creates an [AccountPreviewCard].
  const AccountPreviewCard({
    required this.name,
    required this.typeLabel,
    required this.openingBalanceMinor,
    required this.currency,
    required this.colorValue,
    required this.iconKey,
    super.key,
  });

  /// The account name (blank renders as an em dash).
  final String name;

  /// The localized account-type label.
  final String typeLabel;

  /// The opening balance in minor units (signed).
  final int openingBalanceMinor;

  /// The balance currency.
  final CurrencyCode currency;

  /// The ARGB32 accent color.
  final int colorValue;

  /// The catalog icon key.
  final String iconKey;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return AppCard(
      border: Border.all(color: colors.border),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(colorValue).withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                AccountIcons.iconFor(iconKey),
                color: Color(colorValue),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name.trim().isEmpty ? '—' : name.trim(),
                  style: AppTypography.textTheme(colors).titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  typeLabel,
                  style: AppTypography.label.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AmountText(
            Money.minor(openingBalanceMinor, currency),
            style: AmountStyle.large,
            signed: openingBalanceMinor < 0,
          ),
        ],
      ),
    );
  }
}
