import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
// `AdaptiveBottomNavigationBar.cupertinoTabBar` is typed to Flutter's widget.
import 'package:flutter/cupertino.dart'
    as flutter_cupertino
    show BottomNavigationBarItem, CupertinoTabBar;
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/router/nav_destinations.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/adaptive_style.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:material_ui/material_ui.dart';

/// The app's primary navigation chrome (docs/Platform.md §3).
///
/// Pages never build this and never branch on platform — the shell mounts it
/// once and it renders the right thing for the current platform **and** size
/// class:
///
/// | Platform | compact | medium | expanded / large |
/// |---|---|---|---|
/// | iOS | native adaptive tab bar | rail | sidebar |
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

    // Compact iOS uses the platform's Cupertino tab bar. AppShell passes the
    // adaptive configuration below to AdaptiveScaffold, which upgrades it to
    // the native iOS 26 tab bar when available.
    if (adaptive.platform.usesCupertino) {
      return _cupertinoNavBar(
        context: context,
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

  /// Builds the package configuration used by AppShell's compact scaffold.
  AdaptiveBottomNavigationBar bottomNavigationBar(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);

    return AdaptiveBottomNavigationBar(
      items: <AdaptiveNavigationDestination>[
        for (final destination in NavDestination.all)
          AdaptiveNavigationDestination(
            icon: _symbolFor(destination, selected: false),
            selectedIcon: _symbolFor(destination, selected: true),
            label: destination.label(strings),
          ),
      ],
      selectedIndex: current?.index ?? 0,
      onTap: (index) => onSelect(NavDestination.all[index]),
      useNativeBottomBar: true,
      cupertinoTabBar: _cupertinoNavBar(
        context: context,
        current: current,
        onSelect: onSelect,
        destinationLabel: (destination) => destination.label(strings),
      ),
      bottomNavigationBar: _MaterialNavBar(
        current: current,
        onSelect: onSelect,
        destinationLabel: (destination) => destination.label(strings),
      ),
      selectedItemColor: colors.brandPrimary,
      unselectedItemColor: colors.textSecondary,
    );
  }

  /// Adds scroll clearance for iOS 26's overlay tab bar.
  Widget adaptiveScaffoldBody(BuildContext context, Widget child) {
    if (!PlatformInfo.isIOS26OrHigher()) {
      // Android: `Scaffold` already removes the bottom padding for its body.
      if (!PlatformInfo.isIOS) return child;

      // iOS < 26: the package docks a `CupertinoTabBar` in a `Column` below the
      // body, and `CupertinoPageScaffold` (unlike `CupertinoTabScaffold`) does
      // not consume the bottom safe area. The tab bar pads itself for the home
      // indicator, so without this every page adds that inset a second time as
      // a dead band above the bar.
      return MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: child,
      );
    }

    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        padding: mediaQuery.padding.copyWith(
          bottom: mediaQuery.padding.bottom + _nativeTabBarContentInset,
        ),
        viewPadding: mediaQuery.viewPadding.copyWith(
          bottom: mediaQuery.viewPadding.bottom + _nativeTabBarContentInset,
        ),
      ),
      child: child,
    );
  }

  static const double _nativeTabBarContentInset = 64;

  static String _symbolFor(
    NavDestination destination, {
    required bool selected,
  }) => switch (destination) {
    NavDestination.calendar => 'calendar',
    NavDestination.insights => selected ? 'chart.pie.fill' : 'chart.pie',
    NavDestination.categories =>
      selected ? 'square.grid.2x2.fill' : 'square.grid.2x2',
    NavDestination.settings => selected ? 'gearshape.fill' : 'gearshape',
  };

  flutter_cupertino.CupertinoTabBar _cupertinoNavBar({
    required BuildContext context,
    required NavDestination? current,
    required ValueChanged<NavDestination> onSelect,
    required String Function(NavDestination) destinationLabel,
  }) {
    final colors = AppThemeColors.of(context);
    return flutter_cupertino.CupertinoTabBar(
      currentIndex: current?.index ?? 0,
      onTap: (index) => onSelect(NavDestination.all[index]),
      backgroundColor: colors.surfaceRaised,
      activeColor: colors.brandPrimary,
      inactiveColor: colors.textSecondary,
      height: 50,
      iconSize: 24,
      border: Border(top: BorderSide(color: colors.border, width: 0.5)),
      items: <flutter_cupertino.BottomNavigationBarItem>[
        for (final destination in NavDestination.all)
          flutter_cupertino.BottomNavigationBarItem(
            icon: Icon(destination.icon),
            activeIcon: Icon(destination.selectedIcon),
            label: destinationLabel(destination),
          ),
      ],
    );
  }
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

    // Merge into the app theme rather than replacing it: a bare
    // `NavigationBarTheme(data: …)` discards the inherited `navigationBarTheme`,
    // so the bar fell back to M3's default elevation instead of the app's flat
    // tint-and-hairline surface (docs/Design.md §4.3).
    final base = Theme.of(context).navigationBarTheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    // M3 paints the active icon and label in the on-colour of the indicator.
    // That is `onBrandSubtle` (>= 4.5:1 on `brandSubtle`); `brandPrimary` on the
    // pill measured 3.90:1 light / 3.43:1 dark — below AA (Roadmap §K.1-2). It is
    // the same pairing the rail and sidebar already use.
    bool isSelected(Set<WidgetState> states) =>
        hasSelection && states.contains(WidgetState.selected);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: NavigationBarTheme(
            data: base.copyWith(
              indicatorColor: hasSelection
                  ? colors.brandSubtle
                  : Colors.transparent,
              backgroundColor: colors.surfaceRaised,
              elevation: base.elevation ?? 0,
              iconTheme: WidgetStateProperty.resolveWith(
                (states) => IconThemeData(
                  color: isSelected(states)
                      ? colors.onBrandSubtle
                      : colors.textSecondary,
                ),
              ),
              labelTextStyle: WidgetStateProperty.resolveWith(
                (states) => labelStyle?.copyWith(
                  color: isSelected(states)
                      ? colors.onBrandSubtle
                      : colors.textSecondary,
                  fontWeight: isSelected(states) ? FontWeight.w600 : null,
                ),
              ),
            ),
            child: NavigationBar(
              height: 64,
              selectedIndex: current?.index ?? 0,
              onDestinationSelected: (index) =>
                  onSelect(NavDestination.all[index]),
              destinations: <Widget>[
                for (final destination in NavDestination.all)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destinationLabel(destination),
                  ),
              ],
            ),
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
