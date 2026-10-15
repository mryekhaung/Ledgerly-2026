import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_status.dart';
import 'package:material_ui/material_ui.dart';

class BudgetStatusPill extends StatelessWidget {
  const BudgetStatusPill({required this.status, super.key});

  final BudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    final (color, bg, label, icon) = switch (status) {
      BudgetStatus.safe => (
        colors.moneyIn,
        colors.moneyIn.withValues(alpha: 0.12),
        strings('budgetStatusSafe'),
        AppIcons.success,
      ),
      BudgetStatus.warning => (
        colors.warning,
        colors.warningSubtle,
        strings('budgetStatusWarning'),
        AppIcons.warning,
      ),
      BudgetStatus.exceeded => (
        colors.moneyOut,
        colors.moneyOut.withValues(alpha: 0.12),
        strings('budgetStatusExceeded'),
        AppIcons.error,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.borderMd),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.overline.copyWith(color: color)),
        ],
      ),
    );
  }
}
