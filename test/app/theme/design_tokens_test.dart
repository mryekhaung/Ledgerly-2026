import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:material_ui/material_ui.dart';

/// WCAG 2.1 relative luminance — `Color.r/.g/.b` are 0..1 channels.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// Contrast ratio `(L1 + 0.05) / (L2 + 0.05)`.
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Where the day-cell capsule ramp starts, mirrored from
/// `lib/features/transactions/presentation/widgets/calendar/day_cell.dart`.
///
/// Kept here so the assertion and the implementation name the same number; if
/// the widget's ramp moves, this must move with it. Raised from 0.60 in §L,
/// when the light page became #F5F7FA and step 1 lost separation from it.
const double _capsuleRampStart = 0.66;

/// Token-level assertions.
///
/// The design system is the contract every screen is built on, so its invariants
/// are tested rather than reviewed: contrast ratios, the money color rule, and
/// the tabular-figures requirement are the ones that silently rot otherwise.
void main() {
  group('color contrast (docs/Design.md §2)', () {
    /// Delegates to the top-level helper so every assertion below — including
    /// the §K coverage group at the end of this file — shares one formula.
    double contrastRatio(Color a, Color b) => _contrast(a, b);

    test('should_meet_aa_for_primary_text_on_surface_in_light', () {
      const colors = AppColorsLight();

      expect(
        contrastRatio(colors.textPrimary, colors.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('should_meet_aa_for_primary_text_on_surface_in_dark', () {
      const colors = AppColorsDark();

      expect(
        contrastRatio(colors.textPrimary, colors.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('should_meet_aa_for_money_out_on_surface_in_light', () {
      const colors = AppColorsLight();

      expect(
        contrastRatio(colors.moneyOut, colors.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('should_meet_aa_for_money_out_on_surface_in_dark', () {
      // Dark mode lightens moneyOut precisely so this holds (docs/Design.md §2.3).
      const colors = AppColorsDark();

      expect(
        contrastRatio(colors.moneyOut, colors.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('should_meet_aa_for_money_in_on_surface_in_light', () {
      const colors = AppColorsLight();

      expect(
        contrastRatio(colors.moneyIn, colors.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('should_meet_aa_for_brand_primary_on_surface_in_dark', () {
      const colors = AppColorsDark();

      expect(
        contrastRatio(colors.brandPrimary, colors.surface),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('money color rule (docs/Design.md §2.4)', () {
    test('should_lighten_brand_primary_when_dark', () {
      // jade600 fails 4.5:1 on the dark surface, so dark mode must use a
      // different value - a regression here is a real accessibility bug.
      const light = AppColorsLight();
      const dark = AppColorsDark();

      expect(dark.brandPrimary, isNot(light.brandPrimary));
      expect(dark.isDark, isTrue);
      expect(light.isDark, isFalse);
    });

    test('should_keep_expense_and_income_distinct_when_dark', () {
      const dark = AppColorsDark();

      expect(dark.moneyOut, isNot(dark.moneyIn));
      expect(dark.moneyOutSubtle, isNot(dark.moneyInSubtle));
    });

    test('should_keep_expense_and_income_distinct_when_light', () {
      const light = AppColorsLight();

      expect(light.moneyOut, isNot(light.moneyIn));
      expect(light.moneyOutSubtle, isNot(light.moneyInSubtle));
    });

    test('should_use_an_amber_warning_that_is_neither_money_color', () {
      const light = AppColorsLight();

      // Errors must never be signalled with money colors (docs/Design.md §2.4).
      expect(light.warning, isNot(light.moneyOut));
      expect(light.warning, isNot(light.moneyIn));
    });
  });

  group('spacing scale (docs/Design.md §4.1)', () {
    test('should_be_multiples_of_the_four_px_base_unit', () {
      // xxs is the docs' explicit exception at 2 px for hairline nudges.
      const multiples = <double>[
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ];

      for (final value in multiples) {
        expect(value % 4, 0, reason: '$value is not a multiple of 4');
      }
      expect(AppSpacing.xxs, 2);
    });

    test('should_ascend_strictly', () {
      const scale = <double>[
        AppSpacing.xxs,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ];

      for (var i = 1; i < scale.length; i++) {
        expect(scale[i], greaterThan(scale[i - 1]));
      }
    });

    test('should_use_16_when_width_is_compact', () {
      expect(AppSpacing.pageHorizontal(360), AppSpacing.lg);
      expect(AppSpacing.pageHorizontal(599), AppSpacing.lg);
    });

    test('should_use_24_when_width_is_at_least_medium', () {
      expect(AppSpacing.pageHorizontal(600), AppSpacing.xl);
      expect(AppSpacing.pageHorizontal(1440), AppSpacing.xl);
    });
  });

  group('radius scale (docs/Design.md §4.2)', () {
    test('should_ascend_and_end_fully_rounded', () {
      expect(AppRadius.sm, 8);
      expect(AppRadius.lg, greaterThan(AppRadius.md));
      expect(AppRadius.xl, greaterThan(AppRadius.lg));
      expect(AppRadius.full, greaterThan(AppRadius.xl));
    });
  });

  group('typography (docs/Design.md §3)', () {
    test('should_apply_tabular_figures_to_every_amount_style', () {
      // Digit jitter during animation is the bug this prevents.
      for (final entry in AppTypography.amountStyles.entries) {
        expect(
          entry.value.fontFeatures,
          contains(const FontFeature.tabularFigures()),
          reason: '${entry.key} is missing tabular figures',
        );
      }
    });

    test('should_order_amount_styles_by_descending_size', () {
      expect(
        AppTypography.displayAmount.fontSize,
        greaterThan(AppTypography.amountLarge.fontSize!),
      );
      expect(
        AppTypography.amountLarge.fontSize,
        greaterThan(AppTypography.amount.fontSize!),
      );
    });

    test('should_never_go_below_eleven_px', () {
      // Not const: reading an instance member off a const TextStyle is not
      // allowed in a constant expression.
      final sizes = <double?>[
        AppTypography.displayAmount.fontSize,
        AppTypography.amountLarge.fontSize,
        AppTypography.amount.fontSize,
        AppTypography.titleLarge.fontSize,
        AppTypography.title.fontSize,
        AppTypography.body.fontSize,
        AppTypography.label.fontSize,
        AppTypography.caption.fontSize,
        AppTypography.overline.fontSize,
      ];

      for (final size in sizes) {
        expect(size, isNotNull);
        expect(size, greaterThanOrEqualTo(11));
      }
    });

    test('should_never_use_a_thin_weight', () {
      // Burmese and Japanese render poorly at w300 and lighter. `w400` and
      // above map to 400/500/600 in FontWeight.value, which is the ordering
      // the style guide cares about.
      final weights = <FontWeight?>[
        AppTypography.displayAmount.fontWeight,
        AppTypography.amountLarge.fontWeight,
        AppTypography.amount.fontWeight,
        AppTypography.titleLarge.fontWeight,
        AppTypography.title.fontWeight,
        AppTypography.body.fontWeight,
        AppTypography.label.fontWeight,
        AppTypography.caption.fontWeight,
        AppTypography.overline.fontWeight,
      ];

      for (final weight in weights) {
        expect(weight, isNotNull);
        expect(weight!.value, greaterThanOrEqualTo(FontWeight.w400.value));
      }
    });

    test('should_track_overline_when_used_as_a_section_header', () {
      expect(AppTypography.overline.letterSpacing, 0.6);
    });

    test('should_increase_line_height_when_locale_needs_taller_boxes', () {
      const colors = AppColorsLight();
      final base = AppTypography.textTheme(colors);

      final myanmar = AppTypography.textThemeFor(base, 'my');

      expect(myanmar.bodyMedium!.height, greaterThan(base.bodyMedium!.height!));
    });

    test('should_leave_line_height_unchanged_for_latin_locales', () {
      const colors = AppColorsLight();
      final base = AppTypography.textTheme(colors);

      final english = AppTypography.textThemeFor(base, 'en');

      expect(english.bodyMedium!.height, base.bodyMedium!.height);
    });
  });

  group('elevation (docs/Design.md §4.3)', () {
    test('should_omit_shadow_when_flat', () {
      const colors = AppColorsLight();

      expect(AppElevation.flat(colors), isEmpty);
    });

    test('should_omit_shadow_in_dark_when_raised', () {
      // Dark mode uses a lighter surface instead of a shadow.
      const dark = AppColorsDark();

      expect(AppElevation.raised(dark), isEmpty);
    });

    test('should_apply_shadow_in_light_when_raised', () {
      const light = AppColorsLight();

      expect(AppElevation.raised(light), isNotEmpty);
    });

    test('should_apply_shadow_in_both_modes_when_floating', () {
      expect(AppElevation.floating(const AppColorsLight()), isNotEmpty);
      expect(AppElevation.floating(const AppColorsDark()), isNotEmpty);
    });
  });

  group('motion (docs/Design.md §4.4)', () {
    test('should_collapse_duration_to_zero_when_reduce_motion', () {
      expect(
        AppMotion.scale(AppMotion.long, reduceMotion: true),
        Duration.zero,
      );
    });

    test('should_preserve_duration_when_motion_is_allowed', () {
      expect(
        AppMotion.scale(AppMotion.long, reduceMotion: false),
        AppMotion.long,
      );
    });

    test('should_ascend_in_duration', () {
      expect(AppMotion.short, greaterThan(AppMotion.micro));
      expect(AppMotion.medium, greaterThan(AppMotion.short));
      expect(AppMotion.long, greaterThan(AppMotion.medium));
      expect(AppMotion.emphasized, greaterThan(AppMotion.long));
    });
  });

  group('glass (docs/Design.md §2.5)', () {
    test('should_use_smaller_blur_when_width_is_compact', () {
      expect(AppGlass.blurSigma(360), 18);
      expect(AppGlass.blurSigma(599), 18);
    });

    test('should_use_larger_blur_when_width_is_medium_or_more', () {
      expect(AppGlass.blurSigma(600), 24);
      expect(AppGlass.blurSigma(1440), 24);
    });

    test('should_cap_glass_surfaces_per_screen', () {
      // Performance guard from docs/Platform.md §4.
      expect(AppGlass.maxSurfacesPerScreen, 3);
    });
  });

  group('hit targets and row heights', () {
    test('should_never_go_below_the_ios_minimum_hit_target', () {
      expect(AppHitTarget.minimum, 44);
      expect(AppHitTarget.comfortable, greaterThanOrEqualTo(44));
    });

    test('should_keep_rows_above_the_absolute_minimum', () {
      expect(AppRowHeight.absoluteMinimum, greaterThanOrEqualTo(56));
      expect(
        AppRowHeight.singleLine,
        greaterThan(AppRowHeight.absoluteMinimum),
      );
      expect(AppRowHeight.twoLine, greaterThan(AppRowHeight.singleLine));
    });
  });

  group('system bars (docs/Platform.md §2)', () {
    test('should_show_dark_icons_on_light_surfaces', () {
      final style = AppTheme.systemOverlayStyle(Brightness.light);

      // White-on-white is the invisible-status-bar bug: edge-to-edge bars are
      // transparent, so the icons must contrast the light surface.
      expect(style.statusBarIconBrightness, Brightness.dark);
      expect(style.statusBarColor, Colors.transparent);
      expect(style.systemNavigationBarColor, Colors.transparent);
    });

    test('should_show_light_icons_on_dark_surfaces', () {
      final style = AppTheme.systemOverlayStyle(Brightness.dark);

      expect(style.statusBarIconBrightness, Brightness.light);
      expect(style.statusBarColor, Colors.transparent);
      expect(style.systemNavigationBarColor, Colors.transparent);
    });

    test('should_match_the_app_bar_overlay_to_the_theme', () {
      expect(
        AppTheme.light()
            .appBarTheme
            .systemOverlayStyle
            ?.statusBarIconBrightness,
        Brightness.dark,
      );
      expect(
        AppTheme.dark().appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
        Brightness.light,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // §K — the contrast blind spot, now covered
  // ---------------------------------------------------------------------------
  //
  // Every test above this group passed while the app shipped an invisible
  // selected day, an invisible capsule bar and an unreadable weekday header
  // (docs/Roadmap.md §K). The cause is in what they *covered*: `textPrimary`,
  // `moneyOut`, `moneyIn` and dark `brandPrimary`, each against `surface` only.
  // Nothing asserted the rest of the text ramp, any fill, the selected state,
  // the FAB, the capsule ramp, or that light and dark agree with each other.
  //
  // These tests close that gap. They are the reason the next token change cannot
  // regress silently — the §K defects each have a name and a number here.

  group('contrast coverage for every role (docs/Roadmap.md §K)', () {
    /// Both modes, so a fix that only works on white cannot pass.
    const light = AppColorsLight();
    const dark = AppColorsDark();

    test('every_text_token_meets_aa_on_surface_and_raised', () {
      // Amounts and labels sit on cards (`surfaceRaised`) as often as on the
      // page (`surface`), so both are asserted — §K found `textTertiary` at
      // 2.58:1 light and 3.21:1 dark, i.e. failing on both.
      for (final entry in <(String, AppColors, Color)>[
        ('light textPrimary', light, light.textPrimary),
        ('light textSecondary', light, light.textSecondary),
        ('light textTertiary', light, light.textTertiary),
        ('dark textPrimary', dark, dark.textPrimary),
        ('dark textSecondary', dark, dark.textSecondary),
        ('dark textTertiary', dark, dark.textTertiary),
      ]) {
        final (label, colors, token) = entry;
        for (final surface in <Color>[colors.surface, colors.surfaceRaised]) {
          expect(
            _contrast(token, surface),
            greaterThanOrEqualTo(4.5),
            reason:
                '$label on ${surface.toARGB32().toRadixString(16)} '
                'must clear AA',
          );
        }
      }
    });

    test('every_accent_meets_aa_on_all_three_surfaces', () {
      // §2.4 requires this of the money colours "against every surface they can
      // sit on" — `surfaceSubtle` was missing, and `brandPrimary` was never
      // asserted in light at all.
      for (final entry in <(String, AppColors, Color)>[
        ('light brandPrimary', light, light.brandPrimary),
        ('light moneyOut', light, light.moneyOut),
        ('light moneyIn', light, light.moneyIn),
        ('dark brandPrimary', dark, dark.brandPrimary),
        ('dark moneyOut', dark, dark.moneyOut),
        ('dark moneyIn', dark, dark.moneyIn),
      ]) {
        final (label, colors, token) = entry;
        for (final surface in <Color>[
          colors.surface,
          colors.surfaceRaised,
          colors.surfaceSubtle,
        ]) {
          expect(
            _contrast(token, surface),
            greaterThanOrEqualTo(4.5),
            reason:
                '$label on ${surface.toARGB32().toRadixString(16)} must clear AA',
          );
        }
      }
    });

    test('warning_meets_aa_in_both_modes', () {
      // Light `warning` was `#C98A0B` at **2.95:1** on white — a budget-at-risk
      // label that failed AA (§K.4). §2.4 routes errors to `warning`, so it has
      // to be readable as text.
      for (final entry in <(String, AppColors)>[
        ('light', light),
        ('dark', dark),
      ]) {
        final (label, colors) = entry;
        expect(
          _contrast(colors.warning, colors.surface),
          greaterThanOrEqualTo(4.5),
          reason: '$label warning on surface must clear AA',
        );
      }
    });

    test('the_focus_ring_clears_the_three_to_one_non_text_floor', () {
      // `borderStrong` is a focus ring, which WCAG 1.4.11 treats as a UI mark:
      // 3:1. Light was `#98A2B0` at 2.58:1 (§K.4).
      for (final entry in <(String, AppColors)>[
        ('light', light),
        ('dark', dark),
      ]) {
        final (label, colors) = entry;
        expect(
          _contrast(colors.borderStrong, colors.surface),
          greaterThanOrEqualTo(3.0),
          reason: '$label borderStrong is a UI mark and needs 3:1',
        );
      }
    });

    test('the_selected_fill_is_a_state_not_a_tint', () {
      // The §K.1-2 defect: selection was painted `brandSubtle`, measured 1.20:1
      // light and 1.29:1 dark — a state nobody could see. A *fill* therefore
      // has to clear 3:1, and its on-colour 4.5:1.
      for (final entry in <(String, AppColors)>[
        ('light', light),
        ('dark', dark),
      ]) {
        final (label, colors) = entry;
        expect(
          _contrast(colors.selectedFill, colors.surface),
          greaterThanOrEqualTo(3.0),
          reason: '$label selectedFill must be perceivable as a state',
        );
        expect(
          _contrast(colors.onSelectedFill, colors.selectedFill),
          greaterThanOrEqualTo(4.5),
          reason: '$label onSelectedFill on selectedFill must clear AA',
        );
      }
    });

    test('a_tinted_fill_is_perceivable_and_carries_its_own_on_colour', () {
      // `brandSubtle` is still a *tint* (a nav indicator, a chip pill), so it is
      // allowed below 3:1 — but it must be more than a whisper, and its
      // foreground must be a distinct token: `brandPrimary` on it measured
      // 3.90:1 light / 3.43:1 dark, which is why `onBrandSubtle` exists.
      for (final entry in <(String, AppColors)>[
        ('light', light),
        ('dark', dark),
      ]) {
        final (label, colors) = entry;
        for (final surface in <Color>[
          colors.surface,
          colors.surfaceRaised,
          colors.surfaceSubtle,
        ]) {
          expect(
            _contrast(colors.brandSubtle, surface),
            greaterThanOrEqualTo(1.4),
            reason: '$label brandSubtle must read as a tint on $surface',
          );
        }
        expect(
          _contrast(colors.onBrandSubtle, colors.brandSubtle),
          greaterThanOrEqualTo(4.5),
          reason: '$label onBrandSubtle on brandSubtle must clear AA',
        );
        expect(
          colors.onBrandSubtle,
          isNot(colors.brandPrimary),
          reason: '$label must not paint brandPrimary on brandSubtle',
        );
      }
    });

    test('the_fab_uses_the_brand_colour_not_the_primary_container', () {
      // §2.2: `brandPrimary` is the "FAB, selected tab, primary button". Without
      // a theme M3 falls back to `primaryContainer` = `brandSubtle`, which is
      // what made every FAB in the app pale-mint / dark-forest (§K.1-5).
      for (final theme in <ThemeData>[AppTheme.light(), AppTheme.dark()]) {
        final fab = theme.floatingActionButtonTheme;
        expect(fab, isNotNull, reason: 'the FAB must be themed explicitly');
        expect(fab.backgroundColor, theme.colorScheme.primary);
        expect(fab.foregroundColor, theme.colorScheme.onPrimary);
      }
    });

    test('every_capsule_step_is_visible_and_ordered', () {
      // Mirrors `_Capsule` in `day_cell.dart`. Step 1 used to *be* the
      // `*Subtle` tint at 1.13–1.25:1 — the "black bar" the owner reported
      // (§K.1-3). Every step now clears 2.5:1 and each is lighter than the last,
      // so the grid still reads as a 5-step texture rather than noise.
      for (final entry in <(String, AppColors)>[
        ('light', light),
        ('dark', dark),
      ]) {
        final (label, colors) = entry;
        for (final entry2 in <(String, Color, Color)>[
          ('expense', colors.moneyOutSubtle, colors.moneyOut),
          ('income', colors.moneyInSubtle, colors.moneyIn),
        ]) {
          final (family, subtle, full) = entry2;
          final ratios = <double>[
            for (var step = 1; step <= 4; step++)
              _contrast(
                Color.lerp(
                  subtle,
                  full,
                  _capsuleRampStart + (1 - _capsuleRampStart) * (step - 1) / 3,
                )!,
                colors.surface,
              ),
          ];
          expect(
            ratios.first,
            greaterThanOrEqualTo(2.5),
            reason: '$label $family capsule step 1 must be visible',
          );
          for (var i = 1; i < ratios.length; i++) {
            expect(
              ratios[i],
              greaterThan(ratios[i - 1]),
              reason: '$label $family capsule steps must increase in depth',
            );
          }
        }
      }
    });

    test('light_and_dark_agree_within_30_percent_on_text_and_accents', () {
      // The owner's "the difference is too extreme" is a measurement, not a
      // feeling: same role, contrast against its own surface. Before §K,
      // `moneyIn` was +63% and `brandPrimary` +48% — two different designs
      // sharing one set of names.
      for (final entry in <(String, Color, Color)>[
        ('textPrimary', light.textPrimary, dark.textPrimary),
        ('textSecondary', light.textSecondary, dark.textSecondary),
        ('textTertiary', light.textTertiary, dark.textTertiary),
        ('brandPrimary', light.brandPrimary, dark.brandPrimary),
        ('moneyOut', light.moneyOut, dark.moneyOut),
        ('moneyIn', light.moneyIn, dark.moneyIn),
      ]) {
        final (label, lightToken, darkToken) = entry;
        final lightRatio = _contrast(lightToken, light.surface);
        final darkRatio = _contrast(darkToken, dark.surface);
        final drift = (darkRatio - lightRatio) / lightRatio * 100;
        expect(
          drift.abs(),
          lessThanOrEqualTo(30),
          reason:
              '$label drifts ${drift.toStringAsFixed(1)}% between modes '
              '(${lightRatio.toStringAsFixed(2)} vs '
              '${darkRatio.toStringAsFixed(2)})',
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  // §L — the light surface ramp had no card in it
  // ---------------------------------------------------------------------------
  //
  // §K audited *colour roles* and left the surface ramp unexamined, on the
  // assumption that four named surfaces were four different surfaces. In light
  // mode they were not: `surface` and `surfaceRaised` were both #FFFFFF, and
  // `surfaceSubtle` (#F5F7FA) was *darker* than the "raised" surface §2.2
  // defines as the one that lifts off it. A card therefore had 1.00:1 against
  // the page — measured as 83.6% identical pixels across an accounts screen —
  // while dark mode separated the same two roles into 61.4% and 21.7%. That is
  // the structural half of "the two modes look like different apps", and no
  // test in §K could see it because none of them compared two surfaces.
  //
  // White is the brightest value light mode has, so the only fix is to lower
  // the page. How far is solved, not chosen: `warning` on the page and
  // `textTertiary` on the keypad tray are the binding AA constraints.

  group('surface ramp (docs/Design.md §2.7, docs/Roadmap.md §L)', () {
    const light = AppColorsLight();
    const dark = AppColorsDark();

    test('the_four_surfaces_form_a_strictly_ascending_ramp', () {
      // §2.2 defines `surfaceRaised` as the surface that lifts off
      // `surfaceSubtle`. That only means something if the ramp is ordered, so
      // assert the ordering in both modes rather than trusting the hex.
      for (final entry in <(String, AppColors)>[
        ('light', light),
        ('dark', dark),
      ]) {
        final (label, colors) = entry;
        final ramp = <double>[
          _luminance(colors.surfaceSunken),
          _luminance(colors.surface),
          _luminance(colors.surfaceSubtle),
          _luminance(colors.surfaceRaised),
        ];
        for (var i = 1; i < ramp.length; i++) {
          expect(
            ramp[i],
            greaterThan(ramp[i - 1]),
            reason:
                '$label surface ramp must ascend (sunken < surface < subtle '
                '< raised); got luminances ${ramp.join(', ')}',
          );
        }
      }
    });

    test('a_card_is_actually_separated_from_the_page_behind_it', () {
      // The §L defect was 1.00:1 — invisible. A real lift has to be visible,
      // so this is the number that proves the card exists. Both modes are
      // asserted: light had the defect, and a fix that only works on white
      // would not be a fix.
      for (final entry in <(String, AppColors)>[
        ('light', light),
        ('dark', dark),
      ]) {
        final (label, colors) = entry;
        final separation = _contrast(colors.surfaceRaised, colors.surface);
        expect(
          separation,
          greaterThanOrEqualTo(1.05),
          reason:
              '$label card-vs-page separation is only '
              '${separation.toStringAsFixed(3)}:1 — the card is not lifted',
        );
      }
    });

    test('the_two_modes_lift_a_card_by_the_same_amount', () {
      // Extends the §K parity rule to surfaces: the same role relationship
      // must resolve the same way in both modes. Light separates its card by
      // 1.07:1 and dark by 1.14:1, so the two modes are one design.
      //
      // The ramp *width* is deliberately not asserted. It is 3.9 L* in light
      // and 8.1 in dark, because dark mode gets no shadow at all (§4.3) and so
      // needs twice the surface steps to carry the same elevation.
      final lightSeparation = _contrast(light.surfaceRaised, light.surface);
      final darkSeparation = _contrast(dark.surfaceRaised, dark.surface);
      final drift = (darkSeparation - lightSeparation) / lightSeparation * 100;

      expect(
        drift.abs(),
        lessThanOrEqualTo(30),
        reason:
            'card lift drifts ${drift.toStringAsFixed(1)}% between modes '
            '(${lightSeparation.toStringAsFixed(3)} vs '
            '${darkSeparation.toStringAsFixed(3)}) — the two modes disagree '
            'about what a raised surface means',
      );
    });

    test('every_role_stays_legible_on_the_light_surface_it_lands_on', () {
      // Lowering the page is only safe while the ink still clears AA on it.
      // The keypad tray (`surfaceSunken`) is the tight one: it carries the
      // amount display in `textTertiary`, and the page (`surface`) carries
      // `warning`. Both are asserted here so a future "let's darken the page a
      // touch more" fails instead of shipping.
      for (final surface in <Color>[
        light.surfaceSunken,
        light.surfaceSubtle,
        light.surface,
        light.surfaceRaised,
      ]) {
        final hex = surface.toARGB32().toRadixString(16);
        for (final entry in <(String, Color)>[
          ('textPrimary', light.textPrimary),
          ('textSecondary', light.textSecondary),
          ('textTertiary', light.textTertiary),
          ('moneyOut', light.moneyOut),
          ('moneyIn', light.moneyIn),
          ('brandPrimary', light.brandPrimary),
        ]) {
          final (label, token) = entry;
          expect(
            _contrast(token, surface),
            greaterThanOrEqualTo(4.5),
            reason: 'light $label on $hex must clear AA on every surface',
          );
        }
      }

      // `warning` is a page/card colour, never a well or a band, so it is
      // held to the two surfaces it actually appears on. Folding it into the
      // loop above would demand an AA floor light mode cannot meet on the
      // darkest surfaces without turning the page back into white.
      for (final surface in <Color>[light.surface, light.surfaceRaised]) {
        expect(
          _contrast(light.warning, surface),
          greaterThanOrEqualTo(4.5),
          reason:
              'light warning on ${surface.toARGB32().toRadixString(16)} '
              'must clear AA',
        );
      }
    });

    test('the_dark_ramp_still_lifts_the_card_above_the_page', () {
      // Guards the direction of the dark ramp: raising the card is what makes
      // dark mode read as elevated, and §K's surface work must not have
      // flattened it to match light.
      expect(
        _luminance(dark.surfaceRaised),
        greaterThan(_luminance(dark.surface)),
      );
    });
  });
}
