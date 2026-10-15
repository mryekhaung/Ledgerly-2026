import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/adaptive_style.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Wraps a widget subtree in the same scopes `lib/app/app.dart` installs.
///
/// Every page reaches for `AppThemeColors.of`, `AppStrings.of` and
/// `AdaptiveStyle.of`, and each of those **asserts** rather than silently
/// degrading when its scope is missing. A test that hosts a page under a bare
/// `MaterialApp` therefore fails with an assertion inside the very widget it is
/// trying to exercise — which is what happened when the whole suite first ran
/// in CI.
///
/// Rather than repeat the stack in a dozen `host()` helpers (and let one of them
/// drift out of sync with `app.dart` again), tests compose it from here. Keep
/// this in step with `LedgerlyApp.build`.
///
/// The light/dark token sets come from the real `AppColorsLight` /
/// `AppColorsDark`, so a test asserting on a colour sees the shipped palette.
class AppTestScopes extends StatelessWidget {
  /// Wraps [child] in the app's inherited scopes.
  const AppTestScopes({
    required this.child,
    this.platform,
    this.brightness = Brightness.light,
    super.key,
  });

  /// The subtree to host.
  final Widget child;

  /// Pins the platform the adaptive style resolves to. Null follows the host.
  final AppPlatform? platform;

  /// Which token set to expose. Light by default so colours are the light ones.
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    const lightColors = AppColorsLight();
    const darkColors = AppColorsDark();

    // `AppLocalizations.of` is non-nullable: it unwraps `Localizations.of`
    // with a `!`, so it *throws* rather than returning null when the host
    // `MaterialApp` was built without the app's delegates — which several
    // focused tests do, since they do not care about copy. Asking the base
    // `Localizations` lookup first is the only way to detect that case, and the
    // generated lookup then supplies the shipped strings rather than crashing
    // the whole subtree.
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(
          Localizations.maybeLocaleOf(context) ?? const Locale('en'),
        );

    return AdaptiveStyleScope(
      platformOverride: platform,
      child: AppStringsScope(
        lookup: AppStringLookup.of(l10n),
        child: AppThemeColors(
          colors: brightness == Brightness.dark ? darkColors : lightColors,
          child: child,
        ),
      ),
    );
  }
}

/// Builds a `MaterialApp` with the project's localization delegates and the
/// app's scopes already installed.
///
/// This is the one-line host most widget tests want: pass the widget under test
/// as `home` and it behaves like the real app.
///
/// The theme is the **shipped** `AppTheme.light()`/`dark()`, matching
/// `app.dart`, so a test asserting on a themed colour sees the real palette
/// rather than `MaterialApp`'s default one.
///
/// Two things here are load-bearing rather than cosmetic, and both were learned
/// from CI failures:
///
/// 1. The size/text-scale override lives in `MaterialApp.builder`, **not** as a
///    `MediaQuery` wrapping `home`. `builder` inserts its widget above the
///    `Navigator` but still *inside* the `MaterialApp`'s tight constraints, so
///    the page's `Scaffold` receives a bounded box. Wrapping `home` directly
///    does not: it replaces the constraint chain with one whose child is
///    measured loosely, so a page containing a scrollable fails immediately with
///    "Vertical viewport was given unbounded height" — a stack that points into
///    `material_ui` and reads like a page bug.
/// 2. `pumpAppHost` also resizes `tester.view`, because `MediaQuery` only
///    overrides *data*. A widget that measures itself (an `Align`-based
///    column, which is as wide as its parent) still lays out against the real
///    window and would report 800 regardless of the requested width.
///
/// Why the `StretchingOverscrollIndicator` shows up at all: the widget-test
/// binding reports `TargetPlatform.android` on desktop hosts, and with Material 3
/// the default `ScrollBehavior` wraps every vertical scrollable in one. That is
/// correct app behaviour — it just makes an unbounded parent fatal instead of
/// merely wrong-looking, which is how the wrapping bug above surfaced.
Widget appTestHost({
  required Widget home,
  Size? size,
  Locale locale = const Locale('en'),
  AppPlatform? platform,
  Brightness brightness = Brightness.light,
  TextScaler? textScaler,
  List<Override> overrides = const <Override>[],
  GoRouter? router,
}) {
  return ProviderScope(
    overrides: overrides,
    child: router == null
        ? MaterialApp(
            locale: locale,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            supportedLocales: const <Locale>[
              Locale('en'),
              Locale('my'),
              Locale('ja'),
            ],
            localizationsDelegates: const <LocalizationsDelegate<Object?>>[
              ...GlobalMaterialLocalizations.delegates,
              AppLocalizations.delegate,
            ],
            builder: (context, child) => _TestSurround(
              size: size,
              textScaler: textScaler,
              platform: platform,
              brightness: brightness,
              child: child,
            ),
            home: home,
          )
        // A page that navigates with `context.pushNamed` needs a router above
        // it; a bare `MaterialApp` has none, so the tap throws "No GoRouter
        // found in context" instead of exercising the page. Tests that assert on
        // a *navigation* pass a `router` and drop `home` (the router owns the
        // tree). `GoRouter` takes the same `builder`-position surround through
        // its own `builder`, so the scopes and the surface override still apply.
        : MaterialApp.router(
            locale: locale,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            supportedLocales: const <Locale>[
              Locale('en'),
              Locale('my'),
              Locale('ja'),
            ],
            localizationsDelegates: const <LocalizationsDelegate<Object?>>[
              ...GlobalMaterialLocalizations.delegates,
              AppLocalizations.delegate,
            ],
            routerConfig: router,
            builder: (context, child) => _TestSurround(
              size: size,
              textScaler: textScaler,
              platform: platform,
              brightness: brightness,
              child: child,
            ),
          ),
  );
}

/// The `MediaQuery` + scope wrapper both host shapes need.
///
/// Extracted so the `MaterialApp` and `MaterialApp.router` branches cannot
/// drift: the size/text-scale override must sit in the `builder` (inside the
/// app's tight constraints, above the `Navigator`) in both cases, and the same
/// scopes must wrap the pushed routes in both cases.
class _TestSurround extends StatelessWidget {
  const _TestSurround({
    required this.child,
    required this.size,
    required this.textScaler,
    required this.platform,
    required this.brightness,
  });

  final Widget? child;
  final Size? size;
  final TextScaler? textScaler;
  final AppPlatform? platform;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      size: size ?? MediaQuery.sizeOf(context),
      textScaler: textScaler ?? TextScaler.noScaling,
    ),
    child: AppTestScopes(
      platform: platform,
      brightness: brightness,
      child: child ?? const SizedBox.shrink(),
    ),
  );
}

/// Pumps [appTestHost] with the **real** surface resized to [size].
///
/// `appTestHost` alone only overrides `MediaQuery.size`; the layout still runs
/// against `tester.view`'s 800×600. A widget that branches on the size class
/// does not care, but one that is measured — an `Align`-based column is as wide
/// as its parent, so `tester.getSize` reports the window, not the width the test
/// asked for — does. This resizes the view so `MediaQuery` and the constraints
/// agree, which is what a real device does.
///
/// The view is restored by `addTearDown`, so a test can call this repeatedly
/// (e.g. walking `TestWidths.all`) without leaking a size into the next case.
///
/// Pass exactly one of [home] or [router]: [home] is the usual case, while
/// [router] is for a page that navigates with `context.pushNamed` — with no
/// router in the tree such a tap throws "No GoRouter found in context", so the
/// test would be measuring the missing router rather than the page.
Future<void> pumpAppHost(
  WidgetTester tester, {
  Widget? home,
  GoRouter? router,
  Size size = const Size(800, 600),
  Locale locale = const Locale('en'),
  AppPlatform? platform,
  Brightness brightness = Brightness.light,
  TextScaler? textScaler,
  List<Override> overrides = const <Override>[],
}) async {
  assert(
    (home == null) != (router == null),
    'pumpAppHost needs exactly one of `home` or `router`.',
  );
  final view = tester.view;
  final previousSize = view.physicalSize;
  final previousRatio = view.devicePixelRatio;
  addTearDown(() {
    view.physicalSize = previousSize;
    view.devicePixelRatio = previousRatio;
  });

  view.devicePixelRatio = 1;
  view.physicalSize = size;

  await tester.pumpWidget(
    appTestHost(
      home: home ?? const SizedBox.shrink(),
      router: router,
      size: size,
      locale: locale,
      platform: platform,
      brightness: brightness,
      textScaler: textScaler,
      overrides: overrides,
    ),
  );
}
