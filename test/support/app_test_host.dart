import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
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
/// [size] supplies `MediaQuery.size`. That is enough for a widget that only
/// *branches* on the size class (a nav bar choosing bar/rail/sidebar), because
/// such a widget reads `MediaQuery` and never measures itself. It is **not**
/// enough for a test that calls `tester.getSize` on a child which shrinks to fit
/// — `MediaQuery` provides data, not constraints, so the render tree still lays
/// out against the 800×600 test window. Use [pumpAppHost] when the assertion is
/// about measured geometry.
Widget appTestHost({
  required Widget home,
  Size? size,
  Locale locale = const Locale('en'),
  AppPlatform? platform,
  Brightness brightness = Brightness.light,
  TextScaler? textScaler,
  List<Override> overrides = const <Override>[],
}) {
  final mediaQuery = MediaQueryData(
    size: size ?? const Size(800, 600),
    textScaler: textScaler ?? TextScaler.noScaling,
  );

  Widget app = MaterialApp(
    locale: locale,
    supportedLocales: const <Locale>[Locale('en'), Locale('my'), Locale('ja')],
    localizationsDelegates: const <LocalizationsDelegate<Object?>>[
      ...GlobalMaterialLocalizations.delegates,
      AppLocalizations.delegate,
    ],
    home: MediaQuery(
      data: mediaQuery,
      child: AppTestScopes(
        platform: platform,
        brightness: brightness,
        child: home,
      ),
    ),
  );

  if (overrides.isNotEmpty) {
    app = ProviderScope(overrides: overrides, child: app);
  }
  return app;
}

/// Pumps [appTestHost] with the **real** surface resized to [size].
///
/// `appTestHost` alone only overrides `MediaQuery.size`; the layout still runs
/// against `tester.view`'s 800×600. A widget that branches on the size class
/// does not care, but one that is measured — a `ConstrainedPane` inside an
/// `Align` is as wide as its parent, so `tester.getSize` reports the window, not
/// the width the test asked for — does. This resizes the view so `MediaQuery`
/// and the constraints agree, which is what a real device does.
///
/// The view is restored by `addTearDown`, so a test can call this repeatedly
/// (e.g. walking `TestWidths.all`) without leaking a size into the next case.
Future<void> pumpAppHost(
  WidgetTester tester, {
  required Widget home,
  Size size = const Size(800, 600),
  Locale locale = const Locale('en'),
  AppPlatform? platform,
  Brightness brightness = Brightness.light,
  TextScaler? textScaler,
  List<Override> overrides = const <Override>[],
}) async {
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
      home: home,
      size: size,
      locale: locale,
      platform: platform,
      brightness: brightness,
      textScaler: textScaler,
      overrides: overrides,
    ),
  );
}
