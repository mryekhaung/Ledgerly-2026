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
}
