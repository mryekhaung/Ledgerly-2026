import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveSlider;
import 'package:flutter/material.dart'
    as flutter_material
    show Material, MaterialType;
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:material_ui/material_ui.dart';

/// Alert-threshold slider with live hint.
///
/// Extracted from `budget_form_page.dart` (`docs/Conventions.md` §1).
class BudgetThresholdSection extends StatelessWidget {
  /// Creates a [BudgetThresholdSection].
  const BudgetThresholdSection({
    required this.threshold,
    required this.onChanged,
    super.key,
  });

  /// The alert threshold 0.5–1.0.
  final double threshold;

  /// Called with the new threshold.
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              strings('budgetFieldThreshold'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: colors.warningSubtle,
                borderRadius: AppRadius.borderSm,
              ),
              child: Text(
                '${(threshold * 100).round()}%',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.warning,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        flutter_material.Material(
          type: flutter_material.MaterialType.transparency,
          child: AdaptiveSlider(
            value: threshold,
            min: 0.5,
            max: 1.0,
            divisions: 10,
            activeColor: colors.warning,
            onChanged: onChanged,
          ),
        ),
        Text(
          AppStrings.fill(context, 'budgetThresholdHint', <String, Object>{
            'percent': (threshold * 100).round(),
          }),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
