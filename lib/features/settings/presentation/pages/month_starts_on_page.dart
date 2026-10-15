import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/period/period_calculator.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/settings/presentation/widgets/month_starts_on/day_grid.dart';
import 'package:ledgerly/features/settings/presentation/widgets/month_starts_on/preview_card.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// The dedicated picker page for the budget-month start day (docs/Design.md §6.6).
///
/// Lets the user choose any day 1–28 on which their pay cycle / budgeting
/// period begins. Days 29–31 are excluded so February is never ambiguous
/// (docs/DataModel.md §8).
///
/// Features a live preview card underneath showing "Current period: …" and
/// "Previous: …", plus the reassurance that stored transactions remain untouched.
///
/// Composition root only: grid and preview live in `widgets/month_starts_on/`
/// (`docs/Conventions.md` §1).
class MonthStartsOnPage extends ConsumerWidget {
  /// Creates the month start day picker page.
  const MonthStartsOnPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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

    return AppScaffold(
      title: strings('monthStartsOnTitle'),
      // Declared on the scaffold so the title lines up with the column it caps
      // (`AppScaffold.contentMaxWidth`).
      contentMaxWidth: AppSpacing.proseMaxWidth,
      body: ListView(
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
              color: AppThemeColors.of(context).textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          DayGrid(
            selectedDay: selectedDay,
            onSelect: (day) => _save(
              context,
              ref,
              settings.copyWith(monthStartDay: day),
              strings,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PeriodPreviewCard(
            currentRange: currentStr,
            previousRange: previousStr,
          ),
        ],
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
