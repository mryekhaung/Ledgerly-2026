import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:material_ui/material_ui.dart';

/// Builds the app's [ThemeData] for light and dark from the design tokens.
///
/// This is the **only** place a `ColorScheme` is constructed. Widgets read tokens
/// through `AppTheme.of(context).colors` rather than `Theme.of(context)` so that
/// semantic names (moneyIn, surfaceSunken…) are available alongside Material's.
///
/// See docs/Design.md §2-§4, docs/Platform.md §3.
abstract final class AppTheme {
  const AppTheme._();

  /// Light theme.
  ///
  /// [platform] selects the platform-adaptive chrome (docs/Platform.md §2). It is
  /// injectable so a golden test can render iOS chrome on a Linux runner; when it
  /// is null the host is resolved once via [AppPlatform.resolve].
  static ThemeData light({AppPlatform? platform}) => _build(
    const AppColorsLight(),
    Brightness.light,
    platform ?? AppPlatform.resolve(),
  );

  /// Dark theme. See [light] for [platform].
  static ThemeData dark({AppPlatform? platform}) => _build(
    const AppColorsDark(),
    Brightness.dark,
    platform ?? AppPlatform.resolve(),
  );

  static ThemeData _build(
    AppColors colors,
    Brightness brightness,
    AppPlatform platform,
  ) {
    final colorScheme = _colorScheme(colors, brightness);
    final textTheme = AppTypography.textTheme(colors);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.surface,
      canvasColor: colors.surface,
      dividerColor: colors.border,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      // A Material ink ripple is Android chrome. Applying it globally puts an
      // Android ripple on iOS, which is exactly the "skinned, not native" trap
      // docs/Design.md §1 forbids and §5.2 calls out ("never a ripple on iOS").
      // iOS gets the Cupertino press treatment instead (docs/Platform.md §2).
      splashFactory: platform.usesMaterial
          ? InkSparkle.splashFactory
          : NoSplash.splashFactory,
      visualDensity: VisualDensity.standard,

      // Cards: we prefer tint + hairline to elevation (docs/Design.md §4.3).
      cardTheme: CardThemeData(
        color: colors.surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      ),

      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),

      // Buttons: primary = brandPrimary fill, height 52, pill
      // (docs/Design.md §5.7).
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.brandPrimary,
          foregroundColor: colors.textOnBrand,
          minimumSize: const Size(0, 52),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderFull,
          ),
          textStyle: AppTypography.title,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.borderStrong),
          minimumSize: const Size(0, 52),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderFull,
          ),
          textStyle: AppTypography.title,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.brandPrimary,
          textStyle: AppTypography.title,
        ),
      ),

      // Fields: filled style, no outline borders (docs/Design.md §5.8).
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide.none,
        ),
        // Focus = 2 px ring, no glow (docs/Design.md §5.8).
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: colors.borderStrong, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: colors.warning),
        ),
        errorStyle: AppTypography.caption.copyWith(color: colors.warning),
        labelStyle: AppTypography.label.copyWith(color: colors.textSecondary),
        hintStyle: AppTypography.body.copyWith(color: colors.textTertiary),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceRaised,
        indicatorColor: colors.brandSubtle,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStatePropertyAll(
          AppTypography.caption.copyWith(color: colors.textSecondary),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: colors.textPrimary,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: AppRadius.radiusXl),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: colors.textPrimary,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceSubtle,
        selectedColor: colors.brandSubtle,
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderFull),
        labelStyle: AppTypography.label.copyWith(color: colors.textPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.textPrimary,
        contentTextStyle: AppTypography.body.copyWith(color: colors.surface),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),

      // Motion: durations are read from AppMotion at call sites, but the
      // page-transition defaults are aligned here.
      //
      // Android uses the predictive-back transition so the platform swipe
      // gesture previews the previous route (docs/Platform.md §6). iOS keeps the
      // Cupertino slide, supplied by `cupertino_ui`.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Maps our semantic tokens onto a Material [ColorScheme].
  ///
  /// Material slots we don't use directly still get sane values so third-party
  /// widgets don't fall back to purple.
  static ColorScheme _colorScheme(AppColors colors, Brightness brightness) {
    return ColorScheme(
      brightness: brightness,
      primary: colors.brandPrimary,
      onPrimary: colors.textOnBrand,
      primaryContainer: colors.brandSubtle,
      onPrimaryContainer: colors.textPrimary,
      secondary: colors.brandPrimary,
      onSecondary: colors.textOnBrand,
      secondaryContainer: colors.brandSubtle,
      onSecondaryContainer: colors.textPrimary,
      tertiary: colors.brandPrimary,
      onTertiary: colors.textOnBrand,
      error: colors.warning,
      onError: colors.textOnBrand,
      errorContainer: colors.warningSubtle,
      onErrorContainer: colors.textPrimary,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      onSurfaceVariant: colors.textSecondary,
      surfaceContainerLowest: colors.surfaceSunken,
      surfaceContainerLow: colors.surfaceSubtle,
      surfaceContainer: colors.surfaceSubtle,
      surfaceContainerHigh: colors.surfaceRaised,
      surfaceContainerHighest: colors.surfaceRaised,
      outline: colors.border,
      outlineVariant: colors.border,
      shadow: colors.isDark ? const Color(0xFF000000) : const Color(0xFF0F1720),
      scrim: colors.overlay,
      inverseSurface: colors.textPrimary,
      onInverseSurface: colors.surface,
      inversePrimary: colors.brandPrimary,
      surfaceTint: Colors.transparent,
    );
  }
}

/// Exposes the active [AppColors] (and resolved platform context) to the subtree.
///
/// Usage: `final colors = AppThemeColors.of(context);`
///
/// Widgets must read colors through this, not by constructing token objects —
/// that keeps light/dark switching automatic and testable.
class AppThemeColors extends InheritedWidget {
  /// Wraps [child] with the given [colors].
  const AppThemeColors({required this.colors, required super.child, super.key});

  /// The active semantic color set.
  final AppColors colors;

  /// Reads the nearest [AppColors], failing loudly when the widget is not
  /// wrapped in [AppThemeColors].
  static AppColors of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppThemeColors>();
    assert(
      result != null,
      'AppThemeColors.of() called with a context that does not contain '
      'AppThemeColors. Wrap the app in AppThemeColors (see app.dart).',
    );
    return result!.colors;
  }

  /// Reads the nearest [AppColors], or null when absent — for widgets that can
  /// legitimately render outside the app (goldens, previews).
  static AppColors? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppThemeColors>()?.colors;

  @override
  bool updateShouldNotify(AppThemeColors oldWidget) =>
      oldWidget.colors != colors;
}
