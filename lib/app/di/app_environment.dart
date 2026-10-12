/// Build-time environment, chosen by the `--dart-define=FLAVOR=` flag or by the
/// Xcode/Gradle flavor (docs/Conventions.md §7: flavors `dev` / `prod`).
enum AppEnvironment {
  /// Local development — verbose logging, no real backend.
  dev,

  /// Production — no debug logging, real backend adapters.
  prod;

  /// True when this is the development environment.
  bool get isDev => this == AppEnvironment.dev;

  /// True when debug-only tooling (Dio logger, inspector) may be attached.
  bool get allowsDebugTooling => isDev;

  /// Reads the flavor from `--dart-define=FLAVOR=prod`, defaulting to [dev].
  ///
  /// Defaulting to dev means a plain `flutter run` is always safe: it can never
  /// accidentally point at production data.
  static AppEnvironment fromDartDefine() {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    return switch (flavor) {
      'prod' => AppEnvironment.prod,
      _ => AppEnvironment.dev,
    };
  }

  /// Optional startup route, from `--dart-define=INITIAL_ROUTE=/settings`.
  ///
  /// Dev-only tooling: the app has no bottom navigation yet (`AdaptiveNav` is a
  /// pending Phase 0 item), so a screen that is not the calendar — Settings,
  /// for one — cannot be reached by tapping. This lets a build open directly on
  /// such a screen for manual verification.
  ///
  /// Returns null when unset, which means "use the default route". In [prod] it
  /// is ignored outright: a shipped build must never start anywhere but the
  /// calendar, whatever the build flags say.
  static String? initialRouteFromDartDefine() {
    const route = String.fromEnvironment('INITIAL_ROUTE');
    if (route.isEmpty) return null;
    if (fromDartDefine() != AppEnvironment.dev) return null;
    return route;
  }
}
