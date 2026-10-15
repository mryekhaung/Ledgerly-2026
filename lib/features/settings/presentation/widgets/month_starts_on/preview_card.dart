import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:material_ui/material_ui.dart';

/// The live preview card displaying current/previous period ranges.
///
/// Extracted from `month_starts_on_page.dart` (`docs/Conventions.md` §1).
class PeriodPreviewCard extends StatelessWidget {
  /// Creates a [PeriodPreviewCard].
  const PeriodPreviewCard({
    required this.currentRange,
    required this.previousRange,
    super.key,
  });

  /// The pre-formatted current period range.
  final String currentRange;

  /// The pre-formatted previous period range.
  final String previousRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    final currentLabel = AppStrings.fill(
      context,
      'monthStartsOnCurrentPeriod',
      {'range': currentRange},
    );
    final previousLabel = AppStrings.fill(
      context,
      'monthStartsOnPreviousPeriod',
      {'range': previousRange},
    );

    // §5.2: preview cards are AppCards; the status border rides its slot.
    return AppCard(
      border: Border.all(color: colors.border),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(AppIcons.calendar, size: 20, color: colors.brandPrimary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  currentLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            // Aligns under the current-period text: 20 px icon + an `sm` gap.
            padding: const EdgeInsets.only(left: 20 + AppSpacing.sm),
            child: Text(
              previousLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings('monthStartsOnTransactionsNotice'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
