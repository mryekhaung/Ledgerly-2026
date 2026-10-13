import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/router/nav_destinations.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/widgets/app_nav/adaptive_nav.dart';
import 'package:ledgerly/core/widgets/glass/glass_surface.dart';
import 'package:ledgerly/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';

/// `AdaptiveNav` — the chrome every platform and size class gets.
///
/// The point of these tests is the **branch table** in `docs/Platform.md` §3:
/// the same widget must produce a bottom bar, a rail or a sidebar purely from
/// the width, and must never imitate glass off-iOS. Those are exactly the
/// decisions a screenshot cannot verify, because a wrong branch still renders
/// *something*.
void main() {
  /// Hosts [AdaptiveNav] at a given width with the app's scopes wired.
  ///
  /// The string lookup runs through the real generated delegate so the labels
  /// asserted below are the shipped translations, not stubs. [AppTestScopes]
  /// installs `AppThemeColors`/`AppStringsScope`/`AdaptiveStyleScope` exactly as
  /// `app.dart` does — `AdaptiveNav` asserts on all three.
  Widget host({
    required double width,
    AppPlatform platform = AppPlatform.android,
    NavDestination? current = NavDestination.calendar,
    ValueChanged<NavDestination>? onSelect,
  }) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<Object?>>[
          ...GlobalMaterialLocalizations.delegates,
          AppLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('en')],
        home: Builder(
          builder: (context) => MediaQuery(
            // A tall surface so nothing overflows; the nav is what is under test.
            data: MediaQuery.of(context).copyWith(size: Size(width, 900)),
            child: AppTestScopes(
              platform: platform,
              child: Scaffold(
                body: AdaptiveNav(
                  current: current,
                  onSelect: onSelect ?? (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('compact width', () {
    testWidgets('should_use_a_material_navigation_bar_on_android', (
      tester,
    ) async {
      await tester.pumpWidget(host(width: TestWidths.phone));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('should_never_use_glass_on_android', (tester) async {
      // docs/Platform.md §4: "Android/web: M3 surfaces — never imitate glass".
      await tester.pumpWidget(host(width: TestWidths.phone));
      await tester.pumpAndSettle();

      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('should_use_the_floating_glass_bar_on_ios', (tester) async {
      await tester.pumpWidget(
        host(width: TestWidths.phone, platform: AppPlatform.ios),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingGlassBar), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      // The blur is the actual glass implementation (docs/Platform.md §4:
      // ship the blur fallback first).
      expect(find.byType(BackdropFilter), findsWidgets);
    });

    testWidgets(
      'should_fall_back_to_a_solid_surface_when_transparency_is_reduced',
      (tester) async {
        // Reduce Transparency must degrade the glass to a solid surface — a
        // legibility requirement, not a nicety.
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(390, 900),
                  highContrast: true,
                ),
                child: AppTestScopes(
                  platform: AppPlatform.ios,
                  child: AdaptiveNav(
                    current: NavDestination.calendar,
                    onSelect: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // No blur at all: `canUseGlass` is false, so GlassSurface takes the solid
        // branch.
        expect(find.byType(BackdropFilter), findsNothing);
      },
    );

    testWidgets('should_show_every_destination_label', (tester) async {
      await tester.pumpWidget(host(width: TestWidths.phone));
      await tester.pumpAndSettle();

      // The English labels from the ARB, in destination order.
      const expected = <String>[
        'Calendar',
        'Insights',
        'Categories',
        'Settings',
      ];
      for (final label in expected) {
        expect(
          find.text(label),
          findsWidgets,
          reason: '$label must be reachable by name',
        );
      }
    });

    testWidgets('should_report_the_tapped_destination', (tester) async {
      final tapped = <NavDestination>[];
      await tester.pumpWidget(
        host(width: TestWidths.phone, onSelect: tapped.add, current: null),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(tapped, <NavDestination>[NavDestination.settings]);
    });

    testWidgets('should_mark_the_current_destination_as_selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(width: TestWidths.phone, current: NavDestination.categories),
      );
      await tester.pumpAndSettle();

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, NavDestination.categories.index);
    });

    testWidgets('should_select_nothing_when_the_route_is_not_a_destination', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

      await tester.pumpWidget(host(width: TestWidths.phone, current: null));
      await tester.pumpAndSettle();

      // `NavigationBar.selectedIndex` is a non-nullable `int`, so it can never
      // report "nothing selected" the way `NavigationRail.selectedIndex` (an
      // `int?`) can. The bar is driven by that index, so the honest assertion is
      // on what it *publishes*: no destination may be marked selected.
      final selected = <String>[];
      void collect(SemanticsNode node) {
        // `flagsCollection.isSelected` is a `Tristate` (none / isFalse / isTrue),
        // not a `bool` — the old `hasFlag(SemanticsFlag.isSelected)` helper was
        // deprecated after 3.32 in favour of this richer representation.
        if (node.flagsCollection.isSelected == Tristate.isTrue) {
          selected.add(node.label);
        }
        node.visitChildren((SemanticsNode child) {
          collect(child);
          return true;
        });
      }

      collect(tester.getSemantics(find.byType(NavigationBar)));
      expect(
        selected,
        isEmpty,
        reason: 'a route that is not a destination must not read as selected',
      );
    });
  });

  group('medium width', () {
    testWidgets('should_use_a_rail_and_not_a_bottom_bar', (tester) async {
      await tester.pumpWidget(host(width: TestWidths.tablet));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('should_keep_labels_visible_in_the_rail', (tester) async {
      await tester.pumpWidget(host(width: TestWidths.tablet));
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(
        rail.labelType,
        NavigationRailLabelType.all,
        reason: 'an icon-only rail is a guessing game (Design.md §5.10)',
      );
    });

    testWidgets('should_use_a_rail_on_ios_too', (tester) async {
      // Size class beats platform: an iPad in landscape is a rail, not a glass
      // bar (docs/Platform.md §2 rule 4).
      await tester.pumpWidget(
        host(width: TestWidths.tablet, platform: AppPlatform.ios),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(FloatingGlassBar), findsNothing);
    });
  });

  group('expanded width', () {
    testWidgets('should_use_a_sidebar_with_no_rail_or_bar', (tester) async {
      await tester.pumpWidget(host(width: TestWidths.desktop));
      await tester.pumpAndSettle();

      expect(find.text('Ledgerly'), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('should_show_every_destination_in_the_sidebar', (tester) async {
      await tester.pumpWidget(host(width: TestWidths.desktop));
      await tester.pumpAndSettle();

      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('should_navigate_from_the_sidebar_on_tap', (tester) async {
      final tapped = <NavDestination>[];
      await tester.pumpWidget(
        host(width: TestWidths.desktop, onSelect: tapped.add),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();

      expect(tapped, <NavDestination>[NavDestination.insights]);
    });
  });

  group('large width', () {
    testWidgets('should_use_the_sidebar_at_the_widest_breakpoint', (
      tester,
    ) async {
      await tester.pumpWidget(host(width: TestWidths.wide));
      await tester.pumpAndSettle();

      expect(find.text('Ledgerly'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}
