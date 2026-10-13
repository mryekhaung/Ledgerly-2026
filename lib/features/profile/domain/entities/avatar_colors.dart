/// The color scheme for an Open Peeps avatar composition.
///
/// Colors are stored as 32-bit ARGB integers (`0xAARRGGBB`) chosen from curated palettes.
/// Pure Dart — no Flutter imports (`docs/Agent.md` §3.1).
library;

/// The color slots available for an avatar.
final class AvatarColors {
  /// Creates an avatar color configuration.
  const AvatarColors({
    required this.background,
    required this.skin,
    required this.hair,
    required this.clothing,
    required this.ink,
  });

  /// ARGB32 integer for the circular background fill.
  final int background;

  /// ARGB32 integer for skin tone.
  final int skin;

  /// ARGB32 integer for hair / contrast strands.
  final int hair;

  /// ARGB32 integer for clothing / outfit.
  final int clothing;

  /// ARGB32 integer for line-art ink.
  final int ink;

  /// Alias for [clothing] (`docs/Avatar.md` §9.8).
  int get outfit => clothing;

  /// The default palette selection for the initial avatar configuration.
  static const AvatarColors initial = AvatarColors(
    background: 0xFFE8F1F5,
    skin: 0xFFF1C27D,
    hair: 0xFF2C1B18,
    clothing: 0xFF5B7FFF,
    ink: 0xFF000000,
  );

  /// Returns a copy with specified fields replaced.
  AvatarColors copyWith({
    int? background,
    int? skin,
    int? hair,
    int? clothing,
    int? ink,
  }) => AvatarColors(
    background: background ?? this.background,
    skin: skin ?? this.skin,
    hair: hair ?? this.hair,
    clothing: clothing ?? this.clothing,
    ink: ink ?? this.ink,
  );

  /// Encodes colors to a JSON-serializable map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'background': background,
    'skin': skin,
    'hair': hair,
    'clothing': clothing,
    'ink': ink,
  };

  /// Decodes from a JSON map, falling back safely to [initial] defaults.
  factory AvatarColors.fromJson(Map<String, dynamic> json) => AvatarColors(
    background: json['background'] as int? ?? initial.background,
    skin: json['skin'] as int? ?? initial.skin,
    hair: json['hair'] as int? ?? initial.hair,
    clothing:
        json['clothing'] as int? ??
        (json['outfit'] as int? ?? initial.clothing),
    ink: json['ink'] as int? ?? initial.ink,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarColors &&
          other.background == background &&
          other.skin == skin &&
          other.hair == hair &&
          other.clothing == clothing &&
          other.ink == ink;

  @override
  int get hashCode => Object.hash(background, skin, hair, clothing, ink);

  @override
  String toString() =>
      'AvatarColors(background: 0x${background.toRadixString(16).padLeft(8, '0')}, skin: 0x${skin.toRadixString(16).padLeft(8, '0')}, hair: 0x${hair.toRadixString(16).padLeft(8, '0')}, clothing: 0x${clothing.toRadixString(16).padLeft(8, '0')}, ink: 0x${ink.toRadixString(16).padLeft(8, '0')})';
}
