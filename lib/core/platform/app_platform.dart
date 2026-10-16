import 'package:flutter/foundation.dart';

/// The host platform, resolved once and never re-guessed.
///
/// Web is checked **first** so a browser on an iPhone reports web, not ios
/// (docs/Platform.md §2).
enum AppPlatform {
  ios,
  android,
  web;

  /// Resolves the current platform.
  ///
  /// Pass [override] in tests to avoid depending on the test host.
  static AppPlatform resolve({AppPlatform? override}) {
    if (override != null) return override;
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => AppPlatform.ios,
      TargetPlatform.android => AppPlatform.android,
      // Desktop and anything unknown get the Material treatment.
      _ => AppPlatform.android,
    };
  }

  /// True when the platform should use native Cupertino interaction patterns.
  bool get usesCupertino => this == AppPlatform.ios;

  /// True when Material 3 chrome applies.
  bool get usesMaterial => this != AppPlatform.ios;
}
