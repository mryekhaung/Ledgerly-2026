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

  /// 0–4, where 0 is the *palest* capsule rather than none at all.
  ///
  /// `_Capsule` draws for any non-null intensity and the ramp extrapolates below
  /// its start, so step 0 is a faint bar; a day with **no** activity has a null
  /// [DayIntensity] instead and draws nothing. The doc comment this replaces
  /// ("0 = no capsule") described the intent the ramp was built to avoid.
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

  /// The measured width of one grid cell, used to size the capsule
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
        height: AppRowHeight.calendarCell,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Center(
              child: SizedBox(
                // §6.2: the selected indicator is **36 x 36** — Material 3's own
                // measurement for a selected date, down from the 40 this used
                // before. A 40 px disc inside a 44 px cell left 2 px of air and
                // read heavy; 36 leaves the circle breathing inside the hit
                // target, which stays the full 44 px cell (§M.2).
                width: _selectedIndicatorSize,
                height: _selectedIndicatorSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    // §6.2 selected: a **solid** `selectedFill` circle behind the
                    // whole cell, with the day number in `onSelectedFill` — the
                    // Google Calendar / Apple Calendar convention.
                    //
                    // This used to be a `brandSubtle` wash at `radius.md`, which
                    // measured 1.20:1 on white and 1.29:1 on dark — a selected
                    // state that could not be seen in *either* mode, and a
                    // near-black square in dark (docs/Roadmap.md §K.1-2). A tint
                    // is not a state; `selectedFill` is (docs/Design.md §2.6).
                    if (isSelected)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.selectedFill,
                          borderRadius: AppRadius.borderFull,
                        ),
                      ),
                    // §6.2 today: a **1 dp** ring at `radius.full`, drawn *over*
                    // the selected fill so the two can coexist. Material 3
                    // specifies today as a 1 dp outline with no fill, precisely
                    // so it stays distinct from the filled selected state; this
                    // was 1.5 px, which read as a second selection (§M.3).
                    //
                    // On a selected cell the ring switches to `onSelectedFill`,
                    // because a `brandPrimary` ring on a `brandPrimary` fill
                    // would vanish.
                    if (isToday)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.borderFull,
                          border: Border.all(
                            color: isSelected
                                ? colors.onSelectedFill
                                : colors.brandPrimary,
                            width: 1,
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
                                    ? colors.onSelectedFill
                                    : colors.textSecondary,
                              ),
                            ),
                          SizedBox(
                            height: showMonthLabel ? 14 : 20,
                            child: Center(
                              child: Text(
                                '${day.day}',
                                // Tabular figures, per docs/Design.md §3. The
                                // rule is written for amounts, but the reason is
                                // the same and the calendar is the clearest case
                                // of it: 1 through 31 are a column of digits, and
                                // Inter's proportional figures make `1` visibly
                                // narrower than `8`, so the numbers did not line
                                // up down the grid (§M.7).
                                style: AppTypography.body.copyWith(
                                  fontFeatures: const <FontFeature>[
                                    FontFeature.tabularFigures(),
                                  ],
                                  fontSize: showMonthLabel ? 12 : null,
                                  color: isSelected
                                      ? colors.onSelectedFill
                                      : colors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          if (intensity case final i?)
                            _Capsule(
                              intensity: i,
                              cellWidth: cellWidth,
                              isSelected: isSelected,
                            ),
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

/// The selected-date indicator diameter (docs/Design.md §6.2).
///
/// Material 3 measures a selected date at 36 x 36 dp in the mobile calendar
/// picker. Named so the spec, the widget and the test agree on one number.
const double _selectedIndicatorSize = 36;

/// The capsule bar under a day number — this app's signature grid mark.
///
/// Width is **36 % of the cell** (`docs/Design.md` §6.2), not a fixed pixel
/// count, so the capsule keeps its proportion when the grid stretches on tablet
/// and desktop. [cellWidth] is measured by the grid's `LayoutBuilder`.
///
/// It was 60 %, which the owner read as a divider rather than a data mark —
/// "divider width ကို နဲနဲလျှော့လိုက်ရင် ပိုလှသာမယ်ထင်တယ်" (§M.4). A narrower
/// bar is also the more honest encoding: the capsule's job is to say *this day
/// had activity and roughly how much*, and at 60 % of the cell it competed with
/// the day number for attention instead of annotating it.
class _Capsule extends StatelessWidget {
  const _Capsule({
    required this.intensity,
    required this.cellWidth,
    required this.isSelected,
  });

  final DayIntensity intensity;
  final double cellWidth;

  /// Whether the parent cell is selected, which recolours the capsule.
  final bool isSelected;

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

    // §6.2 steps read as increasing depth. `moneyOutSubtle` is already the
    // *lightest* of the five, so steps must interpolate from it toward the full
    // `moneyOut` — the previous `step * 64` alpha instead faded the subtle tint
    // out, making a busy day the palest capsule on the grid.
    //
    // The ramp starts at **66 %** of the way to the full colour rather than at
    // the subtle tint itself. `*Subtle` measures 1.10–1.25:1 on its surface, so a
    // step-1 day drew a bar that was simply not there — the "black bar" in the
    // owner's dark-mode screenshot (docs/Roadmap.md §K.1-3). From 66 % the four
    // steps land at 2.93/3.48/4.10/4.75 (light expense) through 2.88/3.54/4.39/
    // 5.47 (light income) and 3.30/3.97/4.68/5.53 (dark expense) through
    // 3.91/4.71/5.57/6.59 (dark income), i.e. every step is visible and every
    // step differs. The start was **raised from 60 %** in §L: lowering the page
    // to #F5F7FA brought the light tints closer to it, so step 1 fell to 2.48:1
    // and dropped back under the visibility floor the §K tests set.
    // Asserted in `test/app/theme/design_tokens_test.dart`
    // (`every_capsule_step_is_visible_and_ordered`) and, on the rendered widget,
    // in `calendar_page_test.dart`'s Day Capsule group.
    //
    // Step 0 sits *below* that start, because it is a fifth of the ramp rather
    // than a fourth: t = 0.66 - 0.34/3 = 0.547. §M.10 clamped it at
    // [capsuleRampFloor]. Extrapolating that far landed the palest bar at
    // 2.46:1 (light expense) and 2.38:1 (light income) — under the same 2.5:1
    // floor the §K tests set for every other step, and the audit script flagged
    // both. A capsule that cannot be seen does not say "there was activity
    // here", which is the one thing step 0 exists to say.
    final raw =
        capsuleRampStart + (1 - capsuleRampStart) * (intensity.step - 1) / 3;
    final t = raw < capsuleRampFloor ? capsuleRampFloor : raw;
    final color = Color.lerp(subtle, full, t)!;

    // On a selected cell the capsule switches to `onSelectedFill`.
    //
    // It used to stay `moneyOut`, so a selected day drew a saturated red bar
    // across a saturated teal disc — two focal colours inside one 36 px circle,
    // which is exactly the clash visible on day 16 of the owner's light-mode
    // screenshot (§M.5). The selected day is the single focal state on the
    // screen (§1.2); everything inside it should read as one object. The capsule
    // keeps its *length* — so the day's magnitude is still legible — and gives
    // up only its hue.
    final capsuleColor = isSelected ? colors.onSelectedFill : color;

    return Container(
      width: cellWidth * capsuleWidthFraction,
      height: capsuleHeight,
      margin: const EdgeInsets.only(top: AppSpacing.xxs),
      // `borderFull`, not `borderSm`: a fully rounded 3 px dash reads as a
      // deliberate mark, where an 8 px radius on a 3 px bar is geometrically a
      // rectangle with clipped corners. Material 3 Expressive treats shape as
      // expressive rather than decorative — the capsule is the one place in the
      // grid where that is worth spending (§M.6).
      decoration: BoxDecoration(
        color: capsuleColor,
        borderRadius: AppRadius.borderFull,
      ),
    );
  }
}

/// Capsule width as a fraction of the cell (docs/Design.md §6.2).
///
/// Exported so `test/features/transactions/presentation/calendar_page_test.dart`
/// and the widget name the same number — the same contract
/// `_capsuleRampStart` has in `design_tokens_test.dart`.
const double capsuleWidthFraction = 0.36;

/// Where the capsule ramp starts, as a fraction of the way from `*Subtle` to the
/// full money colour.
///
/// Exported so `design_tokens_test.dart` mirrors the real number instead of a
/// copy of it: the mirror has already been wrong once (§L, where the doc and the
/// code disagreed about the start by 6 points).
const double capsuleRampStart = 0.66;

/// The ramp's lower bound, reached by step 0.
///
/// Step 0 is a *fifth* of the ramp, not a fourth, so the natural extrapolation
/// puts it below [capsuleRampStart] — at 0.547, which measured 2.46:1 (light
/// expense) and 2.38:1 (light income) against the page: under the 2.5:1
/// visibility floor every other step clears (§M.10). Clamped here so the palest
/// capsule still says "there was activity here".
const double capsuleRampFloor = 0.60;

/// Capsule height in logical pixels (docs/Design.md §6.2).
///
/// Down from 4 px alongside the width. A 3 px pill paired with a 36 % width
/// reads as a deliberate dash; a 4 px bar at 60 % read as a divider, which is
/// how the owner described it. Exported for the same reason as
/// [capsuleWidthFraction].
const double capsuleHeight = 3;
