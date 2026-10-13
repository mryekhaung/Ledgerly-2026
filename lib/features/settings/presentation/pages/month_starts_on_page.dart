import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/period/period_calculator.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:material_ui/material_ui.dart';

/// The dedicated picker page for the budget-month start day (docs/Design.md §6.6).
///
/// Lets the user choose any day 1–28 on which their pay cycle / budgeting
/// period begins. Days 29–31 are excluded so February is never ambiguous
/// (docs/DataModel.md §8).
///
/// Features a live preview card underneath showing "Current period: …" and
/// "Previous: …", plus the reassurance that stored transactions remain untouched.
class MonthStartsOnPage extends ConsumerWidget {
  /// Creates the month start day picker page.
  const MonthStartsOnPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final settings = ref.watch(currentSettingsProvider);
    final selectedDay = settings.monthStartDay;

    final calculator = PeriodCalculator(selectedDay);
    final today = LocalDate.fromDateTime(DateTime.now());
    final currentPeriod = calculator.containing(today);
    final previousPeriod = calculator.previous(currentPeriod);
    final locale = Localizations.localeOf(context);

    final currentStr = _formatPeriod(currentPeriod, locale);
    final previousStr = _formatPeriod(previousPeriod, locale);

    return Scaffold(
      appBar: AppBar(title: Text(strings('monthStartsOnTitle'))),
      body: ConstrainedPane(
        maxWidth: AppSpacing.proseMaxWidth,
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal(
              MediaQuery.sizeOf(context).width,
            ),
            vertical: AppSpacing.lg,
          ),
          children: <Widget>[
            Text(
              strings('monthStartsOnDescription'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _DayGrid(
              selectedDay: selectedDay,
              onSelect: (day) => _save(
                context,
                ref,
                settings.copyWith(monthStartDay: day),
                strings,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _PreviewCard(currentRange: currentStr, previousRange: previousStr),
          ],
        ),
      ),
    );
  }

  static String _formatPeriod(BudgetPeriod period, Locale locale) {
    final startDt = period.start.toDateTime();
    final endDt = period.end.toDateTime();
    final localeStr = locale.toLanguageTag();
    if (period.start.year != period.end.year) {
      final startYear = DateFormat.yMMMd(localeStr).format(startDt);
      final endYear = DateFormat.yMMMd(localeStr).format(endDt);
      return '$startYear – $endYear';
    }
    final startFmt = DateFormat.MMMd(localeStr).format(startDt);
    final endFmt = DateFormat.MMMd(localeStr).format(endDt);
    return '$startFmt – $endFmt';
  }

  static Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    AppSettings next,
    String Function(String key) strings,
  ) async {
    final result = await ref.read(saveSettingsActionProvider)((
      settings: next,
      partial: false,
    ));

    if (!context.mounted) return;

    if (result.isSuccess) {
      AppFeedback.selection();
      AppFeedback.confirm(context, message: strings('settingsSaved'));
      return;
    }
    AppFeedback.destructive();
    AppFeedback.failure(context, message: strings('settingsSaveFailed'));
  }
}

/// The 7×4 grid of day chips (1–28).
class _DayGrid extends StatelessWidget {
  const _DayGrid({required this.selectedDay, required this.onSelect});

  final int selectedDay;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 7 columns to match standard calendar layout.
        const columns = 7;
        const totalSpacing = AppSpacing.sm * (columns - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / columns;
        // Keep minimum touch target 44×44 (docs/Design.md §5.7).
        final chipSize = itemWidth < 44 ? 44.0 : itemWidth;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (var day = 1; day <= 28; day++)
              _DayChip(
                day: day,
                isSelected: day == selectedDay,
                size: chipSize,
                colors: colors,
                theme: theme,
                onTap: () => onSelect(day),
              ),
          ],
        );
      },
    );
  }
}

/// One day button inside the grid.
class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.isSelected,
    required this.size,
    required this.colors,
    required this.theme,
    required this.onTap,
  });

  final int day;
  final bool isSelected;
  final double size;
  final AppColors colors;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$day',
      child: Material(
        color: isSelected ? colors.brandSubtle : colors.surfaceSubtle,
        borderRadius: AppRadius.borderMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: size,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderMd,
              border: Border.all(
                color: isSelected ? colors.brandPrimary : colors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              '$day',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? colors.brandPrimary : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The live preview card displaying current/previous period ranges.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.currentRange, required this.previousRange});

  final String currentRange;
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.calendar_today, size: 20, color: colors.brandPrimary),
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
            padding: const EdgeInsets.only(left: 28),
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
