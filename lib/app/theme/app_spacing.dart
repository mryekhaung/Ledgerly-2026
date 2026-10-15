import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:material_ui/material_ui.dart';

/// Spacing scale — **base unit 4**, only these values exist
/// (docs/Design.md §4.1).
///
/// Non-token spacing is a design bug, not a preference.
abstract final class AppSpacing {
  const AppSpacing._();

  /// 2 px — hairline nudges inside a component.
  static const double xxs = 2;

  /// 4 px — glyph-to-label gaps.
  static const double xs = 4;

  /// 8 px — related items within a group.
  static const double sm = 8;

  /// 12 px — internal component padding.
  static const double md = 12;

  /// 16 px — the default. Screen padding (compact), row padding, block gaps.
  static const double lg = 16;

  /// 24 px — screen padding (medium+), gap between unrelated blocks.
  static const double xl = 24;

  /// 32 px — section separation.
  static const double xxl = 32;

  /// 48 px — major page-level separation.
  static const double xxxl = 48;

  /// Horizontal page padding for a given window width
  /// (docs/Design.md §4.1: 16 compact, 24 medium+).
  static double pageHorizontal(double width) => width < 600 ? lg : xl;

  /// Maximum content width for readable single-column content
  /// (docs/Design.md §8: never stretch text past ~560 px).
  static const double proseMaxWidth = 560;

  /// Maximum app content width on wide screens (docs/Platform.md §5).
  static const double contentMaxWidth = 1200;
}

/// Corner radius scale (docs/Design.md §4.2).
abstract final class AppRadius {
  const AppRadius._();

  /// 8 — chips, capsules, day-capsule bars.
  static const double sm = 8;

  /// 12 — inputs, grouped list containers.
  static const double md = 12;

  /// 20 — cards, sheets.
  static const double lg = 20;

  /// 28 — glass bars, FAB, large surfaces.
  static const double xl = 28;

  /// Fully rounded — pills, avatars, circular buttons.
  static const double full = 999;

  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderFull = BorderRadius.all(
    Radius.circular(full),
  );

  /// The same value as [borderSm], for widgets that need a single [Radius]
  /// (progress-bar clips, drag handles). Add more variants only when a call
  /// site actually needs one.
  static const Radius radiusSm = Radius.circular(sm);

  /// The same value as [borderMd], for widgets that need a single [Radius]
  /// (sheet top corners via `BorderRadius.vertical`).
  static const Radius radiusMd = Radius.circular(md);

  /// The same value as [borderLg], for widgets that need a single [Radius]
  /// (sheet top corners via `BorderRadius.vertical`).
  static const Radius radiusLg = Radius.circular(lg);

  /// The same value as [borderXl], for widgets that need a single [Radius]
  /// (`showModalBottomSheet` / `BorderRadius.vertical` shapes). Add more
  /// variants only when a call site actually needs one.
  static const Radius radiusXl = Radius.circular(xl);
}

/// Elevation: we prefer tint + hairline over shadow. Three levels only
/// (docs/Design.md §4.3).
abstract final class AppElevation {
  const AppElevation._();

  /// Rows and grouped lists — a hairline, no shadow.
  static List<BoxShadow> flat(AppColors colors) => const <BoxShadow>[];

  /// Cards — a whisper of lift in light mode, none in dark (surface does the work).
  static List<BoxShadow> raised(AppColors colors) => colors.isDark
      ? const <BoxShadow>[]
      : const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F0F1720),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ];

  /// FAB, glass bars, sheets.
  static List<BoxShadow> floating(AppColors colors) => colors.isDark
      ? const <BoxShadow>[
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ]
      : const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F0F1720),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ];
}

/// Motion tokens (docs/Design.md §4.4).
///
/// Always read durations through [scale] so *Reduce Motion* / *disable animations*
/// collapses every duration to zero in one place.
abstract final class AppMotion {
  const AppMotion._();

  static const Duration micro = Duration(milliseconds: 100);
  static const Duration short = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration long = Duration(milliseconds: 400);
  static const Duration emphasized = Duration(milliseconds: 500);

  // Curves
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeOutQuint;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;

  /// Collapses [duration] to zero when the platform asks for reduced motion.
  static Duration scale(Duration duration, {required bool reduceMotion}) =>
      reduceMotion ? Duration.zero : duration;
}

/// Glass surface constants — iOS floating chrome only
/// (docs/Design.md §2.5, docs/Platform.md §4).
abstract final class AppGlass {
  const AppGlass._();

  /// Blur strength by window width: 18 compact, 24 medium+.
  static double blurSigma(double width) => width < 600 ? 18 : 24;

  /// Hairline stroke width for the glass highlight.
  static const double strokeWidth = 0.5;

  /// Maximum glass surfaces on screen at once (docs/Platform.md §4).
  static const int maxSurfacesPerScreen = 3;
}

/// Layout breakpoints for M3 window size classes
/// (docs/Platform.md §5).
abstract final class AppBreakpoints {
  const AppBreakpoints._();

  static const double medium = 600;
  static const double expanded = 840;
  static const double large = 1200;
}

/// Minimum interactive target — iOS HIG 44, Android FAB 48
/// (docs/Design.md §5.7).
abstract final class AppHitTarget {
  const AppHitTarget._();

  static const double minimum = 44;
  static const double comfortable = 48;
}

/// Row height contracts used by `ListRow` (docs/Design.md §5.6) and the
/// calendar day cell (§6.2).
abstract final class AppRowHeight {
  const AppRowHeight._();

  static const double singleLine = 64;
  static const double twoLine = 76;
  static const double absoluteMinimum = 56;

  /// Height of one calendar day cell (docs/Design.md §6.2).
  ///
  /// Material 3's date picker measures a **40 dp** date bounding box with
  /// **4 dp** between dates, which is 44 — not the 48 this used before, where
  /// every row carried 4 px of dead space and six rows wasted 24 px (§M.1).
  ///
  /// Shared with `month_grid.dart`, which draws the empty padding cells that
  /// complete the first and last week. Those used to carry their own
  /// `AppSpacing.xxxl` — the same 48 written a second time, in a file that
  /// cannot see the first.
  static const double calendarCell = 44;
}
