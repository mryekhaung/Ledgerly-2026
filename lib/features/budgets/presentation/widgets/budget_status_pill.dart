import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
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
        Icons.check_circle_outline,
      ),
      BudgetStatus.warning => (
        const Color(0xFFD97706),
        const Color(0xFFD97706).withValues(alpha: 0.12),
        strings('budgetStatusWarning'),
        Icons.warning_amber_rounded,
      ),
      BudgetStatus.exceeded => (
        colors.moneyOut,
        colors.moneyOut.withValues(alpha: 0.12),
        strings('budgetStatusExceeded'),
        Icons.error_outline,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
