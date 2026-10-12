import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_catalog.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:material_ui/material_ui.dart';

/// The concrete colours an avatar part is drawn with.
///
/// Bridges the domain's theme-agnostic [PaletteSlot] to actual colours. This is
/// the only file in the avatar stack that knows about `Color`, which is what lets
/// `domain/` stay pure Dart while the palette still differs between light and
/// dark (`docs/Agent.md` §3.1).
abstract final class AvatarPalette {
  const AvatarPalette._();

  /// Light-scheme fills, indexed by [PaletteSlot.index].
  ///
  /// Saturated mid-tones: the head is drawn on top in a lighter tint, so a pale
  /// background would erase the silhouette.
  static const List<Color> _lightFills = <Color>[
    Color(0xFF7FD1B9), // jade
    Color(0xFF8CC4F0), // sky
    Color(0xFFB3A6F0), // violet
    Color(0xFFF0A8C0), // rose
    Color(0xFFF2C27F), // amber
    Color(0xFF9FD89A), // leaf
    Color(0xFFF0A08C), // clay
    Color(0xFF8FB0C8), // slate
    Color(0xFF2A3440), // ink — eyes and mouth
  ];

  /// Dark-scheme fills: the same hues, lifted so they read on a dark surface.
  static const List<Color> _darkFills = <Color>[
    Color(0xFF3E8C77),
    Color(0xFF3C6E9C),
    Color(0xFF5C4FA0),
    Color(0xFF9C5470),
    Color(0xFF9C7233),
    Color(0xFF4C8050),
    Color(0xFF9C5B49),
    Color(0xFF4C6578),
    Color(0xFFE4E8EE), // ink — inverted for contrast
  ];

  /// The fills for the active scheme.
  static List<Color> fillsFor(AppColors colors) =>
      colors.isDark ? _darkFills : _lightFills;

  /// The fill for [slot], clamped so an index from a newer build cannot throw.
  static Color resolve(AppColors colors, PaletteSlot slot) {
    final fills = fillsFor(colors);
    return fills[slot.index.clamp(0, fills.length - 1)];
  }

  /// The colour the head is drawn in, given the background it sits on.
  ///
  /// Derived rather than stored: the head must stay legible against *any*
  /// background, and the reliable way to guarantee that is to lighten the
  /// background itself rather than to pick a second, independently-chosen colour.
  static Color headFor(AppColors colors, Color background) {
    final hsl = HSLColor.fromColor(background);
    return hsl
        .withLightness(
          (hsl.lightness + (colors.isDark ? 0.26 : 0.20)).clamp(0, 1),
        )
        .withSaturation((hsl.saturation * 0.55).clamp(0, 1))
        .toColor();
  }

  /// The rim drawn around the head, so it separates from a same-hue background.
  static Color rimFor(AppColors colors) =>
      colors.isDark ? const Color(0x33000000) : const Color(0x1A0F1720);

  /// The colour for eyes and mouth — the last palette slot, which is ink in the
  /// light scheme and a near-white in the dark one.
  static Color inkFor(AppColors colors) =>
      resolve(colors, const PaletteSlot(8));
}
