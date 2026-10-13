import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
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
/// [lightColors] / [darkColors] are the real token sets, so a test asserting on
/// a colour sees the shipped palette.
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

    return AdaptiveStyleScope(
      platformOverride: platform,
      child: Builder(
        // The inner `Builder` matters: `AppStringsScope` and `AppThemeColors`
        // need a context *below* `Localizations`, which the caller's
        // `MaterialApp` provides — reading it here keeps this widget usable
        // directly under `MaterialApp.home`.
        builder: (context) => AppStringsScope(
          lookup: AppStringLookup.of(AppLocalizations.of(context)),
          child: AppThemeColors(
            colors: brightness == Brightness.dark ? darkColors : lightColors,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Builds a `MaterialApp` with the project's localization delegates and the
/// app's scopes already installed.
///
/// This is the one-line host most widget tests want: pass the widget under test
/// as [home] (or [builder]) and it behaves like the real app.
///
/// [size] overrides `MediaQuery.size` so a test can exercise an exact
/// breakpoint without depending on the harness's 800×600 default.
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
