/// Curated, WCAG-friendly palettes for the Open Peeps avatar system.
///
/// Spec: `docs/Avatar.md` §6 and §9.4.
/// Defined in pure Dart using 32-bit ARGB integers (`0xAARRGGBB`) so domain and
/// data layers remain framework-free (`docs/Agent.md` §3.1).
library;

/// The curated color choices for each avatar color slot.
abstract final class AvatarPalette {
  const AvatarPalette._();

  /// 8 curated background circle/squircle tint fills (`docs/Avatar.md` §6).
  static const List<int> backgrounds = <int>[
    0xFFE8F1F5, // soft ice blue
    0xFFE3F2FD, // sky tint
    0xFFE8F5E9, // mint tint
    0xFFFFF3E0, // warm peach
    0xFFF3E5F5, // lavender tint
    0xFFFFEBEE, // blush tint
    0xFFFFFDE7, // buttercream tint
    0xFFECEFF1, // slate tint
  ];

  /// 4 outline/ink line-art shades (`docs/Avatar.md` §6).
  static const List<int> inks = <int>[
    0xFF000000, // pure ink black (default)
    0xFF1E232A, // charcoal slate
    0xFF2B1E16, // deep bistre
    0xFF1B2A32, // midnight navy
  ];

  /// 10 hair / headContrast strand shades (`docs/Avatar.md` §6).
  static const List<int> hairs = <int>[
    0xFF1A1A1A, // jet black
    0xFF2C1B18, // espresso dark brown (source default)
    0xFF4A3728, // warm brown
    0xFF7D4E2D, // chestnut / auburn
    0xFFB35427, // copper ginger
    0xFFDE9E48, // honey blonde
    0xFFF5D061, // light golden blonde
    0xFF8D99AE, // silver grey
    0xFFE0E1DD, // platinum white
    0xFFF59797, // pastel rose
  ];

  /// 7 natural, diverse skin tones (`docs/Avatar.md` §6).
  static const List<int> skins = <int>[
    0xFF694D3D, // deep espresso (source default)
    0xFF8D5524, // chestnut
    0xFFC68642, // warm honey
    0xFFD69A5E, // caramel
    0xFFE0AC69, // golden olive
    0xFFF1C27D, // almond tan (source default)
    0xFFFFDBB4, // fair peach (source default)
  ];

  /// 10 vibrant and neutral outfit/clothing shades (`docs/Avatar.md` §6).
  static const List<int> outfits = <int>[
    0xFF5B7FFF, // cobalt blue
    0xFF78E185, // mint green (source default)
    0xFFFF6B6B, // coral red
    0xFFFFCF77, // marigold yellow (source default)
    0xFFA370F7, // lavender violet
    0xFF20C997, // teal green
    0xFFFF8E3C, // tangerine orange
    0xFF4D96FF, // sky cyan
    0xFF6C757D, // slate grey
    0xFF2B2D42, // midnight navy
  ];

  /// Alias for [outfits].
  static List<int> get clothings => outfits;
}
