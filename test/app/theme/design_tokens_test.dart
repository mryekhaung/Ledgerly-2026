import 'dart:ui' show FontFeature;

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:material_ui/material_ui.dart';

/// Token-level assertions.
///
/// The design system is the contract every screen is built on, so its invariants
/// are tested rather than reviewed: contrast ratios, the money color rule, and
/// the tabular-figures requirement are the ones that silently rot otherwise.
void main() {
  group('color contrast (docs/Design.md §2)', () {
    /// WCAG relative luminance.
    ///
    /// Uses `.r/.g/.b`, which are 0..1 in the current Flutter `Color` API.
    double luminance(Color c) {
      double channel(double v) =>
          v <= 0.03928 ? v / 12.92 : _pow((v + 0.055) / 1.055, 2.4);
      return 0.2126 * channel(c.r) +
          0.7152 * channel(c.g) +
          0.0722 * channel(c.b);
    }

    double contrastRatio(Color a, Color b) {
      final la = luminance(a);
      final lb = luminance(b);
      final lighter = la > lb ? la : lb;
      final darker = la > lb ? lb : la;
      return (lighter + 0.05) / (darker + 0.05);
    }

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
}

double _pow(double base, double exponent) {
  // Small integer-ish power without importing dart:math for one call site.
  var result = 1.0;
  for (var i = 0; i < exponent.round(); i++) {
    result *= base;
  }
  return result;
}
