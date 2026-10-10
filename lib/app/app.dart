import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_router.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/adaptive_style.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/l10n/app_localization.dart';
import 'package:material_ui/material_ui.dart';

/// The root widget: theme + locale + adaptive context + router.
///
/// Kept deliberately thin. It resolves the mode, locale and platform context and
/// hands off to the router — no business logic, no feature knowledge
/// (docs/Agent.md §3.3).
class LedgerlyApp extends StatefulWidget {
  /// Creates the app.
  ///
  /// [router] and [platformOverride] are injectable so widget and golden tests
  /// can drive specific routes and platforms from a single host.
  const LedgerlyApp({
    this.router,
    this.platformOverride,
    this.locale,
    super.key,
  });

  /// Router override for tests. Defaults to [createRouter].
  final GoRouter? router;

  /// Forces a platform so goldens can render iOS and Android chrome.
  final AppPlatform? platformOverride;

  /// Forces a locale for tests. Null follows the device.
  final Locale? locale;

  @override
  State<LedgerlyApp> createState() => _LedgerlyAppState();
}

class _LedgerlyAppState extends State<LedgerlyApp> {
  late final GoRouter _router = widget.router ?? createRouter();

  @override
  Widget build(BuildContext context) {
    // The token sets are const, so light/dark switch without rebuilding the palette.
    const lightColors = AppColorsLight();
    const darkColors = AppColorsDark();

    return _ThemeProvider(
      lightColors: lightColors,
      darkColors: darkColors,
      builder: (context, activeColors) => MaterialApp.router(
        title: 'Ledgerly',
        debugShowCheckedModeBanner: false,
        routerConfig: _router,

        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,

        locale: widget.locale,
        supportedLocales: AppLocalization.supportedLocales
            .map(Locale.new)
            .toList(growable: false),

        // Re-wrap here so AdaptiveStyle is available *below* MediaQuery
        // (MaterialApp provides Localizations for us). When the ARB bindings are
        // generated, `localizationsDelegates: AppLocalizations.localizationsDelegates`
        // is added alongside `supportedLocales` above.
        builder: (context, child) => AdaptiveStyleScope(
          platformOverride: widget.platformOverride,
          child: AppThemeColors(
            colors: activeColors,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

/// Resolves the active [AppColors] for the current brightness and passes it down
/// through the [builder].
///
/// `ThemeMode.system` is honoured here so a widget-slot style can pick the
/// matching token set at the same time as Material's own scheme.
class _ThemeProvider extends StatelessWidget {
  const _ThemeProvider({
    required this.lightColors,
    required this.darkColors,
    required this.builder,
  });

  final AppColors lightColors;
  final AppColors darkColors;
  final Widget Function(BuildContext context, AppColors colors) builder;

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final colors = brightness == Brightness.dark ? darkColors : lightColors;
    return builder(context, colors);
  }
}
