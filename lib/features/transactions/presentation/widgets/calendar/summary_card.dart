import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_totals.dart';
import 'package:ledgerly/features/transactions/presentation/providers/calendar_notifier.dart';
import 'package:material_ui/material_ui.dart';

/// The selected-day summary card directly under the grid.
///
/// Design.md §6.3: this card IS an `AppCard`. It is scoped to the *selected
/// day*: `selectedDayTotalProvider` is a day-level SQL aggregate, so switching
/// days repaints this without touching the month figures the grid uses.
///
/// Extracted from `calendar_page.dart` (`docs/Conventions.md` §1).
class CalendarSummaryCard extends ConsumerWidget {
  /// Creates a [CalendarSummaryCard].
  const CalendarSummaryCard({required this.day, super.key});

  /// The day whose totals are shown.
  final LocalDate day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);
    final currency = ref.watch(currencyProvider);
    final totalAsync = ref.watch(selectedDayTotalProvider);
    final total = totalAsync.value ?? DailyTotal.empty(day, currency);

    // §6.3: the hero is the day's **spend** — the expense magnitude, unsigned, in
    // `moneyOut` — so the figure can never contradict the "Spent today" label.
    //
    // It used to be the signed *net* (`incomeMinor - expenseMinor`), which meant
    // an income-only day rendered a green `+¥200,000` directly under the words
    // "Spent today": a salary reported as spending (docs/Roadmap.md §K.1-1). The
    // footer below already reports Income and Expense separately and correctly.
    final spentMoney = Money.minor(total.expenseMinor, currency);

    // Design.md §6.3: the summary card directly under the grid IS an AppCard.
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            strings('calendarSpentToday'),
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          AmountText(
            spentMoney,
            style: AmountStyle.large,
            signed: false,
            color: colors.moneyOut,
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryColumn(
                  label: strings('calendarIncome'),
                  amount: Money.minor(total.incomeMinor, currency),
                  color: colors.moneyIn,
                ),
              ),
              Expanded(
                child: _SummaryColumn(
                  label: strings('calendarExpense'),
                  amount: Money.minor(total.expenseMinor, currency),
                  color: colors.moneyOut,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One side of the summary card footer.
class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final Money amount;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: AppThemeColors.of(context).textSecondary),
      ),
      const SizedBox(height: AppSpacing.xs),
      AmountText(amount, style: AmountStyle.row, signed: false, color: color),
    ],
  );
}
