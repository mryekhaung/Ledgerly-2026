import 'package:material_ui/material_ui.dart';

/// Raw brand palette. **Private to the token layer** — widgets must use the
/// semantic tokens in [AppColorsLight] / [AppColorsDark] instead
/// (docs/Design.md §2.1).
///
/// Kept in its own class so the palette can be swapped without touching any
/// semantic token name.
///
/// Every value here was chosen against a measured WCAG 2.1 ratio, not by eye.
/// The audit that produced them (and the targets each role must hit) is recorded
/// in `docs/Roadmap.md` §K; the assertions live in
/// `test/app/theme/design_tokens_test.dart`. **Do not "brighten for aesthetics"
/// without re-running that test** — §K is the history of exactly that mistake.
abstract final class AppPalette {
  const AppPalette._();

  static const ink900 = Color(0xFF0F1720);
  static const ink700 = Color(0xFF26313D);

  /// Dark-mode hairline. Lifted from `ink700` so a separator is visible on
  /// `darkSurface` (1.57:1 vs 1.42:1) — §K.4.
  static const ink600 = Color(0xFF2C3844);

  static const ink500 = Color(0xFF5A6675);

  /// Light-mode `textTertiary` — 4.74:1 on white (AA). `ink300` reached only
  /// 2.58:1, which is why the weekday header was unreadable (§K.1-4).
  static const ink400 = Color(0xFF6B7480);

  /// Dark-mode `textTertiary` — 5.23:1 on `darkSurface` (AA). Also the light
  /// focus ring (`borderStrong`), 3.89:1 on white.
  static const ink350 = Color(0xFF7E8896);

  static const ink300 = Color(0xFF98A2B0);

  /// Light-mode hairline. Lifted from `ink100` (1.23:1 → 1.31:1) — §K.4.
  static const ink200 = Color(0xFFDCE1E9);

  static const ink100 = Color(0xFFE4E8EE);
  static const ink50 = Color(0xFFF5F7FA);

  static const jade600 = Color(0xFF0E7C66);
  static const jade500 = Color(0xFF12987C);

  /// Light brand tint (`brandSubtle`). **Raised from `#D6F0E8`**, which read
  /// 1.20:1 on white — i.e. a selected state nobody could see (§K.1-2). This
  /// clears 1.45:1 on `surfaceSubtle`, so a nav indicator or chip pill still
  /// reads as a tint and not a smear.
  static const jade100 = Color(0xFFA3DBC8);

  /// Light text/icon on [jade100] — 5.81:1, where `jade600` on it was 3.90:1
  /// and failed AA for small text (§K.1-2).
  static const jadeOnTintLight = Color(0xFF0A5A4A);

  static const coral500 = Color(0xFFCC3438);
  static const coral100 = Color(0xFFFDE7E7);

  static const sage500 = Color(0xFF1E7A45);
  static const sage100 = Color(0xFFE3F6E9);

  /// Light warning. `#C98A0B` measured **2.95:1** on white — a budget-at-risk
  /// label that failed AA (§K.4). This is 4.86:1.
  static const amber500 = Color(0xFF9C6606);
  static const amber100 = Color(0xFFFCF0D8);

  static const violet500 = Color(0xFF6B5BD2);

  // --- Dark-mode variants (contrast-corrected, docs/Design.md §2.3) ---
  //
  // Each is the light value lightened just enough to clear 4.5:1 on
  // `darkSurface`, and no further: over-brightening is what made the two modes
  // read as different apps (§K.2 — `moneyIn` was +63% against its light twin).
  static const jadeDark = Color(0xFF22A287);
  static const coralDark = Color(0xFFE85D66);
  static const sageDark = Color(0xFF3FAD64);
  static const amberDark = Color(0xFFE0A63C);

  static const darkSurface = Color(0xFF0E1218);
  static const darkSurfaceRaised = Color(0xFF182029);
  static const darkSurfaceSubtle = Color(0xFF141A21);
  static const darkSurfaceSunken = Color(0xFF0A0E13);
  static const darkBorder = Color(0xFF26313D);

  /// Dark brand tint (`brandSubtle`). Raised from `#0F2E28` (1.29:1 — invisible).
  static const darkBrandSubtle = Color(0xFF1A4C40);

  /// Dark text/icon on [darkBrandSubtle] — 5.80:1.
  static const jadeOnTintDark = Color(0xFF7FD8C0);

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

  /// Text and icons **on** [brandSubtle]. A tinted fill needs its own
  /// foreground: painting `brandPrimary` on `brandSubtle` measured 3.90:1 light
  /// and 3.43:1 dark, both below AA for small text (§K.1-2).
  Color get onBrandSubtle;

  // --- Selection (docs/Design.md §2.6) ---
  //
  // A *state* is not a tint. Before these existed the only "selected" token was
  // `brandSubtle`, a 1.2:1 wash, so every selected control in the app was
  // effectively invisible (§K.1-2, §K.1-5).

  /// Fill for a solid selected state — a day cell, a chosen option. Must clear
  /// 3:1 against `surface` so the state itself is perceivable.
  Color get selectedFill;

  /// Foreground on [selectedFill]. Must clear 4.5:1 on it.
  Color get onSelectedFill;

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
  Color get border => AppPalette.ink200;

  @override
  Color get borderStrong => AppPalette.ink350;

  @override
  Color get textPrimary => AppPalette.ink900;

  @override
  Color get textSecondary => AppPalette.ink500;

  @override
  Color get textTertiary => AppPalette.ink400;

  @override
  Color get textOnBrand => const Color(0xFFFFFFFF);

  @override
  Color get brandPrimary => AppPalette.jade600;

  @override
  Color get brandSubtle => AppPalette.jade100;

  @override
  Color get onBrandSubtle => AppPalette.jadeOnTintLight;

  @override
  Color get selectedFill => AppPalette.jade600;

  @override
  Color get onSelectedFill => const Color(0xFFFFFFFF);

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
  Color get border => AppPalette.ink600;

  @override
  Color get borderStrong => AppPalette.ink300;

  @override
  Color get textPrimary => AppPalette.ink50;

  @override
  Color get textSecondary => AppPalette.ink300;

  @override
  Color get textTertiary => AppPalette.ink350;

  @override
  Color get textOnBrand => const Color(0xFF06231D);

  @override
  Color get brandPrimary => AppPalette.jadeDark;

  @override
  Color get brandSubtle => AppPalette.darkBrandSubtle;

  @override
  Color get onBrandSubtle => AppPalette.jadeOnTintDark;

  @override
  Color get selectedFill => AppPalette.jadeDark;

  @override
  Color get onSelectedFill => const Color(0xFF06231D);

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
