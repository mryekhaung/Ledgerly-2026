import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_router.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/adaptive_style.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/l10n/app_localization.dart';
import 'package:ledgerly/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The root widget: theme + locale + adaptive context + router.
///
/// Kept deliberately thin. It resolves the mode, locale and platform context and
/// hands off to the router — no business logic, no feature knowledge
/// (`docs/Agent.md` §3.3).
///
/// A [ConsumerWidget] so it can follow the stored preferences: `themeMode` and
/// `locale` come from `SettingsProvider`, which watches the Drift settings
/// stream — that is what makes a change in Settings repaint the whole app with no
/// restart and no navigation away (`docs/Architecture.md` §5, §7).
class LedgerlyApp extends ConsumerWidget {
  /// Creates the app.
  ///
  /// [router] and [platformOverride] are injectable so widget and golden tests
  /// can drive specific routes and platforms from a single host.
  ///
  /// [settingsOverride] forces settings for tests — a golden of the dark theme
  /// should not have to write to a database first. When it is null the stored
  /// preferences are used.
  const LedgerlyApp({
    this.router,
    this.platformOverride,
    this.locale,
    this.settingsOverride,
    super.key,
  });

  /// Router override for tests. Defaults to [createRouter].
  final GoRouter? router;

  /// Forces a platform so goldens can render iOS and Android chrome.
  final AppPlatform? platformOverride;

  /// Forces a locale for tests, bypassing the stored language preference.
  final Locale? locale;

  /// Forces a settings snapshot for tests, bypassing the database read.
  final AppSettings? settingsOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The token sets are const, so light/dark switch without rebuilding the palette.
    const lightColors = AppColorsLight();
    const darkColors = AppColorsDark();

    // `settingsOverride` wins so a test never opens the database; otherwise the
    // stream's current value, and — before its first emission lands — the
    // defaults, so the very first frame is themed rather than blank.
    //
    // The explicit type is required, not cosmetic: `a ?? b` takes its static type
    // from `a`, so `settingsOverride` being `AppSettings?` would make the whole
    // expression nullable and force `?.` on a value that is never null.
    final AppSettings settings =
        settingsOverride ?? ref.watch(currentSettingsProvider);

    // An explicit test locale wins; then the stored preference; a null stored
    // preference is the documented "follow the device" state and must stay null
    // so `MaterialApp` resolves it from the platform.
    final resolvedLocale = locale ?? _localeFromCode(settings.localeCode);

    // The active brightness also drives the token set below, so the widget-slot
    // colours and Material's scheme can never disagree about the mode.
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final effectiveBrightness = switch (settings.themeMode) {
      AppThemeMode.light => Brightness.light,
      AppThemeMode.dark => Brightness.dark,
      AppThemeMode.system => platformBrightness,
    };

    return MaterialApp.router(
      title: 'Ledgerly',
      debugShowCheckedModeBanner: false,
      routerConfig: router ?? createRouter(),

      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeModeOf(settings.themeMode),

      locale: resolvedLocale,
      supportedLocales: AppLocalization.supportedLocales
          .map(Locale.new)
          .toList(growable: false),
      // Flutter's Material/Cupertino/Widgets strings for en/my/ja first, then
      // our own ARB delegate so `AppLocalizations.of` resolves. The generated
      // delegate is also the source of the strings AppStringsScope hands to
      // the widget tree.
      //
      // The element type must be `LocalizationsDelegate<Object?>`: our delegate
      // is `LocalizationsDelegate<AppLocalizations>` while Flutter's built-ins
      // are `LocalizationsDelegate<dynamic>`, so neither `<Object>` nor
      // `<dynamic>` accepts both. `Object?` is the common supertype that does.
      localizationsDelegates: const <LocalizationsDelegate<Object?>>[
        ...GlobalMaterialLocalizations.delegates,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],

      // Re-wrap here so AdaptiveStyle is available *below* MediaQuery.
      // AppStringsScope wraps the generated bindings so a runtime ARB key
      // (e.g. one carried out of a ValidationFailure) resolves the same way a
      // compile-time key does.
      //
      // `platformBrightness` is pinned to the *resolved* app brightness for the
      // whole tree. `adaptive_platform_ui`, `CupertinoPageScaffold`, native
      // platform views and `CupertinoColors.resolveFrom` all read the device
      // setting from `MediaQuery`; without this, a pinned light/dark choice
      // only held for the shell and every pushed page followed the device.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(platformBrightness: effectiveBrightness),
        child: AdaptiveStyleScope(
          platformOverride: platformOverride,
          child: AppStringsScope(
            lookup: AppStringLookup.of(AppLocalizations.of(context)),
            child: AppThemeColors(
              // `effectiveBrightness` rather than reading MediaQuery again: this
              // is what makes an explicit light/dark choice recolour the custom
              // tokens too, instead of only Material's own scheme.
              colors: effectiveBrightness == Brightness.dark
                  ? darkColors
                  : lightColors,
              // Declarative edge-to-edge bar style: dark icons on light
              // surfaces and vice versa. `AnnotatedRegion` (not a
              // `SystemChrome.set…` call in `build`) so theme switches apply
              // without a side effect, and pages without an `AppBar` are
              // covered too (`docs/Platform.md` §2).
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: AppTheme.systemOverlayStyle(effectiveBrightness),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Maps a stored BCP-47 tag to a [Locale], or null to follow the device.
  ///
  /// A tag we do not ship resolves to null rather than to a `Locale` the app has
  /// no translations for: Flutter would then fall back to English *from a
  /// specific locale*, whereas null lets it use the device locale — which may be
  /// one we do support. Guarding here also keeps a hand-edited database from
  /// pinning the UI to a locale with no ARB.
  static Locale? _localeFromCode(String? code) {
    if (code == null) return null;
    return AppLocalization.supportedLocales.contains(code)
        ? Locale(code)
        : null;
  }

  /// Maps the domain enum onto Flutter's `ThemeMode`.
  ///
  /// The single place the two meet — `domain/` must not import Flutter
  /// (`docs/Agent.md` §3.1).
  static ThemeMode _themeModeOf(AppThemeMode mode) => switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}
