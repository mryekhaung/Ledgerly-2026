import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:material_ui/material_ui.dart';

/// Type scale (docs/Design.md §3).
///
/// Fonts: **Inter** for amounts + Latin UI, **Noto Sans Myanmar** (`my`),
/// **Noto Sans JP** (`ja`), system fallback elsewhere. Bundled for web.
///
/// Two rules from docs/Design.md §3 are enforced here rather than left to
/// discipline:
///   1. **All amounts use tabular figures** so columns align and digits don't
///      jitter during animation. See [amountStyles] / the `amount*` members.
///   2. **Nothing below 11 px, nothing lighter than w500 on small sizes** —
///      thin weights render poorly for Burmese and Japanese.
abstract final class AppTypography {
  const AppTypography._();

  /// Latin + amount family.
  static const String fontFamily = 'Inter';

  /// Burmese family — applied per-locale via [textThemeFor].
  static const String fontFamilyMyanmar = 'Noto Sans Myanmar';

  /// Japanese family — applied per-locale via [textThemeFor].
  static const String fontFamilyJapanese = 'Noto Sans JP';

  /// Tabular figures. Applied to every money style and to aligned numeric columns.
  static const List<FontFeature> tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  /// Hero amount — summary card, keypad display (40/44, w600).
  static const TextStyle displayAmount = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    height: 44 / 40,
    fontWeight: FontWeight.w600,
    fontFeatures: tabularFigures,
  );

  /// Selected-day total (28/32, w600).
  static const TextStyle amountLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 32 / 28,
    fontWeight: FontWeight.w600,
    fontFeatures: tabularFigures,
  );

  /// List-row amounts (17/22, w600).
  static const TextStyle amount = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w600,
    fontFeatures: tabularFigures,
  );

  /// Screen title, large (22/28, w600).
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w600,
  );

  /// Card titles, nav labels (17/22, w600).
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w600,
  );

  /// Body copy (15/21, w400).
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 21 / 15,
    fontWeight: FontWeight.w400,
  );

  /// Field labels, chips (13/18, w500).
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
  );

  /// Day numbers, timestamps (11/15, w500).
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 15 / 11,
    fontWeight: FontWeight.w500,
  );

  /// Section headers, ALL CAPS (11/14, w600, tracking 0.6).
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  );

  /// Every amount style, for exhaustive application in tests.
  static const Map<String, TextStyle> amountStyles = <String, TextStyle>{
    'displayAmount': displayAmount,
    'amountLarge': amountLarge,
    'amount': amount,
  };

  /// Builds the themed [TextTheme] for [colors].
  ///
  /// Amount colors are applied by `AmountText`, not here, because they depend on
  /// the money's sign rather than the slot.
  static TextTheme textTheme(AppColors colors) => TextTheme(
    displayLarge: displayAmount.copyWith(color: colors.textPrimary),
    headlineLarge: titleLarge.copyWith(color: colors.textPrimary),
    titleMedium: title.copyWith(color: colors.textPrimary),
    bodyMedium: body.copyWith(color: colors.textPrimary),
    labelMedium: label.copyWith(color: colors.textSecondary),
    labelSmall: caption.copyWith(color: colors.textSecondary),
    labelLarge: overline.copyWith(color: colors.textSecondary),
  );

  /// Returns [base] adjusted for the line-height needs of [locale]
  /// (docs/Design.md §3: my/ja get +0.15 so ascenders/descenders don't clip).
  ///
  /// The font family is swapped by the `fontFamily` override on the theme, so this
  /// only corrects metrics.
  static TextTheme textThemeFor(TextTheme base, String locale) {
    if (locale != 'my' && locale != 'ja') return base;

    const bump = 0.15;
    TextStyle expand(TextStyle? style) {
      if (style == null) return const TextStyle();
      final height = style.height;
      return style.copyWith(height: height == null ? null : height + bump);
    }

    return base.copyWith(
      displayLarge: expand(base.displayLarge),
      headlineLarge: expand(base.headlineLarge),
      titleMedium: expand(base.titleMedium),
      bodyMedium: expand(base.bodyMedium),
      labelMedium: expand(base.labelMedium),
      labelSmall: expand(base.labelSmall),
      labelLarge: expand(base.labelLarge),
    );
  }
}
