import 'dart:ui' as ui;

import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/adaptive_style.dart';
import 'package:material_ui/material_ui.dart';

/// The frosted surface behind the floating chrome (docs/Platform.md §4).
///
/// One widget, three modes, chosen from [AdaptiveStyle] — never by the caller:
///
///  * **blur** — iOS with Liquid Glass available. `BackdropFilter` + tint +
///    hairline stroke. This is the shipped implementation; the native tab bar
///    and the refraction shader are deliberately **not** used (`Platform.md` §4
///    verdict: both carry risk this component does not need).
///  * **solid** — Reduce Transparency / Increase Contrast is on, or the platform
///    has no glass. Falls back to `surfaceRaised` with a hairline border, so the
///    bar stays legible instead of turning into a washed-out smear.
///  * **material** — Android/web never imitate glass (`Platform.md` §4:
///    "Android/web: M3 surfaces — never imitate glass").
///
/// Glass is for the **floating chrome layer only** — tab bar, toolbar buttons,
/// FAB, sheets. Never content cards.
class GlassSurface extends StatelessWidget {
  /// Wraps [child] in the appropriate chrome surface.
  const GlassSurface({
    required this.child,
    this.borderRadius,
    this.border,
    this.padding,
    super.key,
  });

  /// The content that floats on the surface.
  final Widget child;

  /// Corner radius. Null means square (a full-width bar with no rounding).
  final BorderRadius? borderRadius;

  /// Optional hairline. Defaults to a full outline; pass e.g.
  /// `Border(top: BorderSide(...))` for a bar that only needs a top edge.
  final Border? border;

  /// Inner padding.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final adaptive = AdaptiveStyle.of(context);
    final colors = AppThemeColors.of(context);
    final radius = borderRadius ?? BorderRadius.zero;

    // Android and web get a plain M3 surface. Skipping the blur is not just an
    // aesthetic choice: on Android a BackdropFilter over a scrolling list is a
    // measurable cost for a look the platform does not use anyway.
    if (!adaptive.canUseGlass) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: radius,
          border: border ?? Border.all(color: colors.border),
        ),
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        // A single sigma for both axes: a directional blur reads as a smudge on
        // a bar that scrolls in two directions.
        filter: ui.ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.glassTint,
            borderRadius: radius,
            border: border ?? Border.all(color: colors.glassStroke),
          ),
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }

  /// Blur radius. Fixed rather than scaled by radius: the glass look comes from
  /// how much content is diffused, which does not change with corner rounding.
  ///
  /// Kept modest (docs/Platform.md §4: profile on older hardware) — a large
  /// sigma over a long scrolling list is the expensive case.
  static const double _blurSigma = 18;
}

/// The floating glass bar iOS uses instead of a docked bar
/// (docs/Design.md §5.10: "floating glass bar, inset `lg` from screen edges and
/// bottom safe area").
///
/// Provides only the chrome and the inset; the content is the caller's.
class FloatingGlassBar extends StatelessWidget {
  /// Creates the bar.
  const FloatingGlassBar({
    required this.child,
    this.inset = AppSpacing.lg,
    super.key,
  });

  /// The bar's content (normally a row of destinations).
  final Widget child;

  /// Gap between the bar and the screen edges.
  final double inset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        inset,
        0,
        inset,
        // Sits above the home indicator without touching it.
        inset + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: GlassSurface(
        borderRadius: AppRadius.borderXl,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: child,
      ),
    );
  }
}

/// A solid bottom bar for Material platforms — the docked counterpart to
/// [FloatingGlassBar], matching M3 `NavigationBar` metrics.
///
/// Exists as its own widget so `AdaptiveNav` can swap the two without the
/// caller knowing which platform it is on.
class DockedBottomBar extends StatelessWidget {
  /// Creates the bar.
  const DockedBottomBar({required this.child, super.key});

  /// The bar's content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: MediaQuery.removePadding(
        context: context,
        // The bar handles the bottom inset itself via the SafeArea below, so the
        // child must not also be inset or the icons sit too high.
        removeBottom: true,
        child: SafeArea(top: false, child: child),
      ),
    );
  }
}
