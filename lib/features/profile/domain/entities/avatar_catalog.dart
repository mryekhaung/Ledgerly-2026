import 'dart:math';

import 'package:ledgerly/features/profile/domain/entities/avatar_colors.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_palette.dart';

/// Legacy palette slot placeholder for transitional compatibility.
final class PaletteSlot {
  const PaletteSlot(this.index);
  final int index;
}

/// Legacy backdrop kind for transitional compatibility.
enum BackdropKind { none, circle, stripes, ring }

/// Legacy shape kind for transitional compatibility.
enum ShapeKind { circle, roundedSquare, teardrop, hexagon }

/// Legacy eyes kind for transitional compatibility.
enum EyesKind { dots, lines, happy, sparkle }

/// Legacy mouth kind for transitional compatibility.
enum MouthKind { smile, neutral, dot, frown }

/// Legacy avatar option for transitional compatibility.
final class AvatarOption<T> {
  const AvatarOption({required this.kind, required this.palette});
  final T kind;
  final PaletteSlot palette;
}

/// The catalogue of every part and option for Open Peeps avatars.
///
/// Spec: `docs/Avatar.md` §3, §4, §9.3.
/// Pure Dart — no Flutter imports.
abstract final class AvatarCatalog {
  const AvatarCatalog._();

  /// Canvas width from `manifest.json`.
  static const int canvasWidth = 704;

  /// Canvas height from `manifest.json`.
  static const int canvasHeight = 704;

  /// 48 head/hair options from Open Peeps (`docs/Avatar.md` §9.3).
  static const List<String> heads = <String>[
    'afro',
    'bangs',
    'bangs2',
    'bantu_knots',
    'bear',
    'bun',
    'bun2',
    'buns',
    'cornrows',
    'cornrows2',
    'dreads1',
    'dreads2',
    'flat_top',
    'flat_top_long',
    'gray_bun',
    'gray_medium',
    'gray_short',
    'hat_beanie',
    'hat_hip',
    'hijab',
    'long',
    'long_afro',
    'long_bangs',
    'long_curly',
    'medium1',
    'medium2',
    'medium3',
    'medium_bangs',
    'medium_bangs2',
    'medium_bangs3',
    'medium_straight',
    'mohawk',
    'mohawk2',
    'no_hair1',
    'no_hair2',
    'no_hair3',
    'pomp',
    'shaved1',
    'shaved2',
    'shaved3',
    'short1',
    'short2',
    'short3',
    'short4',
    'short5',
    'turban',
    'twists',
    'twists2',
  ];

  /// 30 facial expression options from Open Peeps (`docs/Avatar.md` §9.3).
  static const List<String> expressions = <String>[
    'angry_with_fang',
    'awe',
    'blank',
    'calm',
    'cheeky',
    'concerned',
    'concerned_fear',
    'contempt',
    'cute',
    'cyclops',
    'driven',
    'eating_happy',
    'explaining',
    'eyes_closed',
    'fear',
    'hectic',
    'loving_grin1',
    'loving_grin2',
    'monster',
    'old',
    'rage',
    'serious',
    'smile',
    'smile_big',
    'smile_lol',
    'smile_teeth_gap',
    'solemn',
    'suspicious',
    'tired',
    'very_angry',
  ];

  /// Alias for [expressions].
  static List<String> get faces => expressions;

  /// 16 facial hair options from Open Peeps (`docs/Avatar.md` §9.3).
  static const List<String> facialHairs = <String>[
    'chin',
    'full',
    'full2',
    'full3',
    'full4',
    'goatee1',
    'goatee2',
    'moustache1',
    'moustache2',
    'moustache3',
    'moustache4',
    'moustache5',
    'moustache6',
    'moustache7',
    'moustache8',
    'moustache9',
  ];

  /// 8 accessory / glasses options from Open Peeps (`docs/Avatar.md` §9.3).
  static const List<String> accessories = <String>[
    'eyepatch',
    'glasses',
    'glasses2',
    'glasses3',
    'glasses4',
    'glasses5',
    'sunglasses',
    'sunglasses2',
  ];

  /// 2 protective mask options from Open Peeps (`docs/Avatar.md` §9.3).
  static const List<String> masks = <String>['medical_mask', 'respirator'];

  /// Validates whether an [AvatarConfig] references existing catalog IDs.
  static bool isValidConfig(AvatarConfig config) {
    if (!heads.contains(config.headId)) return false;
    if (!expressions.contains(config.faceId)) return false;
    if (config.accessoryId != null &&
        !accessories.contains(config.accessoryId)) {
      return false;
    }
    if (config.facialHairId != null &&
        !facialHairs.contains(config.facialHairId)) {
      return false;
    }
    if (config.maskId != null && !masks.contains(config.maskId)) {
      return false;
    }
    return true;
  }

  /// Generates a random, valid [AvatarConfig].
  ///
  /// Uses probability thresholds from `docs/Avatar.md` §9.3:
  /// - `accessories`: 20% probability
  /// - `facialHair`: 10% probability
  /// - `mask`: 5% probability
  ///
  /// Deterministic when provided with a seeded [random].
  static AvatarConfig random(Random random) {
    T pick<T>(List<T> list) => list[random.nextInt(list.length)];

    final head = pick(heads);
    final face = pick(expressions);

    // Accessories: 20% chance
    final accessory = random.nextInt(100) < 20 ? pick(accessories) : null;

    // Facial hair: 10% chance
    final facialHair = random.nextInt(100) < 10 ? pick(facialHairs) : null;

    // Mask: 5% chance
    final mask = random.nextInt(100) < 5 ? pick(masks) : null;

    final colors = AvatarColors(
      background: pick(AvatarPalette.backgrounds),
      skin: pick(AvatarPalette.skins),
      hair: pick(AvatarPalette.hairs),
      clothing: pick(AvatarPalette.outfits),
      ink: pick(AvatarPalette.inks),
    );

    return AvatarConfig(
      headId: head,
      faceId: face,
      accessoryId: accessory,
      facialHairId: facialHair,
      maskId: mask,
      colors: colors,
    );
  }

  // --- Legacy helpers preserved for transitional compatibility ---

  static const List<AvatarOption<BackdropKind>> backgroundColors =
      <AvatarOption<BackdropKind>>[
        AvatarOption(kind: BackdropKind.none, palette: PaletteSlot(0)),
        AvatarOption(kind: BackdropKind.none, palette: PaletteSlot(1)),
        AvatarOption(kind: BackdropKind.none, palette: PaletteSlot(2)),
        AvatarOption(kind: BackdropKind.none, palette: PaletteSlot(3)),
        AvatarOption(kind: BackdropKind.none, palette: PaletteSlot(4)),
        AvatarOption(kind: BackdropKind.none, palette: PaletteSlot(5)),
        AvatarOption(kind: BackdropKind.none, palette: PaletteSlot(6)),
        AvatarOption(kind: BackdropKind.none, palette: PaletteSlot(7)),
      ];

  static const List<AvatarOption<BackdropKind>> backdrops =
      <AvatarOption<BackdropKind>>[
        AvatarOption(kind: BackdropKind.none, palette: PaletteSlot(0)),
        AvatarOption(kind: BackdropKind.circle, palette: PaletteSlot(0)),
        AvatarOption(kind: BackdropKind.stripes, palette: PaletteSlot(1)),
        AvatarOption(kind: BackdropKind.ring, palette: PaletteSlot(2)),
      ];

  static const List<AvatarOption<ShapeKind>> shapes = <AvatarOption<ShapeKind>>[
    AvatarOption(kind: ShapeKind.circle, palette: PaletteSlot(0)),
    AvatarOption(kind: ShapeKind.roundedSquare, palette: PaletteSlot(1)),
    AvatarOption(kind: ShapeKind.teardrop, palette: PaletteSlot(2)),
    AvatarOption(kind: ShapeKind.hexagon, palette: PaletteSlot(3)),
  ];

  static const List<AvatarOption<EyesKind>> eyes = <AvatarOption<EyesKind>>[
    AvatarOption(kind: EyesKind.dots, palette: PaletteSlot(8)),
    AvatarOption(kind: EyesKind.lines, palette: PaletteSlot(8)),
    AvatarOption(kind: EyesKind.happy, palette: PaletteSlot(8)),
    AvatarOption(kind: EyesKind.sparkle, palette: PaletteSlot(8)),
  ];

  static const List<AvatarOption<MouthKind>> mouths = <AvatarOption<MouthKind>>[
    AvatarOption(kind: MouthKind.smile, palette: PaletteSlot(8)),
    AvatarOption(kind: MouthKind.neutral, palette: PaletteSlot(8)),
    AvatarOption(kind: MouthKind.dot, palette: PaletteSlot(8)),
    AvatarOption(kind: MouthKind.frown, palette: PaletteSlot(8)),
  ];

  static int optionCount(AvatarPart part) => switch (part) {
    AvatarPart.background => backgroundColors.length,
    AvatarPart.backdrop => backdrops.length,
    AvatarPart.shape => shapes.length,
    AvatarPart.eyes => eyes.length,
    AvatarPart.mouth => mouths.length,
  };

  static List<int> optionIndices(AvatarPart part) =>
      List<int>.generate(optionCount(part), (index) => index);

  static const AvatarConfig initial = AvatarConfig.initial;

  static int paintOrder(AvatarPart part) => AvatarPart.values.indexOf(part);
}
