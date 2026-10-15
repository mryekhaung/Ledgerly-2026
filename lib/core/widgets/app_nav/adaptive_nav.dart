import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/router/nav_destinations.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/adaptive_style.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/glass/glass_surface.dart';
import 'package:material_ui/material_ui.dart';

/// The app's primary navigation chrome (docs/Platform.md §3).
///
/// Pages never build this and never branch on platform — the shell mounts it
/// once and it renders the right thing for the current platform **and** size
/// class:
///
/// | Platform | compact | medium | expanded / large |
/// |---|---|---|---|
/// | iOS | floating glass bar | rail | sidebar |
/// | Android / web | M3 `NavigationBar` | rail | sidebar |
///
/// Size class beats platform: an iPad in landscape gets the sidebar, and an
/// Android tablet gets the same sidebar as the iPad (`Platform.md` §2 rule 4 —
/// layout differences come from size class, not platform).
class AdaptiveNav extends StatelessWidget {
  /// Creates the navigation chrome.
  const AdaptiveNav({required this.current, required this.onSelect, super.key});

  /// The destination currently selected, or null when the current route is not a
  /// primary destination (e.g. the add-transaction form, which lives outside the
  /// shell anyway, or a deep-linked unknown path). A null selection renders no
  /// active item rather than lying about which section the user is in.
  final NavDestination? current;

  /// Called with the destination the user picked.
  final ValueChanged<NavDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    final adaptive = AdaptiveStyle.of(context);
    final sizeClass = adaptive.sizeClass;
    final strings = AppStrings.of(context);

    // Wide windows get a rail or sidebar regardless of platform.
    if (sizeClass.usesSidebar) {
      return _NavSidebar(
        current: current,
        onSelect: onSelect,
        destinationLabel: (d) => d.label(strings),
      );
    }
    if (sizeClass.usesNavigationRail) {
      return _NavRail(
        current: current,
        onSelect: onSelect,
        destinationLabel: (d) => d.label(strings),
      );
    }

    // Compact: iOS floats a glass bar, everyone else docks an M3 bar.
    if (adaptive.canUseGlass) {
      return _GlassNavBar(
        current: current,
        onSelect: onSelect,
        destinationLabel: (d) => d.label(strings),
      );
    }
    return _MaterialNavBar(
      current: current,
      onSelect: onSelect,
      destinationLabel: (d) => d.label(strings),
    );
  }

  /// Navigates from anywhere inside the shell — built for the router's `builder`.
  ///
  /// Kept as a small escape hatch because the sidebar/rail need the shell's own
  /// navigation callback and the bar does not.
  static String routeOf(NavDestination destination) => destination.route;
}

/// Whether [location] should read as [destination] being selected.
///
/// Extracted so `window`-level tests can assert the matching rule without
/// mounting a router.
bool isDestinationSelected(NavDestination destination, String location) =>
    NavDestination.fromLocation(location) == destination;

/// M3 `NavigationBar` — the compact Android/web layout.
class _MaterialNavBar extends StatelessWidget {
  const _MaterialNavBar({
    required this.current,
    required this.onSelect,
    required this.destinationLabel,
  });

  final NavDestination? current;
  final ValueChanged<NavDestination> onSelect;
  final String Function(NavDestination) destinationLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    // `NavigationBar.selectedIndex` is a non-nullable `int` (unlike
    // `NavigationRail.selectedIndex`, which is an `int?`), so the bar has no way
    // to say "nothing is selected" the way the rail does with `null`. Passing 0
    // unconditionally would light up the first destination and contradict this
    // widget's contract — a route that is not a destination must not claim to be
    // one. So when [current] is null the bar still needs a valid in-range index,
    // but everything that *reads* as selected is painted neutral: the pill is
    // transparent and every destination keeps its unselected icon.
    final hasSelection = current != null;

    return DockedBottomBar(
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          // Brand-derived colours rather than Material's defaults, so the
          // selected pill matches the rest of the app (docs/Design.md §2.2).
          indicatorColor: hasSelection
              ? colors.brandSubtle
              : Colors.transparent,
          backgroundColor: colors.surfaceRaised,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => Theme.of(context).textTheme.labelSmall?.copyWith(
              color: states.contains(WidgetState.selected) && hasSelection
                  ? colors.brandPrimary
                  : colors.textSecondary,
              fontWeight: states.contains(WidgetState.selected) && hasSelection
                  ? FontWeight.w600
                  : null,
            ),
          ),
        ),
        child: NavigationBar(
          // The bar is always visible; content scrolls beneath it via the
          // shell's inset (docs/Platform.md §4: content scrolls *under* chrome).
          height: 64,
          selectedIndex: current?.index ?? 0,
          onDestinationSelected: (index) => onSelect(NavDestination.all[index]),
          destinations: <Widget>[
            for (final destination in NavDestination.all)
              NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(
                  destination.selectedIcon,
                  color: hasSelection ? colors.brandPrimary : null,
                ),
                label: destinationLabel(destination),
              ),
          ],
        ),
      ),
    );
  }
}

/// Floating glass bar — the compact iOS layout (docs/Design.md §5.10).
class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.current,
    required this.onSelect,
    required this.destinationLabel,
  });

  final NavDestination? current;
  final ValueChanged<NavDestination> onSelect;
  final String Function(NavDestination) destinationLabel;

  @override
  Widget build(BuildContext context) {
    return FloatingGlassBar(
      child: Row(
        children: <Widget>[
          for (final destination in NavDestination.all)
            Expanded(
              child: _GlassNavItem(
                destination: destination,
                label: destinationLabel(destination),
                selected: destination == current,
                onTap: () => onSelect(destination),
              ),
            ),
        ],
      ),
    );
  }
}

/// One item inside the glass bar: icon over label, with a subtle brand tint
/// behind the active one.
class _GlassNavItem extends StatelessWidget {
  const _GlassNavItem({
    required this.destination,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 24,
                color: selected ? colors.brandPrimary : colors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: selected ? colors.brandPrimary : colors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// M3 `NavigationRail` — the medium layout, for every platform.
class _NavRail extends StatelessWidget {
  const _NavRail({
    required this.current,
    required this.onSelect,
    required this.destinationLabel,
  });

  final NavDestination? current;
  final ValueChanged<NavDestination> onSelect;
  final String Function(NavDestination) destinationLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return NavigationRailTheme(
      data: NavigationRailThemeData(
        backgroundColor: colors.surfaceRaised,
        indicatorColor: colors.brandSubtle,
        // `onBrandSubtle`, not `brandPrimary`: the indicator is a `brandSubtle`
        // fill, and `brandPrimary` on it measured 3.90:1 light / 3.43:1 dark —
        // below AA for a 13 px label (Roadmap §K.1-2).
        selectedIconTheme: IconThemeData(color: colors.onBrandSubtle),
        unselectedIconTheme: IconThemeData(color: colors.textSecondary),
        selectedLabelTextStyle: Theme.of(context).textTheme.labelMedium
            ?.copyWith(
              color: colors.onBrandSubtle,
              fontWeight: FontWeight.w600,
            ),
        unselectedLabelTextStyle: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: colors.textSecondary),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          right: false,
          child: NavigationRail(
            // Labels always visible: an icon-only rail is a guessing game, and
            // Design.md §5.10 says the label stays visible.
            labelType: NavigationRailLabelType.all,
            selectedIndex: current?.index,
            onDestinationSelected: (index) =>
                onSelect(NavDestination.all[index]),
            destinations: <NavigationRailDestination>[
              for (final destination in NavDestination.all)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: Text(destinationLabel(destination)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The expanded / large layout: a labelled sidebar (docs/Platform.md §3,
/// "`NavigationRail` (medium) → sidebar drawer (expanded)").
class _NavSidebar extends StatelessWidget {
  const _NavSidebar({
    required this.current,
    required this.onSelect,
    required this.destinationLabel,
  });

  final NavDestination? current;
  final ValueChanged<NavDestination> onSelect;
  final String Function(NavDestination) destinationLabel;

  /// Fixed width — a sidebar that resizes with the window makes the content
  /// pane jump (docs/Design.md §6 two-pane split).
  static const double width = 240;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          border: Border(right: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Text(
                  'Ledgerly',
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final destination in NavDestination.all)
                _SidebarItem(
                  destination: destination,
                  label: destinationLabel(destination),
                  selected: destination == current,
                  onTap: () => onSelect(destination),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// One sidebar row: a rounded, brand-tinted bar when selected.
class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? colors.brandSubtle : Colors.transparent,
          borderRadius: AppRadius.borderMd,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.borderMd,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 22,
                    color: selected
                        ? colors.onBrandSubtle
                        : colors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: selected
                            ? colors.onBrandSubtle
                            : colors.textPrimary,
                        fontWeight: selected ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The route a destination navigates to, re-exported for the shell.
///
/// Keeps `AppRoutes` out of the shell's imports so the shell deals only in
/// destinations.
const String defaultNavRoute = AppRoutes.calendar;
