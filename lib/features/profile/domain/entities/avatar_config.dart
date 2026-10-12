/// The parts an avatar is assembled from.
///
/// An avatar is a **composition of indexed parts**, not a picture: the user
/// picks a shape for each slot and the renderer draws them in a fixed order.
/// That is what makes "random generate" meaningful (shuffle every index) and
/// what keeps a profile a few bytes in the settings table instead of a blob.
///
/// Spec: `docs/Architecture.md` §2 (`AvatarConfig`, `AvatarCatalog`).
///
/// This file is `domain/` — pure Dart, no Flutter import
/// (`docs/Agent.md` §3.1). The catalog carries no `Color`: it stores palette
/// *indices* and the renderer resolves them against the active theme, so a dark
/// theme gets a contrast-corrected variant for free.
library;

import 'package:ledgerly/features/profile/domain/entities/avatar_catalog.dart';

/// One configurable slot on the avatar.
///
/// The order of the values is the paint order: background, then the back layer,
/// then the face, then the eyes, then the mouth. The renderer relies on that, so
/// reordering this enum changes what every stored avatar looks like — treat the
/// order as part of the persisted format.
enum AvatarPart {
  /// The circular backdrop fill.
  background,

  /// A decorative shape behind the head.
  backdrop,

  /// The head/body silhouette.
  shape,

  /// The eye pair.
  eyes,

  /// The mouth.
  mouth,
}

/// An immutable, serialisable avatar composition.
///
/// Every field is an index into the matching option list of [AvatarCatalog].
/// Indices are validated on load ([isValid]) and coerced into range, so a config
/// written by a future build with more options cannot crash the renderer — it
/// degrades to a valid avatar instead.
final class AvatarConfig {
  /// Creates an avatar configuration.
  const AvatarConfig({
    required this.backgroundColorIndex,
    required this.backdropIndex,
    required this.shapeIndex,
    required this.eyesIndex,
    required this.mouthIndex,
  });

  /// The avatar a brand-new install starts with.
  ///
  /// Not all-zeros. The first option of every slot is also the most generic one
  /// (circle head, dot eyes, smile), and that combination renders as the plain
  /// smiley glyph — a new user's profile would open on something that reads as
  /// an emoji rather than as an identity. This picks slot index 0 for the
  /// background and backdrop, but a rounded-square head with line eyes and a
  /// neutral mouth, which is legibly a *figure* first and a face second.
  ///
  /// This is a seed, not a stored value: it is only ever read before the user
  /// has saved an avatar, so existing profiles are unaffected.
  static const AvatarConfig initial = AvatarConfig(
    backgroundColorIndex: 0,
    backdropIndex: 0,
    shapeIndex: 1,
    eyesIndex: 1,
    mouthIndex: 1,
  );

  /// Index into `AvatarCatalog.backgroundColors`.
  final int backgroundColorIndex;

  /// Index into `AvatarCatalog.backdrops`.
  final int backdropIndex;

  /// Index into `AvatarCatalog.shapes`.
  final int shapeIndex;

  /// Index into `AvatarCatalog.eyes`.
  final int eyesIndex;

  /// Index into `AvatarCatalog.mouths`.
  final int mouthIndex;

  /// The stored wire form: five indices joined by dashes, e.g. `2-1-0-3-4`.
  ///
  /// Dashes rather than JSON because this is written to the `app_settings`
  /// key–value table, where a compact single value is the natural fit
  /// (`docs/DataModel.md` §7). The format is append-only: a future sixth slot
  /// appends a field and old values still parse (see [tryParse]).
  String encode() =>
      '$backgroundColorIndex-$backdropIndex-$shapeIndex-$eyesIndex-$mouthIndex';

  /// Parses [encode]'s output, or null when [value] is malformed.
  ///
  /// Returning null rather than throwing keeps a corrupt row a *decoding*
  /// problem the datasource can fall back on, never a launch failure — the same
  /// rule the settings datasource follows.
  static AvatarConfig? tryParse(String value) {
    final parts = value.split('-');
    // A shorter value is an older avatar and is rejected outright rather than
    // zero-padded: guessing which slot a missing field meant is how a stored
    // avatar silently changes shape between releases.
    if (parts.length != 5) return null;

    final indices = <int>[];
    for (final part in parts) {
      final index = int.tryParse(part);
      if (index == null || index < 0) return null;
      indices.add(index);
    }

    return AvatarConfig(
      backgroundColorIndex: indices[0],
      backdropIndex: indices[1],
      shapeIndex: indices[2],
      eyesIndex: indices[3],
      mouthIndex: indices[4],
    );
  }

  /// The index currently chosen for [part].
  int indexOf(AvatarPart part) => switch (part) {
    AvatarPart.background => backgroundColorIndex,
    AvatarPart.backdrop => backdropIndex,
    AvatarPart.shape => shapeIndex,
    AvatarPart.eyes => eyesIndex,
    AvatarPart.mouth => mouthIndex,
  };

  /// A copy with [part] set to [index].
  ///
  /// The editor cycles one slot at a time, so a per-part setter keeps it from
  /// having to name all five fields on every tap.
  AvatarConfig withPart(AvatarPart part, int index) => switch (part) {
    AvatarPart.background => AvatarConfig(
      backgroundColorIndex: index,
      backdropIndex: backdropIndex,
      shapeIndex: shapeIndex,
      eyesIndex: eyesIndex,
      mouthIndex: mouthIndex,
    ),
    AvatarPart.backdrop => AvatarConfig(
      backgroundColorIndex: backgroundColorIndex,
      backdropIndex: index,
      shapeIndex: shapeIndex,
      eyesIndex: eyesIndex,
      mouthIndex: mouthIndex,
    ),
    AvatarPart.shape => AvatarConfig(
      backgroundColorIndex: backgroundColorIndex,
      backdropIndex: backdropIndex,
      shapeIndex: index,
      eyesIndex: eyesIndex,
      mouthIndex: mouthIndex,
    ),
    AvatarPart.eyes => AvatarConfig(
      backgroundColorIndex: backgroundColorIndex,
      backdropIndex: backdropIndex,
      shapeIndex: shapeIndex,
      eyesIndex: index,
      mouthIndex: mouthIndex,
    ),
    AvatarPart.mouth => AvatarConfig(
      backgroundColorIndex: backgroundColorIndex,
      backdropIndex: backdropIndex,
      shapeIndex: shapeIndex,
      eyesIndex: eyesIndex,
      mouthIndex: index,
    ),
  };

  /// Whether every index addresses a real option in [AvatarCatalog].
  ///
  /// The renderer clamps defensively anyway, but validating on write means the
  /// stored value is only ever something the editor could have produced.
  bool get isValid => AvatarPart.values.every(
    (part) => indexOf(part) < AvatarCatalog.optionCount(part),
  );

  @override
  bool operator ==(Object other) =>
      other is AvatarConfig &&
      other.backgroundColorIndex == backgroundColorIndex &&
      other.backdropIndex == backdropIndex &&
      other.shapeIndex == shapeIndex &&
      other.eyesIndex == eyesIndex &&
      other.mouthIndex == mouthIndex;

  @override
  int get hashCode => Object.hash(
    backgroundColorIndex,
    backdropIndex,
    shapeIndex,
    eyesIndex,
    mouthIndex,
  );

  @override
  String toString() => 'AvatarConfig(${encode()})';
}
