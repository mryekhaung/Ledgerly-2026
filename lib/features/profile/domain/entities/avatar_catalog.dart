import 'dart:math';

import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';

/// A palette slot on the avatar.
///
/// A pair of colours (base + accent) rather than a single one: every part is
/// drawn with a fill and a rim, and keeping them together is what makes a
/// randomly generated avatar look deliberate instead of muddy.
///
/// `domain/` cannot import Flutter, so this is **not** a `Color` — the renderer
/// maps a [PaletteSlot] onto the active theme's palette. That indirection is
/// also what gives the dark theme a contrast-corrected variant for free.
final class PaletteSlot {
  /// Creates a palette slot.
  const PaletteSlot(this.index);

  /// Index into the renderer's palette table. Identical in light and dark, but
  /// resolved to different concrete colours.
  final int index;
}

/// How a backdrop is drawn behind the head.
enum BackdropKind {
  /// Nothing — the background alone.
  none,

  /// A large soft circle offset up and to the right.
  circle,

  /// A pair of overlapping rounded bars.
  stripes,

  /// A ring outline.
  ring,
}

/// How a head silhouette is drawn.
enum ShapeKind {
  /// A circle — the neutral default.
  circle,

  /// A rounded square.
  roundedSquare,

  /// A downward teardrop, wider at the top.
  teardrop,

  /// A hexagon.
  hexagon,
}

/// How the eye pair is drawn.
enum EyesKind {
  /// Two filled dots.
  dots,

  /// Two short horizontal lines — a calm, closed-eye look.
  lines,

  /// Two arcs, smiling upward.
  happy,

  /// Two dots with a small highlight, for a friendlier read.
  sparkle,
}

/// How the mouth is drawn.
enum MouthKind {
  /// A gentle upward curve.
  smile,

  /// A flat line.
  neutral,

  /// A small filled circle.
  dot,

  /// A short downward curve.
  frown,
}

/// One selectable option in an avatar slot.
final class AvatarOption<T> {
  /// Creates an option.
  const AvatarOption({required this.kind, required this.palette});

  /// Which drawing routine to use.
  final T kind;

  /// The colour pair, for the parts that are filled.
  final PaletteSlot palette;
}

/// The catalogue of every part an avatar can be built from.
///
/// Static data, deliberately: an avatar is stored as five indices
/// ([AvatarConfig]), so the catalogue **is** the persisted format. Appending an
/// option is backwards-compatible; reordering or removing one silently changes
/// every existing avatar, so both are treated as breaking changes.
///
/// Spec: `docs/Architecture.md` §2.
abstract final class AvatarCatalog {
  const AvatarCatalog._();

  /// Background fills. The most varied slot, since it dominates the silhouette.
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

  /// Decorative shapes drawn behind the head.
  static const List<AvatarOption<BackdropKind>> backdrops =
      <AvatarOption<BackdropKind>>[
        AvatarOption(kind: BackdropKind.none, palette: PaletteSlot(0)),
        AvatarOption(kind: BackdropKind.circle, palette: PaletteSlot(0)),
        AvatarOption(kind: BackdropKind.stripes, palette: PaletteSlot(1)),
        AvatarOption(kind: BackdropKind.ring, palette: PaletteSlot(2)),
      ];

  /// Head silhouettes.
  static const List<AvatarOption<ShapeKind>> shapes = <AvatarOption<ShapeKind>>[
    AvatarOption(kind: ShapeKind.circle, palette: PaletteSlot(0)),
    AvatarOption(kind: ShapeKind.roundedSquare, palette: PaletteSlot(1)),
    AvatarOption(kind: ShapeKind.teardrop, palette: PaletteSlot(2)),
    AvatarOption(kind: ShapeKind.hexagon, palette: PaletteSlot(3)),
  ];

  /// Eye styles.
  static const List<AvatarOption<EyesKind>> eyes = <AvatarOption<EyesKind>>[
    AvatarOption(kind: EyesKind.dots, palette: PaletteSlot(8)),
    AvatarOption(kind: EyesKind.lines, palette: PaletteSlot(8)),
    AvatarOption(kind: EyesKind.happy, palette: PaletteSlot(8)),
    AvatarOption(kind: EyesKind.sparkle, palette: PaletteSlot(8)),
  ];

  /// Mouth styles.
  static const List<AvatarOption<MouthKind>> mouths = <AvatarOption<MouthKind>>[
    AvatarOption(kind: MouthKind.smile, palette: PaletteSlot(8)),
    AvatarOption(kind: MouthKind.neutral, palette: PaletteSlot(8)),
    AvatarOption(kind: MouthKind.dot, palette: PaletteSlot(8)),
    AvatarOption(kind: MouthKind.frown, palette: PaletteSlot(8)),
  ];

  /// The number of options available for [part].
  ///
  /// The one place that knows how the per-part lists line up, so validation
  /// ([AvatarConfig.isValid]) and the editor's cycle length cannot disagree.
  static int optionCount(AvatarPart part) => switch (part) {
    AvatarPart.background => backgroundColors.length,
    AvatarPart.backdrop => backdrops.length,
    AvatarPart.shape => shapes.length,
    AvatarPart.eyes => eyes.length,
    AvatarPart.mouth => mouths.length,
  };

  /// The options for [part], as a list of indices.
  static List<int> optionIndices(AvatarPart part) =>
      List<int>.generate(optionCount(part), (index) => index);

  /// A config where every slot is the given `indices`' first entry — a
  /// deterministic starting point for tests and previews.
  static const AvatarConfig initial = AvatarConfig.initial;

  /// Generates a random but *valid* avatar.
  ///
  /// Takes a [Random] rather than reaching for a global one so the result is
  /// reproducible under test — the editor's shuffle button and the goldens both
  /// depend on that.
  ///
  /// The background and the head are drawn as independent picks: constraining
  /// them to "different palette slots" was considered and rejected, because with
  /// only eight slots it removes more good combinations than it prevents bad
  /// ones, and the head is drawn with a rim so it stays legible either way.
  static AvatarConfig random(Random random) {
    int pick(int length) => random.nextInt(length);

    return AvatarConfig(
      backgroundColorIndex: pick(backgroundColors.length),
      backdropIndex: pick(backdrops.length),
      shapeIndex: pick(shapes.length),
      eyesIndex: pick(eyes.length),
      mouthIndex: pick(mouths.length),
    );
  }

  /// The zero-based index of [part] in the paint order.
  static int paintOrder(AvatarPart part) => AvatarPart.values.indexOf(part);
}
