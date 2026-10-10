import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:material_ui/material_ui.dart';

/// The adaptive context every design-system component reads: platform, size
/// class, and accessibility flags (docs/Platform.md §2).
///
/// **Pages/features never branch on platform.** They consume design-system
/// widgets; only `core/widgets` reads this. `AdaptiveStyle.of(context)` is the
/// sanctioned way for those components to decide which implementation to render.
class AdaptiveStyle extends InheritedWidget {
  /// Creates the adaptive context. Prefer [AdaptiveStyleScope] which resolves
  /// the values from [MediaQuery] for you.
  const AdaptiveStyle({
    required this.platform,
    required this.sizeClass,
    required this.reduceTransparency,
    required this.reduceMotion,
    required this.boldText,
    required super.child,
    super.key,
  });

  /// The host platform.
  final AppPlatform platform;

  /// The current window size class.
  final WindowSizeClass sizeClass;

  /// True when the OS asks us to reduce transparency. Glass falls back to a
  /// solid surface — this is not optional (docs/Platform.md §4).
  final bool reduceTransparency;

  /// True when the OS asks for reduced motion. Collapse durations to zero.
  final bool reduceMotion;

  /// True when bold text is enabled — weight 500 becomes 600 in some styles.
  final bool boldText;

  /// True when iOS Liquid Glass chrome may be used.
  bool get canUseGlass => platform.usesLiquidGlass && !reduceTransparency;

  /// Reads the nearest [AdaptiveStyle], falling back to a sensible,
  /// non-platform-specific default when absent (goldens, isolated previews).
  static AdaptiveStyle of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AdaptiveStyle>();
    return result ?? const AdaptiveStyle.fallback();
  }

  /// A conservative default: material chrome, compact, no transparency
  /// reduction. Used only when no ancestor scope exists.
  const AdaptiveStyle.fallback({super.key})
    : platform = AppPlatform.android,
      sizeClass = WindowSizeClass.compact,
      reduceTransparency = false,
      reduceMotion = false,
      boldText = false,
      super(child: const SizedBox.shrink());

  @override
  bool updateShouldNotify(AdaptiveStyle oldWidget) =>
      oldWidget.platform != platform ||
      oldWidget.sizeClass != sizeClass ||
      oldWidget.reduceTransparency != reduceTransparency ||
      oldWidget.reduceMotion != reduceMotion ||
      oldWidget.boldText != boldText;
}

/// Resolves platform + window size class + accessibility flags from [MediaQuery]
/// and provides them to the subtree.
///
/// Mount this once, above the router, in `app/app.dart`.
class AdaptiveStyleScope extends StatelessWidget {
  /// Wraps [child] with resolved adaptive values.
  const AdaptiveStyleScope({
    required this.child,
    this.platformOverride,
    super.key,
  });

  /// The subtree that can read [AdaptiveStyle].
  final Widget child;

  /// Forces a platform — used by golden tests to render iOS and Android chrome
  /// from a single host.
  final AppPlatform? platformOverride;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return AdaptiveStyle(
      platform: AppPlatform.resolve(override: platformOverride),
      sizeClass: WindowSizeClass.fromWidth(mediaQuery.size.width),
      reduceTransparency: mediaQuery.highContrast,
      reduceMotion: mediaQuery.disableAnimations,
      boldText: mediaQuery.boldText,
      child: child,
    );
  }
}
