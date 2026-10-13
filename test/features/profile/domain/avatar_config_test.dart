import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_catalog.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_colors.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_palette.dart';

/// [AvatarConfig] and [AvatarCatalog] — Open Peeps avatar system tests.
///
/// Spec: `docs/Avatar.md` §4, §8, §9.3.
void main() {
  group('AvatarConfig.encode / JSON serialization', () {
    test('should_encode_as_valid_json_with_expected_fields', () {
      const config = AvatarConfig(
        headId: 'afro',
        faceId: 'smile',
        accessoryId: 'glasses',
        facialHairId: 'chin',
        maskId: 'medical_mask',
        colors: AvatarColors(
          background: 0xFFE8F1F5,
          skin: 0xFFF1C27D,
          hair: 0xFF2C1B18,
          clothing: 0xFF5B7FFF,
          ink: 0xFF000000,
        ),
      );

      final encoded = config.encode();
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;

      expect(decoded['head'], 'afro');
      expect(decoded['face'], 'smile');
      expect(decoded['accessory'], 'glasses');
      expect(decoded['facialHair'], 'chin');
      expect(decoded['mask'], 'medical_mask');
      expect(decoded['version'], 1);
      expect(decoded['colors'], isA<Map<String, dynamic>>());
      final colors = decoded['colors'] as Map<String, dynamic>;
      expect(colors['skin'], 0xFFF1C27D);
      expect(colors['clothing'], 0xFF5B7FFF);
    });

    test('should_round_trip_cleanly_through_encode_and_tryParse', () {
      const original = AvatarConfig(
        headId: 'bun',
        faceId: 'cheeky',
        accessoryId: 'sunglasses',
        facialHairId: 'full',
        maskId: 'respirator',
        colors: AvatarColors(
          background: 0xFFFFF3E0,
          skin: 0xFFC68642,
          hair: 0xFF7D4E2D,
          clothing: 0xFFFF6B6B,
          ink: 0xFF1E232A,
        ),
      );

      final parsed = AvatarConfig.tryParse(original.encode());

      expect(parsed, original);
      expect(parsed?.headId, 'bun');
      expect(parsed?.faceId, 'cheeky');
      expect(parsed?.accessoryId, 'sunglasses');
      expect(parsed?.facialHairId, 'full');
      expect(parsed?.maskId, 'respirator');
      expect(parsed?.colors, original.colors);
    });

    test('should_omit_null_overlay_fields_from_json', () {
      const config = AvatarConfig(
        headId: 'short1',
        faceId: 'calm',
        accessoryId: null,
        facialHairId: null,
        maskId: null,
      );

      final decoded = jsonDecode(config.encode()) as Map<String, dynamic>;

      expect(decoded.containsKey('accessory'), isFalse);
      expect(decoded.containsKey('facialHair'), isFalse);
      expect(decoded.containsKey('mask'), isFalse);
      expect(decoded.containsKey('item'), isFalse);
    });
  });

  group('AvatarConfig.tryParse fallbacks and migrations', () {
    test('should_decode_legacy_dash_format_to_initial_avatar', () {
      // docs/Avatar.md §4: "unknown/old 'a-b-c-d-e' values decode to initial"
      expect(AvatarConfig.tryParse('0-0-1-1-1'), AvatarConfig.initial);
      expect(AvatarConfig.tryParse('2-1-0-3-4'), AvatarConfig.initial);
      expect(AvatarConfig.tryParse('7-3-2-1-0'), AvatarConfig.initial);
    });

    test('should_return_null_for_empty_or_whitespace_strings', () {
      expect(AvatarConfig.tryParse(''), isNull);
      expect(AvatarConfig.tryParse('   '), isNull);
    });

    test('should_return_null_for_malformed_json_strings', () {
      expect(AvatarConfig.tryParse('not-json'), isNull);
      expect(AvatarConfig.tryParse('{invalid-json}'), isNull);
      expect(AvatarConfig.tryParse('12345'), isNull);
      expect(AvatarConfig.tryParse('["array", "not", "map"]'), isNull);
    });

    test('should_fall_back_missing_required_ids_to_initial_values', () {
      const partialJson = '{"head":"","face":"","version":1}';
      final parsed = AvatarConfig.tryParse(partialJson);

      expect(parsed, isNotNull);
      expect(parsed?.headId, AvatarConfig.initial.headId);
      expect(parsed?.faceId, AvatarConfig.initial.faceId);
    });
  });

  group('AvatarConfig.isValid', () {
    test('should_accept_valid_avatar_configs', () {
      expect(AvatarConfig.initial.isValid, isTrue);
      const custom = AvatarConfig(headId: 'afro', faceId: 'smile');
      expect(custom.isValid, isTrue);
    });

    test('should_reject_empty_required_ids', () {
      const emptyHead = AvatarConfig(headId: '', faceId: 'calm');
      expect(emptyHead.isValid, isFalse);

      const emptyFace = AvatarConfig(headId: 'short1', faceId: ' ');
      expect(emptyFace.isValid, isFalse);
    });
  });

  group('AvatarColors and Palettes', () {
    test('should_contain_exact_counts_mandated_by_spec', () {
      // docs/Avatar.md §6: background 8 · outline/ink 4 · hair 10 · skin 7 · outfit 10
      expect(AvatarPalette.backgrounds.length, 8);
      expect(AvatarPalette.inks.length, 4);
      expect(AvatarPalette.hairs.length, 10);
      expect(AvatarPalette.skins.length, 7);
      expect(AvatarPalette.outfits.length, 10);
    });

    test('should_round_trip_AvatarColors_json', () {
      const colors = AvatarColors(
        background: 0xFFE8F1F5,
        skin: 0xFF694D3D,
        hair: 0xFF1A1A1A,
        clothing: 0xFF20C997,
        ink: 0xFF1E232A,
      );

      final json = colors.toJson();
      final restored = AvatarColors.fromJson(json);

      expect(restored, colors);
      expect(restored.outfit, colors.clothing);
    });
  });

  group('AvatarCatalog Open Peeps counts and validation', () {
    test('should_match_inspected_counts_from_Avatar_md_spike', () {
      // docs/Avatar.md §9.3
      expect(AvatarCatalog.heads.length, 48);
      expect(AvatarCatalog.expressions.length, 30);
      expect(AvatarCatalog.facialHairs.length, 16);
      expect(AvatarCatalog.accessories.length, 8);
      expect(AvatarCatalog.masks.length, 2);
    });

    test('should_validate_configs_against_catalog', () {
      expect(AvatarCatalog.isValidConfig(AvatarConfig.initial), isTrue);

      const invalidHead = AvatarConfig(
        headId: 'non_existent_head',
        faceId: 'calm',
      );
      expect(AvatarCatalog.isValidConfig(invalidHead), isFalse);

      const invalidAccessory = AvatarConfig(
        headId: 'short1',
        faceId: 'calm',
        accessoryId: 'non_existent_glasses',
      );
      expect(AvatarCatalog.isValidConfig(invalidAccessory), isFalse);
    });

    test('should_generate_only_valid_avatars_across_500_random_draws', () {
      // docs/Avatar.md §8: "random x500 always valid and reaches every part id; palette picks always in palette"
      for (var seed = 0; seed < 500; seed++) {
        final randomConfig = AvatarCatalog.random(_SeededRandom(seed));
        expect(
          AvatarCatalog.isValidConfig(randomConfig),
          isTrue,
          reason: 'seed $seed produced an invalid config: $randomConfig',
        );
        expect(
          AvatarPalette.backgrounds.contains(randomConfig.colors.background),
          isTrue,
        );
        expect(AvatarPalette.skins.contains(randomConfig.colors.skin), isTrue);
        expect(AvatarPalette.hairs.contains(randomConfig.colors.hair), isTrue);
        expect(
          AvatarPalette.outfits.contains(randomConfig.colors.clothing),
          isTrue,
        );
        expect(AvatarPalette.inks.contains(randomConfig.colors.ink), isTrue);
      }
    });

    test('should_be_deterministic_for_the_same_random_seed', () {
      expect(
        AvatarCatalog.random(_SeededRandom(1234)),
        AvatarCatalog.random(_SeededRandom(1234)),
      );
    });

    test('should_reach_all_variants_across_draws', () {
      final seenHeads = <String>{};
      final seenFaces = <String>{};
      final seenAccessories = <String>{};
      final seenBeards = <String>{};
      final seenMasks = <String>{};

      for (var seed = 0; seed < 1000; seed++) {
        final config = AvatarCatalog.random(Random(seed));
        seenHeads.add(config.headId);
        seenFaces.add(config.faceId);
        if (config.accessoryId != null) {
          seenAccessories.add(config.accessoryId!);
        }
        if (config.facialHairId != null) {
          seenBeards.add(config.facialHairId!);
        }
        if (config.maskId != null) {
          seenMasks.add(config.maskId!);
        }
      }

      expect(seenHeads.length, AvatarCatalog.heads.length);
      expect(seenFaces.length, AvatarCatalog.expressions.length);
      expect(seenAccessories.length, AvatarCatalog.accessories.length);
      expect(seenBeards.length, AvatarCatalog.facialHairs.length);
      expect(seenMasks.length, AvatarCatalog.masks.length);
    });
  });
}

/// A deterministic pseudo-random generator for tests.
class _SeededRandom implements Random {
  _SeededRandom(this._state);

  int _state;

  @override
  int nextInt(int max) {
    _state ^= _state << 13;
    _state ^= _state >> 7;
    _state ^= _state << 17;
    return (_state.abs()) % max;
  }

  @override
  bool nextBool() => nextInt(2) == 1;

  @override
  double nextDouble() => nextInt(1 << 20) / (1 << 20);
}
