import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// M3 window size class (docs/Platform.md §5).
///
/// Layout differences come from **size class, never platform** — an Android
/// tablet and an iPad get the same layout.
enum WindowSizeClass {
  /// < 600 — single column, bottom nav, full-screen push pages.
  compact,

  /// 600–839 — nav rail, two-pane where useful, forms in a centered 560 column.
  medium,

  /// 840–1199 — sidebar nav, master–detail panes.
  expanded,

  /// >= 1200 — sidebar + content capped ~1200, extra gutters, 3-column insights.
  large;

  /// Classifies a logical width in logical pixels.
  static WindowSizeClass fromWidth(double width) {
    if (width < 600) return WindowSizeClass.compact;
    if (width < 840) return WindowSizeClass.medium;
    if (width < 1200) return WindowSizeClass.expanded;
    return WindowSizeClass.large;
  }

  /// Classifies the window that [context] is being laid out in.
  ///
  /// Uses `MediaQuery.sizeOf` so the widget only rebuilds when the size changes,
  /// not on every MediaQuery field change.
  static WindowSizeClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  /// True when this class is wide enough for a two-pane / master–detail layout.
  ///
  /// Calendar, Categories, and Settings all switch to two panes at this point
  /// (docs/Platform.md §5).
  bool get isTwoPaneCapable => this != WindowSizeClass.compact;

  /// True when a navigation rail or sidebar replaces the bottom bar.
  bool get usesNavigationRail => index >= WindowSizeClass.medium.index;

  /// True when the sidebar layout (rather than a rail) applies.
  bool get usesSidebar => index >= WindowSizeClass.expanded.index;

  /// Whether the app should present centered modal forms instead of full pages
  /// (docs/Platform.md §5: Add/Edit Transaction and other forms).
  bool get usesModalForms => isTwoPaneCapable;

  /// Human-readable label, for debug overlays and golden test names.
  String get label => switch (this) {
    WindowSizeClass.compact => 'compact',
    WindowSizeClass.medium => 'medium',
    WindowSizeClass.expanded => 'expanded',
    WindowSizeClass.large => 'large',
  };
}

/// The canonical widths the design must be verified at
/// (docs/Design.md §8, docs/Platform.md §5).
abstract final class TestWidths {
  const TestWidths._();

  /// Small phone (360 px) — the tightest realistic constraint.
  static const double smallPhone = 360;

  /// iPhone 14/15 logical width.
  static const double phone = 390;

  /// Large phone / small foldable.
  static const double largePhone = 430;

  /// Tablet portrait / split view — first two-pane breakpoint.
  static const double tablet = 768;

  /// Tablet landscape / small desktop.
  static const double desktop = 1024;

  /// Wide desktop — content cap engages.
  static const double wide = 1440;

  /// Every width that must be checked before a UI task is done.
  static const List<double> all = <double>[
    smallPhone,
    phone,
    largePhone,
    tablet,
    desktop,
    wide,
  ];
}
