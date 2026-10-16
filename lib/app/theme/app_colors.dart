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

  /// Light-mode `textSecondary` — labels and metadata. **Darkened from
  /// `#5A6675`** when the page stopped being white: 5.85:1 on white fell to
  /// 5.45:1 on the `#F5F7FA` page, which put it 33 % away from dark's 7.27:1
  /// and broke the §2.6.3 parity rule. This is 6.00:1 on the page, 21 % away
  /// (§L).
  static const ink500 = Color(0xFF575F6D);

  /// Light-mode `textTertiary` — **darkened from `#6B7480`** when the page
  /// stopped being white (§L). At `#6B7480` this measured 4.74:1 on white but
  /// only 4.43:1 on the new `#F5F7FA` page, so the token moved with the surface
  /// it has to stay legible on. This is 4.68:1 there and 5.02:1 on white.
  ///
  /// `ink300` reached only 2.58:1 on white, which is why the weekday header was
  /// unreadable (§K.1-4) — it is kept below, not used for text.
  static const ink400 = Color(0xFF67707C);

  /// Dark-mode `textTertiary` — 5.23:1 on `darkSurface` (AA). Also the light
  /// focus ring (`borderStrong`), 3.35:1 on the `#F5F7FA` page and 3.89:1 on
  /// white, so it clears the 3:1 UI-mark floor on both (§L).
  static const ink350 = Color(0xFF7E8896);

  static const ink300 = Color(0xFF98A2B0);

  /// Light-mode hairline. Lifted from `ink100` (1.23:1 → 1.31:1) — §K.4.
  static const ink200 = Color(0xFFDCE1E9);

  static const ink100 = Color(0xFFE4E8EE);
  static const ink50 = Color(0xFFF5F7FA);

  // --- Light surface ramp (docs/Design.md §2.2, §2.7) ---
  //
  // A monotonic four-step ramp, darkest first, deliberately mirroring the dark
  // ramp's shape below. Before §L the light ramp was `surface` #FFFFFF,
  // `surfaceRaised` #FFFFFF, `surfaceSubtle` #F5F7FA — which is *inverted*
  // against §2.2's own definition of `surfaceRaised` as "cards/rows that need
  // to lift off `surfaceSubtle`", and left a card with **zero** optical
  // separation from the page. Measured, not argued: in
  // `test/features/accounts/presentation/goldens/accounts_light.png` 83.6 % of
  // the screen was one identical #FFFFFF, page and card alike, while the dark
  // twin separated them into 61.4 % #0E1218 and 21.7 % #182029. That is the
  // structural half of "the two modes look like different apps".
  //
  // White is the brightest value light mode can offer, so the only way to make
  // a card *lift* is to lower the page. Every hue (jade/coral/sage) is
  // untouched; this moves neutrals only.
  //
  // How far down the page can go is not a taste call — it is solved. The
  // binding constraints are that `warning` must clear AA on the page (it needs
  // surface Y >= 0.9213) and `textTertiary` must clear AA on the keypad tray
  // (0.8917). Light mode has very little headroom here, which is exactly why
  // the ramp is tight: it is the widest one that keeps every role legible on
  // the surface it actually lands on. Verified in
  // `test/app/theme/design_tokens_test.dart`.

  /// Light `surface` — the page background. Grouped-section grey, the way iOS
  /// `systemGroupedBackground` and M3 `surfaceContainerLow` work.
  static const lightSurface = Color(0xFFF5F7FA);

  /// Light `surfaceRaised` — cards and rows. The brightest surface in the mode,
  /// which is what makes a card read as lifted: 1.07:1 against the page, where
  /// dark separates the same two roles by 1.14:1.
  static const lightSurfaceRaised = Color(0xFFFFFFFF);

  /// Light `surfaceSubtle` — grouped sections, field fills, skeletons, the
  /// segmented-control track. Sits **between** the page and a card, which is
  /// where dark mode puts the same role, so a band reads as slightly raised in
  /// both modes rather than advancing in one and receding in the other.
  static const lightSurfaceSubtle = Color(0xFFF7F9FB);

  /// Light `surfaceSunken` — keypad tray, press washes, inset wells. The
  /// darkest light surface, so a well reads as pressed-in rather than quiet.
  static const lightSurfaceSunken = Color(0xFFF1F4F8);

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

  /// Income / positive. **Darkened from `#1E7A45`** in §L: that reached 5.35:1
  /// on white but only 4.99:1 on the new `#F5F7FA` page, which put it 32 % away
  /// from dark's 6.59:1 and broke the §2.6.3 parity rule. This is 5.47:1 on the
  /// page and still clears AA on all four light surfaces (§2.4).
  static const sage500 = Color(0xFF1C7340);
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

  // --- Scrim ---
  Color get overlay;

  /// True when this is the dark scheme. Used only by adaptive components that
  /// need to pick an alpha or blur strength the tokens can't express.
  bool get isDark;
}

/// Light semantic tokens — docs/Design.md §2.2.
final class AppColorsLight implements AppColors {
  const AppColorsLight();

  @override
  Color get surface => AppPalette.lightSurface;

  @override
  Color get surfaceRaised => AppPalette.lightSurfaceRaised;

  @override
  Color get surfaceSubtle => AppPalette.lightSurfaceSubtle;

  @override
  Color get surfaceSunken => AppPalette.lightSurfaceSunken;

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
  bool get isDark => true;
}
