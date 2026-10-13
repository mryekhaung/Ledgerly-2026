import 'dart:convert';

import 'package:ledgerly/features/profile/domain/entities/avatar_catalog.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_colors.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_palette.dart';

/// Legacy enum kept for transitional compatibility until the Editor UI (Step 4)
/// fully migrates to the new tab architecture (`docs/Avatar.md` §6).
enum AvatarPart { background, backdrop, shape, eyes, mouth }

/// An immutable, serialisable avatar composition for the Open Peeps avatar system.
///
/// An avatar is defined by component part IDs and palette colors, not indices
/// (`docs/Avatar.md` §4).
///
/// Stored in the existing `app_settings` table as JSON under the `profile.avatar` key.
/// Decode never throws: unknown or legacy formats gracefully fall back to [initial].
final class AvatarConfig {
  /// Creates an avatar configuration.
  const AvatarConfig({
    this.headId = 'short1',
    this.faceId = 'calm',
    this.accessoryId,
    this.facialHairId,
    this.maskId,
    this.itemId,
    this.colors = AvatarColors.initial,
    this.version = 1,
    int? backgroundColorIndex,
    int? backdropIndex,
    int? shapeIndex,
    int? eyesIndex,
    int? mouthIndex,
  }) : _legacyBackgroundColorIndex = backgroundColorIndex,
       _legacyBackdropIndex = backdropIndex,
       _legacyShapeIndex = shapeIndex,
       _legacyEyesIndex = eyesIndex,
       _legacyMouthIndex = mouthIndex;

  /// The avatar a brand-new install starts with.
  ///
  /// Uses clean defaults: short hair (`short1`), calm expression (`calm`),
  /// no overlays, and balanced initial palette colors.
  static const AvatarConfig initial = AvatarConfig(
    headId: 'short1',
    faceId: 'calm',
    colors: AvatarColors.initial,
    backgroundColorIndex: 0,
    backdropIndex: 0,
    shapeIndex: 1,
    eyesIndex: 1,
    mouthIndex: 1,
  );

  /// ID of the head / hair variant (e.g. 'short1', 'afro', 'bun').
  final String headId;

  /// ID of the facial expression variant (e.g. 'calm', 'smile', 'cheeky').
  final String faceId;

  /// ID of the accessory overlay (e.g. 'glasses', 'sunglasses'), or null if none.
  final String? accessoryId;

  /// ID of the facial hair overlay (e.g. 'chin', 'full', 'goatee1'), or null if none.
  final String? facialHairId;

  /// ID of the mask overlay (e.g. 'medical_mask', 'respirator'), or null if none.
  final String? maskId;

  /// ID of the prop/item overlay (reserved for v2.1 original art; null for now).
  final String? itemId;

  /// Curated color slots for the avatar.
  final AvatarColors colors;

  /// Schema/catalog version number.
  final int version;

  final int? _legacyBackgroundColorIndex;
  final int? _legacyBackdropIndex;
  final int? _legacyShapeIndex;
  final int? _legacyEyesIndex;
  final int? _legacyMouthIndex;

  /// Legacy background color index mapped from `colors.background`.
  int get backgroundColorIndex {
    final legacy = _legacyBackgroundColorIndex;
    if (legacy != null) return legacy;
    final idx = AvatarPalette.backgrounds.indexOf(colors.background);
    return idx >= 0 ? idx : 0;
  }

  /// Legacy backdrop index.
  int get backdropIndex => _legacyBackdropIndex ?? 0;

  /// Legacy shape index.
  int get shapeIndex => _legacyShapeIndex ?? 1;

  /// Legacy eyes index.
  int get eyesIndex => _legacyEyesIndex ?? 1;

  /// Legacy mouth index.
  int get mouthIndex => _legacyMouthIndex ?? 1;

  /// Whether this avatar configuration is well-formed.
  bool get isValid {
    if (headId.trim().isEmpty || faceId.trim().isEmpty) return false;
    final legacyBg = _legacyBackgroundColorIndex;
    if (legacyBg != null &&
        (legacyBg < 0 || legacyBg >= AvatarCatalog.backgroundColors.length)) {
      return false;
    }
    final legacyBackdrop = _legacyBackdropIndex;
    if (legacyBackdrop != null &&
        (legacyBackdrop < 0 ||
            legacyBackdrop >= AvatarCatalog.backdrops.length)) {
      return false;
    }
    final legacyShape = _legacyShapeIndex;
    if (legacyShape != null &&
        (legacyShape < 0 || legacyShape >= AvatarCatalog.shapes.length)) {
      return false;
    }
    final legacyEyes = _legacyEyesIndex;
    if (legacyEyes != null &&
        (legacyEyes < 0 || legacyEyes >= AvatarCatalog.eyes.length)) {
      return false;
    }
    final legacyMouth = _legacyMouthIndex;
    if (legacyMouth != null &&
        (legacyMouth < 0 || legacyMouth >= AvatarCatalog.mouths.length)) {
      return false;
    }
    return true;
  }

  /// Serializes the configuration to a compact JSON string.
  String encode() => jsonEncode(toJson());

  /// Returns a JSON-serializable Map representation.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'head': headId,
    'face': faceId,
    if (accessoryId != null) 'accessory': accessoryId,
    if (facialHairId != null) 'facialHair': facialHairId,
    if (maskId != null) 'mask': maskId,
    if (itemId != null) 'item': itemId,
    'colors': colors.toJson(),
    'version': version,
    if (_legacyBackgroundColorIndex != null)
      'legacyBg': _legacyBackgroundColorIndex,
    if (_legacyBackdropIndex != null) 'legacyBackdrop': _legacyBackdropIndex,
    if (_legacyShapeIndex != null) 'legacyShape': _legacyShapeIndex,
    if (_legacyEyesIndex != null) 'legacyEyes': _legacyEyesIndex,
    if (_legacyMouthIndex != null) 'legacyMouth': _legacyMouthIndex,
  };

  /// Decodes from a JSON map, falling back safely for missing or unknown fields.
  factory AvatarConfig.fromJson(Map<String, dynamic> json) {
    final head = json['head'] as String? ?? initial.headId;
    final face = json['face'] as String? ?? initial.faceId;
    final accessory = json['accessory'] as String?;
    final facialHair = json['facialHair'] as String?;
    final mask = json['mask'] as String?;
    final item = json['item'] as String?;
    final rawColors = json['colors'];
    final colors = rawColors is Map<String, dynamic>
        ? AvatarColors.fromJson(rawColors)
        : initial.colors;
    final version = json['version'] as int? ?? 1;

    final legacyBg = json['legacyBg'] as int?;
    final legacyBackdrop = json['legacyBackdrop'] as int?;
    final legacyShape = json['legacyShape'] as int?;
    final legacyEyes = json['legacyEyes'] as int?;
    final legacyMouth = json['legacyMouth'] as int?;

    return AvatarConfig(
      headId: head.isNotEmpty ? head : initial.headId,
      faceId: face.isNotEmpty ? face : initial.faceId,
      accessoryId: (accessory != null && accessory.isNotEmpty)
          ? accessory
          : null,
      facialHairId: (facialHair != null && facialHair.isNotEmpty)
          ? facialHair
          : null,
      maskId: (mask != null && mask.isNotEmpty) ? mask : null,
      itemId: (item != null && item.isNotEmpty) ? item : null,
      colors: colors,
      version: version,
      backgroundColorIndex: legacyBg,
      backdropIndex: legacyBackdrop,
      shapeIndex: legacyShape,
      eyesIndex: legacyEyes,
      mouthIndex: legacyMouth,
    );
  }

  /// Parses an encoded string ([encode] output), or returns null when malformed.
  ///
  /// Gracefully detects legacy v1 `"a-b-c-d-e"` strings and decodes them to [initial]
  /// per `docs/Avatar.md` §4.
  static AvatarConfig? tryParse(String raw) {
    if (raw.trim().isEmpty) return null;

    // Detect legacy index-based format (e.g. "0-0-1-1-1")
    if (RegExp(r'^\d+-\d+-\d+-\d+-\d+$').hasMatch(raw.trim())) {
      return initial;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return AvatarConfig.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Creates a copy of this configuration with given fields replaced.
  AvatarConfig copyWith({
    String? headId,
    String? faceId,
    Object? accessoryId = _sentinel,
    Object? facialHairId = _sentinel,
    Object? maskId = _sentinel,
    Object? itemId = _sentinel,
    AvatarColors? colors,
    int? version,
    int? backgroundColorIndex,
    int? backdropIndex,
    int? shapeIndex,
    int? eyesIndex,
    int? mouthIndex,
  }) {
    return AvatarConfig(
      headId: headId ?? this.headId,
      faceId: faceId ?? this.faceId,
      accessoryId: identical(accessoryId, _sentinel)
          ? this.accessoryId
          : accessoryId as String?,
      facialHairId: identical(facialHairId, _sentinel)
          ? this.facialHairId
          : facialHairId as String?,
      maskId: identical(maskId, _sentinel) ? this.maskId : maskId as String?,
      itemId: identical(itemId, _sentinel) ? this.itemId : itemId as String?,
      colors: colors ?? this.colors,
      version: version ?? this.version,
      backgroundColorIndex: backgroundColorIndex ?? _legacyBackgroundColorIndex,
      backdropIndex: backdropIndex ?? _legacyBackdropIndex,
      shapeIndex: shapeIndex ?? _legacyShapeIndex,
      eyesIndex: eyesIndex ?? _legacyEyesIndex,
      mouthIndex: mouthIndex ?? _legacyMouthIndex,
    );
  }

  /// Legacy index lookup by [AvatarPart].
  int indexOf(AvatarPart part) => switch (part) {
    AvatarPart.background => backgroundColorIndex,
    AvatarPart.backdrop => backdropIndex,
    AvatarPart.shape => shapeIndex,
    AvatarPart.eyes => eyesIndex,
    AvatarPart.mouth => mouthIndex,
  };

  /// Legacy modifier returning an updated configuration.
  AvatarConfig withPart(AvatarPart part, int index) {
    return switch (part) {
      AvatarPart.background => copyWith(
        backgroundColorIndex: index,
        colors: colors.copyWith(
          background:
              AvatarPalette.backgrounds[index.clamp(
                0,
                AvatarPalette.backgrounds.length - 1,
              )],
        ),
      ),
      AvatarPart.backdrop => copyWith(backdropIndex: index),
      AvatarPart.shape => copyWith(shapeIndex: index),
      AvatarPart.eyes => copyWith(eyesIndex: index),
      AvatarPart.mouth => copyWith(mouthIndex: index),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarConfig &&
          other.headId == headId &&
          other.faceId == faceId &&
          other.accessoryId == accessoryId &&
          other.facialHairId == facialHairId &&
          other.maskId == maskId &&
          other.itemId == itemId &&
          other.colors == colors &&
          other.version == version &&
          other._legacyBackgroundColorIndex == _legacyBackgroundColorIndex &&
          other._legacyBackdropIndex == _legacyBackdropIndex &&
          other._legacyShapeIndex == _legacyShapeIndex &&
          other._legacyEyesIndex == _legacyEyesIndex &&
          other._legacyMouthIndex == _legacyMouthIndex;

  @override
  int get hashCode => Object.hash(
    headId,
    faceId,
    accessoryId,
    facialHairId,
    maskId,
    itemId,
    colors,
    version,
    _legacyBackgroundColorIndex,
    _legacyBackdropIndex,
    _legacyShapeIndex,
    _legacyEyesIndex,
    _legacyMouthIndex,
  );

  @override
  String toString() =>
      'AvatarConfig(head: $headId, face: $faceId, accessory: $accessoryId, facialHair: $facialHairId, mask: $maskId, colors: $colors)';
}

const Object _sentinel = Object();
