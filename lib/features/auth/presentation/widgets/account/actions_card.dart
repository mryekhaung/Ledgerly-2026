import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/core/widgets/list_row.dart';
import 'package:material_ui/material_ui.dart';

/// Sign-out and delete-account actions.
///
/// Extracted from `account_page.dart` (`docs/Conventions.md` §1).
class AccountActionsCard extends StatelessWidget {
  /// Creates an [AccountActionsCard].
  const AccountActionsCard({
    required this.isLoading,
    required this.onSignOut,
    required this.onDeleteAccount,
    super.key,
  });

  /// Whether an auth request is in flight.
  final bool isLoading;

  /// Called to sign out.
  final VoidCallback onSignOut;

  /// Called to delete the account.
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.borderMd,
      border: Border.all(color: colors.border),
      child: Column(
        children: <Widget>[
          ListRow(
            leading: Icon(AppIcons.signOut, color: colors.textPrimary),
            title: Text(
              strings('accountSignOut'),
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
            trailing: const Icon(AppIcons.chevronRight),
            onTap: isLoading ? null : onSignOut,
            semanticsLabel: strings('accountSignOut'),
          ),
          Divider(height: 1, color: colors.border),
          ListRow(
            leading: Icon(AppIcons.destructive, color: colors.moneyOut),
            title: Text(
              strings('accountDeleteTitle'),
              style: AppTypography.body.copyWith(
                color: colors.moneyOut,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(AppIcons.chevronRight, color: colors.moneyOut),
            onTap: isLoading ? null : onDeleteAccount,
            semanticsLabel: strings('accountDeleteTitle'),
          ),
        ],
      ),
    );
  }
}
