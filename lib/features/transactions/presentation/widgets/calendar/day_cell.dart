import 'package:intl/intl.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:material_ui/material_ui.dart';

/// A day's capsule intensity and direction.
///
/// Five quantized steps (0–4) so the grid reads as texture, not noise
/// (`docs/Design.md` §6.2).
final class DayIntensity {
  /// Creates a [DayIntensity].
  const DayIntensity._(this.step, this.direction);

  /// 0 = no capsule, 1–4 = increasing fill.
  final int step;

  /// Which colour family to use.
  final TransactionDirection? direction;

  /// Quantizes `netMinor / p95` to 5 steps: 0, 0.25, 0.5, 0.75, 1.0 → 0–4.
  factory DayIntensity.fromNet(
    int netMinor,
    int p95,
    TransactionDirection? dominant,
  ) {
    final raw = netMinor.abs() / p95;
    final clamped = raw > 1.0 ? 1.0 : raw;
    final step = (clamped * 4).round();
    return DayIntensity._(step, dominant);
  }
}

/// One tappable day cell in the grid.
///
/// Extracted from `calendar_page.dart` (`docs/Conventions.md` §1).
class DayCell extends StatelessWidget {
  /// Creates a [DayCell].
  const DayCell({
    required this.day,
    required this.cellWidth,
    this.showMonthLabel = false,
    required this.isSelected,
    required this.isToday,
    required this.intensity,
    required this.onTap,
    super.key,
  });

  /// The calendar day this cell renders.
  final LocalDate day;

  /// The measured width of one grid cell, used to size the capsule at 60 %
  /// (`docs/Design.md` §6.2).
  final double cellWidth;

  /// Whether to show the tiny month label (pay-cycle mode, 1st of month).
  final bool showMonthLabel;

  /// Whether this day is the selected day.
  final bool isSelected;

  /// Whether this day is today.
  final bool isToday;

  /// The capsule intensity, or null when the day has no activity.
  final DayIntensity? intensity;

  /// Called when the cell is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context);

    String dateStr;
    try {
      dateStr = DateFormat.yMMMMd(locale.toLanguageTag())
          .format(day.toDateTime());
    } catch (_) {
      dateStr = '${day.year}-${day.month}-${day.day}';
    }
    final semanticLabel = isToday
        ? '$dateStr, ${strings('calendarToday')}'
        : dateStr;

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel,
      child: SizedBox(
        height: 48,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    // §6.2 selected: `brandSubtle` fill behind the whole cell at
                    // `radius.md`.
                    if (isSelected)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.brandSubtle,
                          borderRadius: AppRadius.borderMd,
                        ),
                      ),
                    // §6.2 today: a `brandPrimary` 1.5 px ring at `radius.full`,
                    // drawn *over* the selected fill so the two can coexist.
                    if (isToday)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.borderFull,
                          border: Border.all(
                            color: colors.brandPrimary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (showMonthLabel)
                            Text(
                              DateFormat.MMM(
                                Localizations.localeOf(context).toLanguageTag(),
                              ).format(day.toDateTime()),
                              // docs/Design.md §6.6: the tiny month label on the
                              // 1st of each calendar month is `overline`. It used
                              // to be an 8 px literal, which is below the
                              // `caption` floor §3 sets ("never go below caption
                              // (11)") — Burmese and Japanese lose legibility
                              // under it.
                              style: AppTypography.overline.copyWith(
                                color: isSelected
                                    ? colors.brandPrimary
                                    : colors.textSecondary,
                              ),
                            ),
                          SizedBox(
                            height: showMonthLabel ? 14 : 20,
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: AppTypography.body.copyWith(
                                  fontSize: showMonthLabel ? 12 : null,
                                  color: isSelected
                                      ? colors.brandPrimary
                                      : colors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          if (intensity case final i?)
                            _Capsule(intensity: i, cellWidth: cellWidth),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 4 px rounded bar under a day number.
///
/// Width is **60 % of the cell** (`docs/Design.md` §6.2), not a fixed 24 px, so
/// the capsule keeps its proportion when the grid stretches on tablet and
/// desktop. [cellWidth] is measured by the grid's `LayoutBuilder`.
class _Capsule extends StatelessWidget {
  const _Capsule({required this.intensity, required this.cellWidth});

  final DayIntensity intensity;
  final double cellWidth;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    // `transfer` shares the expense/neutral treatment rather than getting its own
    // colour: v0.1 cannot create one (`docs/Roadmap.md`), and inventing a colour
    // for an unreachable state would be untested design. The case is spelled out
    // anyway so the switch stays exhaustive when `transfer` ships in v0.3.
    final (subtle, full) = switch (intensity.direction) {
      TransactionDirection.income => (colors.moneyInSubtle, colors.moneyIn),
      TransactionDirection.expense ||
      TransactionDirection.transfer ||
      null => (colors.moneyOutSubtle, colors.moneyOut),
    };

    // §6.2 steps 1–4 read as increasing depth. `moneyOutSubtle` is already the
    // *lightest* of the five, so steps must interpolate from it toward the full
    // `moneyOut` — the previous `step * 64` alpha instead faded the subtle tint
    // out, making a busy day the palest capsule on the grid.
    final t = (intensity.step - 1) / 3;
    final color = Color.lerp(subtle, full, t)!;

    return Container(
      width: cellWidth * 0.6,
      height: 4,
      margin: const EdgeInsets.only(top: AppSpacing.xxs),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.borderSm),
    );
  }
}
