import 'package:material_ui/material_ui.dart';

/// Raw brand palette. **Private to the token layer** — widgets must use the
/// semantic tokens in [AppColorsLight] / [AppColorsDark] instead
/// (docs/Design.md §2.1).
///
/// Kept in its own class so the palette can be swapped without touching any
/// semantic token name.
abstract final class AppPalette {
  const AppPalette._();

  static const ink900 = Color(0xFF0F1720);
  static const ink700 = Color(0xFF26313D);
  static const ink500 = Color(0xFF5A6675);
  static const ink300 = Color(0xFF98A2B0);
  static const ink100 = Color(0xFFE4E8EE);
  static const ink50 = Color(0xFFF5F7FA);

  static const jade600 = Color(0xFF0E7C66);
  static const jade500 = Color(0xFF12987C);
  static const jade100 = Color(0xFFD6F0E8);

  static const coral500 = Color(0xFFCC3438);
  static const coral100 = Color(0xFFFDE7E7);

  static const sage500 = Color(0xFF1E7A45);
  static const sage100 = Color(0xFFE3F6E9);

  static const amber500 = Color(0xFFC98A0B);
  static const amber100 = Color(0xFFFCF0D8);

  static const violet500 = Color(0xFF6B5BD2);

  // Dark-mode lightened variants (contrast-corrected, docs/Design.md §2.3).
  static const jadeDark = Color(0xFF2BB99A);
  static const coralDark = Color(0xFFFF6B6F);
  static const sageDark = Color(0xFF4CC777);
  static const amberDark = Color(0xFFE0A63C);

  static const darkSurface = Color(0xFF0E1218);
  static const darkSurfaceRaised = Color(0xFF182029);
  static const darkSurfaceSubtle = Color(0xFF141A21);
  static const darkSurfaceSunken = Color(0xFF0A0E13);
  static const darkBorder = Color(0xFF26313D);
  static const darkBrandSubtle = Color(0xFF0F2E28);
  static const darkCoralSubtle = Color(0xFF33191B);
  static const darkSageSubtle = Color(0xFF122C1C);
  static const darkAmberSubtle = Color(0xFF33280F);
}

/// Semantic color contract. Every widget reads colors through this interface,
/// so light/dark are the only implementations and neither leaks raw palette values.
///
/// Mirrors docs/Design.md §2.2 (light) and §2.3 (dark).
abstract interface class AppColors {
  // --- Surfaces ---
  Color get surface;
  Color get surfaceRaised;
  Color get surfaceSubtle;
  Color get surfaceSunken;

  // --- Lines ---
  Color get border;
  Color get borderStrong;

  // --- Text ---
  Color get textPrimary;
  Color get textSecondary;
  Color get textTertiary;
  Color get textOnBrand;

  // --- Brand ---
  Color get brandPrimary;
  Color get brandSubtle;

  // --- Money (docs/Design.md §2.4: out = expense/red, in = income/green) ---
  Color get moneyOut;
  Color get moneyOutSubtle;
  Color get moneyIn;
  Color get moneyInSubtle;

  // --- Status ---
  Color get warning;
  Color get warningSubtle;

  // --- Scrim & glass ---
  Color get overlay;
  Color get glassTint;
  Color get glassStroke;

  /// True when this is the dark scheme. Used only by adaptive components that
  /// need to pick an alpha or blur strength the tokens can't express.
  bool get isDark;
}

/// Light semantic tokens — docs/Design.md §2.2.
final class AppColorsLight implements AppColors {
  const AppColorsLight();

  @override
  Color get surface => const Color(0xFFFFFFFF);

  @override
  Color get surfaceRaised => const Color(0xFFFFFFFF);

  @override
  Color get surfaceSubtle => AppPalette.ink50;

  @override
  Color get surfaceSunken => const Color(0xFFEDF0F5);

  @override
  Color get border => AppPalette.ink100;

  @override
  Color get borderStrong => AppPalette.ink300;

  @override
  Color get textPrimary => AppPalette.ink900;

  @override
  Color get textSecondary => AppPalette.ink500;

  @override
  Color get textTertiary => AppPalette.ink300;

  @override
  Color get textOnBrand => const Color(0xFFFFFFFF);

  @override
  Color get brandPrimary => AppPalette.jade600;

  @override
  Color get brandSubtle => AppPalette.jade100;

  @override
  Color get moneyOut => AppPalette.coral500;

  @override
  Color get moneyOutSubtle => AppPalette.coral100;

  @override
  Color get moneyIn => AppPalette.sage500;

  @override
  Color get moneyInSubtle => AppPalette.sage100;

  @override
  Color get warning => AppPalette.amber500;

  @override
  Color get warningSubtle => AppPalette.amber100;

  @override
  Color get overlay => const Color(0x520F1720); // ink900 @ 32%

  @override
  Color get glassTint => const Color(0x9EFFFFFF); // @ 62%

  @override
  Color get glassStroke => const Color(0x73FFFFFF); // @ 45%

  @override
  bool get isDark => false;
}

/// Dark semantic tokens — docs/Design.md §2.3.
final class AppColorsDark implements AppColors {
  const AppColorsDark();

  @override
  Color get surface => AppPalette.darkSurface;

  @override
  Color get surfaceRaised => AppPalette.darkSurfaceRaised;

  @override
  Color get surfaceSubtle => AppPalette.darkSurfaceSubtle;

  @override
  Color get surfaceSunken => AppPalette.darkSurfaceSunken;

  @override
  Color get border => AppPalette.darkBorder;

  @override
  Color get borderStrong => AppPalette.ink300;

  @override
  Color get textPrimary => AppPalette.ink50;

  @override
  Color get textSecondary => AppPalette.ink300;

  @override
  Color get textTertiary => AppPalette.ink500;

  @override
  Color get textOnBrand => const Color(0xFF06231D);

  @override
  Color get brandPrimary => AppPalette.jadeDark;

  @override
  Color get brandSubtle => AppPalette.darkBrandSubtle;

  @override
  Color get moneyOut => AppPalette.coralDark;

  @override
  Color get moneyOutSubtle => AppPalette.darkCoralSubtle;

  @override
  Color get moneyIn => AppPalette.sageDark;

  @override
  Color get moneyInSubtle => AppPalette.darkSageSubtle;

  @override
  Color get warning => AppPalette.amberDark;

  @override
  Color get warningSubtle => AppPalette.darkAmberSubtle;

  @override
  Color get overlay => const Color(0x8C000000); // @ 55%

  @override
  Color get glassTint => const Color(0x94182029); // surfaceRaised @ 58%

  @override
  Color get glassStroke => const Color(0x1FFFFFFF); // @ 12%

  @override
  bool get isDark => true;
}
