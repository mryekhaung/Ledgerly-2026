import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/app.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/router/app_router.dart';
import 'package:ledgerly/core/platform/adaptive_style.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/platform/window_size.dart';
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

    testWidgets('should_show_phase_zero_scaffold_when_no_feature_exists',
        (tester) async {
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      expect(find.text('Phase 0 scaffold'), findsOneWidget);
    });

    testWidgets('should_apply_brand_primary_to_primary_buttons',
        (tester) async {
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      final scheme = Theme.of(context).colorScheme;

      // jade600 from docs/Design.md §2.1 — the light-mode brand primary.
      expect(scheme.primary, const Color(0xFF0E7C66));
    });

    testWidgets('should_use_light_theme_when_platform_is_light', (tester) async {
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      final theme = Theme.of(context);

      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFFFFFFF));
    });
  });

  group('routing', () {
    testWidgets('should_open_requested_destination_when_starting_on_insights',
        (tester) async {
      await tester.pumpWidget(hostApp(initialLocation: AppRoutes.insights));
      await tester.pumpAndSettle();

      expect(find.textContaining('navigation.insights'), findsOneWidget);
    });

    testWidgets('should_navigate_when_router_pushed_to_categories',
        (tester) async {
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      context.goNamed(AppRoutes.categoriesName);
      await tester.pumpAndSettle();

      expect(find.textContaining('navigation.categories'), findsOneWidget);
    });

    testWidgets('should_navigate_to_settings_when_router_pushed',
        (tester) async {
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      context.goNamed(AppRoutes.settingsName);
      await tester.pumpAndSettle();

      expect(find.textContaining('navigation.settings'), findsOneWidget);
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

    testWidgets('should_mark_ios_glass_capable_when_platform_is_ios',
        (tester) async {
      await tester.pumpWidget(hostApp(platform: AppPlatform.ios));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      final adaptive = AdaptiveStyle.of(context);

      expect(adaptive.platform, AppPlatform.ios);
      expect(adaptive.canUseGlass, isTrue);
    });

    testWidgets('should_disable_glass_when_platform_is_android',
        (tester) async {
      await tester.pumpWidget(hostApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);

      expect(AdaptiveStyle.of(context).canUseGlass, isFalse);
    });

    testWidgets('should_report_medium_size_class_at_default_test_surface',
        (tester) async {
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

    testWidgets('should_build_with_japanese_locale_when_forced', (tester) async {
      await tester.pumpWidget(hostApp(locale: const Locale('ja')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
