import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveToolbarHost;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/app.dart';
import 'package:ledgerly/app/router/app_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/router/nav_destinations.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/core/platform/adaptive_style.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/widgets/app_nav/adaptive_nav.dart';
import 'package:ledgerly/features/categories/presentation/pages/category_list_page.dart';
import 'package:ledgerly/features/insights/presentation/pages/insights_page.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/pages/settings_page.dart';
import 'package:ledgerly/features/transactions/presentation/pages/calendar_page.dart';
import 'package:material_ui/material_ui.dart';

/// Boot tests for the Phase 0 shell.
///
/// These assert the app starts, the token layer resolves, and navigation between
/// the placeholder destinations works — the contract the router and theme must
/// uphold before any feature is built.
void main() {
  Widget hostApp({
    AppPlatform platform = AppPlatform.android,
    String initialLocation = AppRoutes.calendar,
    Locale? locale,
  }) {
    return ProviderScope(
      child: LedgerlyApp(
        router: createRouter(initialLocation: initialLocation),
        platformOverride: platform,
        locale: locale,
        // The app reads theme/locale from the settings stream, which needs the
        // get_it locator — not configured in a widget test. Passing an explicit
        // snapshot keeps this a pure boot test of the shell.
        settingsOverride: AppSettings.defaults,
      ),
    );
  }

  group('boot', () {
    testWidgets('should_render_without_error_when_app_starts', (tester) async {
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should_show_primary_navigation_when_app_boots', (
      tester,
    ) async {
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      // The shell now mounts real chrome rather than a bare passthrough.
      expect(find.byType(AdaptiveNav), findsOneWidget);
    });

    testWidgets('should_install_adaptive_toolbar_host_around_router', (
      tester,
    ) async {
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      expect(find.byType(AdaptiveToolbarHost), findsOneWidget);
    });

    testWidgets('should_apply_brand_primary_to_primary_buttons', (
      tester,
    ) async {
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      final scheme = Theme.of(context).colorScheme;

      // jade600 from docs/Design.md §2.1 — the light-mode brand primary.
      expect(scheme.primary, const Color(0xFF0E7C66));
    });

    testWidgets('should_use_light_theme_when_platform_is_light', (
      tester,
    ) async {
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      final theme = Theme.of(context);

      expect(theme.brightness, Brightness.light);
      // The page is the `surface` token, not white: light mode separates a card
      // from the page behind it by lowering the page, because white is the
      // brightest value the mode has (docs/Design.md §2.7). Pinning white here
      // is what let the invisible card ship — the two were the same colour.
      expect(theme.scaffoldBackgroundColor, const AppColorsLight().surface);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF5F7FA));
    });

    testWidgets('should_let_a_card_lift_off_the_page_in_light_mode', (
      tester,
    ) async {
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      final scheme = Theme.of(context).colorScheme;

      // End-to-end check that the §L ramp reaches the running app and not just
      // the token layer: the card surface must actually differ from the page.
      expect(
        scheme.surfaceContainerHigh,
        isNot(scheme.surface),
        reason:
            'a card the same colour as the page is not a card — this was '
            '1.00:1 before §L',
      );
    });
  });

  group('routing', () {
    // The destinations used to be placeholder text keyed by `navigation.*`.
    // Calendar, Categories and Settings are real pages now, so these assert on
    // the page type and the destination's own label instead of a placeholder
    // string that no longer exists.
    testWidgets('should_open_calendar_when_router_starts_at_root', (
      tester,
    ) async {
      await tester.pumpWidget(hostApp(initialLocation: AppRoutes.calendar));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarPage), findsOneWidget);
    });

    testWidgets('should_open_requested_destination_when_starting_on_insights', (
      tester,
    ) async {
      await tester.pumpWidget(hostApp(initialLocation: AppRoutes.insights));
      await tester.pumpAndSettle();

      expect(find.byType(InsightsPage), findsOneWidget);
    });

    testWidgets('should_navigate_when_router_pushed_to_categories', (
      tester,
    ) async {
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      GoRouter.of(context).goNamed(AppRoutes.categoriesName);
      await tester.pumpAndSettle();

      expect(find.byType(CategoryListPage), findsOneWidget);
    });

    testWidgets('should_navigate_to_settings_when_router_pushed', (
      tester,
    ) async {
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      GoRouter.of(context).goNamed(AppRoutes.settingsName);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('should_follow_the_route_when_a_nav_destination_is_selected', (
      tester,
    ) async {
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      expect(find.byType(CalendarPage), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Selecting a destination must both navigate and move the active state.
      expect(find.byType(SettingsPage), findsOneWidget);
      final nav = tester.widget<AdaptiveNav>(find.byType(AdaptiveNav));
      expect(nav.current, NavDestination.settings);
    });
  });

  group('adaptive context', () {
    testWidgets('should_provide_adaptive_style_when_app_boots', (tester) async {
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      final adaptive = AdaptiveStyle.of(context);

      expect(adaptive.platform, AppPlatform.android);
      expect(adaptive.reduceTransparency, isFalse);
    });

    testWidgets('should_mark_ios_as_cupertino_when_platform_is_ios', (
      tester,
    ) async {
      await tester.pumpWidget(hostApp(platform: AppPlatform.ios));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      final adaptive = AdaptiveStyle.of(context);

      expect(adaptive.platform, AppPlatform.ios);
      expect(adaptive.platform.usesCupertino, isTrue);
    });

    testWidgets('should_use_material_interactions_when_platform_is_android', (
      tester,
    ) async {
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);

      expect(AdaptiveStyle.of(context).platform.usesCupertino, isFalse);
    });

    testWidgets('should_report_medium_size_class_at_default_test_surface', (
      tester,
    ) async {
      // The default flutter_test surface is 800x600 logical px.
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);

      expect(
        AdaptiveStyle.of(context).sizeClass,
        WindowSizeClass.fromWidth(800),
      );
    });
  });

  group('localization', () {
    testWidgets('should_build_with_myanmar_locale_when_forced', (tester) async {
      await tester.pumpWidget(hostApp(locale: const Locale('my')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('should_build_with_japanese_locale_when_forced', (
      tester,
    ) async {
      await tester.pumpWidget(hostApp(locale: const Locale('ja')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
