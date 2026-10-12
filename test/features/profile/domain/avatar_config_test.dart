import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_catalog.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';

/// [AvatarConfig] and [AvatarCatalog] — the persisted avatar format.
///
/// The encode/parse pair is the whole storage contract: a value that round-trips
/// in tests is a value that survives an app update. Most of these cases exist to
/// pin down the *rejection* behaviour, because the datasource's only defence
/// against a corrupt row is `tryParse` returning null.
void main() {
  group('AvatarConfig.encode', () {
    test('should_join_the_five_indices_with_dashes', () {
      const config = AvatarConfig(
        backgroundColorIndex: 2,
        backdropIndex: 1,
        shapeIndex: 0,
        eyesIndex: 3,
        mouthIndex: 4,
      );

      expect(config.encode(), '2-1-0-3-4');
    });

    test('should_encode_the_initial_avatar_as_its_five_indices', () {
      // Pinned against the live [AvatarConfig.initial] rather than a hardcoded
      // literal: the default is a design choice that may be re-tuned, and this
      // test exists to prove the *encoding* is the five indices joined, not to
      // freeze which combination ships as the default.
      expect(
        AvatarConfig.initial.encode(),
        '${AvatarConfig.initial.backgroundColorIndex}-'
        '${AvatarConfig.initial.backdropIndex}-'
        '${AvatarConfig.initial.shapeIndex}-'
        '${AvatarConfig.initial.eyesIndex}-'
        '${AvatarConfig.initial.mouthIndex}',
      );
      expect(
        AvatarConfig.initial.encode(),
        matches(RegExp(r'^\d+-\d+-\d+-\d+-\d+$')),
      );
    });
  });

  group('AvatarConfig.tryParse', () {
    test('should_round_trip_every_field', () {
      const original = AvatarConfig(
        backgroundColorIndex: 7,
        backdropIndex: 3,
        shapeIndex: 2,
        eyesIndex: 1,
        mouthIndex: 0,
      );

      final parsed = AvatarConfig.tryParse(original.encode());

      expect(parsed, original);
      expect(parsed?.encode(), original.encode());
    });

    test('should_reject_a_value_with_too_few_fields', () {
      // An older build's avatar. Guessing which slot is missing is how a stored
      // avatar silently changes shape between releases, so this must fail.
      expect(AvatarConfig.tryParse('1-2-3'), isNull);
      expect(AvatarConfig.tryParse('1-2-3-4'), isNull);
      expect(AvatarConfig.tryParse(''), isNull);
    });

    test('should_reject_a_value_with_too_many_fields', () {
      expect(AvatarConfig.tryParse('1-2-3-4-5-6'), isNull);
    });

    test('should_reject_a_non_numeric_field', () {
      expect(AvatarConfig.tryParse('1-2-x-4-5'), isNull);
    });

    test('should_reject_a_negative_index', () {
      expect(AvatarConfig.tryParse('1-2--1-4-5'), isNull);
    });
  });

  group('AvatarConfig.indexOf', () {
    const config = AvatarConfig(
      backgroundColorIndex: 1,
      backdropIndex: 2,
      shapeIndex: 3,
      eyesIndex: 4,
      mouthIndex: 5,
    );

    test('should_return_the_matching_field_for_every_part', () {
      expect(config.indexOf(AvatarPart.background), 1);
      expect(config.indexOf(AvatarPart.backdrop), 2);
      expect(config.indexOf(AvatarPart.shape), 3);
      expect(config.indexOf(AvatarPart.eyes), 4);
      expect(config.indexOf(AvatarPart.mouth), 5);
    });

    test('should_cover_every_enum_value', () {
      // Guards against a new AvatarPart being added without an indexOf branch —
      // the switch would fail to compile, but this documents the intent.
      for (final part in AvatarPart.values) {
        expect(() => config.indexOf(part), returnsNormally);
      }
    });
  });

  group('AvatarConfig.withPart', () {
    test('should_change_only_the_named_part', () {
      final next = AvatarConfig.initial.withPart(AvatarPart.shape, 3);

      expect(next.shapeIndex, 3);
      expect(
        next.backgroundColorIndex,
        AvatarConfig.initial.backgroundColorIndex,
      );
      expect(next.backdropIndex, AvatarConfig.initial.backdropIndex);
      expect(next.eyesIndex, AvatarConfig.initial.eyesIndex);
      expect(next.mouthIndex, AvatarConfig.initial.mouthIndex);
    });

    test('should_replace_each_part_independently', () {
      var config = AvatarConfig.initial;
      for (var i = 0; i < AvatarPart.values.length; i++) {
        config = config.withPart(AvatarPart.values[i], i);
      }

      for (var i = 0; i < AvatarPart.values.length; i++) {
        expect(config.indexOf(AvatarPart.values[i]), i);
      }
    });

    test('should_return_an_unequal_config_when_the_index_changes', () {
      // Picks an index that is guaranteed to differ from the initial config's
      // own, so the assertion is about `withPart` and not about a stale
      // hardcoded expectation.
      final initialEyes = AvatarConfig.initial.eyesIndex;
      final changedEyes = initialEyes == 0 ? 1 : 0;

      expect(
        AvatarConfig.initial.withPart(AvatarPart.eyes, changedEyes),
        isNot(AvatarConfig.initial),
      );
    });
  });

  group('AvatarConfig.isValid', () {
    test('should_accept_the_initial_avatar', () {
      expect(AvatarConfig.initial.isValid, isTrue);
    });

    test('should_accept_the_last_option_of_every_part', () {
      final config = AvatarConfig(
        backgroundColorIndex: AvatarCatalog.backgroundColors.length - 1,
        backdropIndex: AvatarCatalog.backdrops.length - 1,
        shapeIndex: AvatarCatalog.shapes.length - 1,
        eyesIndex: AvatarCatalog.eyes.length - 1,
        mouthIndex: AvatarCatalog.mouths.length - 1,
      );

      expect(config.isValid, isTrue);
    });

    test('should_reject_an_out_of_range_part', () {
      final tooBig = AvatarConfig(
        backgroundColorIndex: AvatarCatalog.backgroundColors.length,
        backdropIndex: 0,
        shapeIndex: 0,
        eyesIndex: 0,
        mouthIndex: 0,
      );

      expect(tooBig.isValid, isFalse);
    });
  });

  group('equality', () {
    test('should_treat_two_identical_configs_as_equal', () {
      const a = AvatarConfig(
        backgroundColorIndex: 1,
        backdropIndex: 1,
        shapeIndex: 1,
        eyesIndex: 1,
        mouthIndex: 1,
      );
      const b = AvatarConfig(
        backgroundColorIndex: 1,
        backdropIndex: 1,
        shapeIndex: 1,
        eyesIndex: 1,
        mouthIndex: 1,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('should_use_the_encoded_form_in_toString', () {
      expect(
        AvatarConfig.initial.toString(),
        'AvatarConfig(${AvatarConfig.initial.encode()})',
      );
    });

    test('should_not_default_to_the_smiley_glyph', () {
      // Regression guard. The all-zeros combination — circle head, dot eyes,
      // smiling mouth — is the universal emoji glyph, and a first-run profile
      // opening on it is exactly the "why do these look like emoji?" report
      // this default was changed to fix. The default must not be that trio.
      final defaultConfig = AvatarConfig.initial;
      final isSmileyGlyph =
          defaultConfig.shapeIndex == 0 &&
          defaultConfig.eyesIndex == 0 &&
          defaultConfig.mouthIndex == 0;
      expect(isSmileyGlyph, isFalse);
    });
  });

  group('AvatarCatalog', () {
    test('should_offer_at_least_two_options_for_every_part', () {
      // A single-option slot would make the editor's swatch strip pointless.
      for (final part in AvatarPart.values) {
        expect(
          AvatarCatalog.optionCount(part),
          greaterThanOrEqualTo(2),
          reason: 'part $part needs at least two options to be worth editing',
        );
      }
    });

    test('should_list_exactly_as_many_indices_as_options', () {
      for (final part in AvatarPart.values) {
        expect(
          AvatarCatalog.optionIndices(part).length,
          AvatarCatalog.optionCount(part),
        );
      }
    });

    test('should_list_zero_based_contiguous_indices', () {
      for (final part in AvatarPart.values) {
        final indices = AvatarCatalog.optionIndices(part);
        expect(indices.first, 0);
        expect(indices.last, AvatarCatalog.optionCount(part) - 1);
      }
    });

    test('should_only_use_palette_slots_the_renderer_defines', () {
      // PaletteSlot(8) is the ink slot; slots 0..7 are the fills. A ninth would
      // silently render black, which is the failure this catches.
      for (final slot in <PaletteSlot>[
        ...AvatarCatalog.backgroundColors.map((o) => o.palette),
        ...AvatarCatalog.backdrops.map((o) => o.palette),
        ...AvatarCatalog.shapes.map((o) => o.palette),
        ...AvatarCatalog.eyes.map((o) => o.palette),
        ...AvatarCatalog.mouths.map((o) => o.palette),
      ]) {
        expect(slot.index, inInclusiveRange(0, 8));
      }
    });

    test('should_return_a_valid_avatar_from_random', () {
      // Exhaustive over a fixed seed range: `random` must never be able to
      // generate something `isValid` rejects, or the save would fail on a
      // shuffle the user did not type.
      for (var seed = 0; seed < 200; seed++) {
        final config = AvatarCatalog.random(_SeededRandom(seed));
        expect(config.isValid, isTrue, reason: 'seed $seed produced $config');
      }
    });

    test('should_return_the_same_avatar_for_the_same_seed', () {
      expect(
        AvatarCatalog.random(_SeededRandom(42)),
        AvatarCatalog.random(_SeededRandom(42)),
      );
    });

    test('should_eventually_use_every_option_in_every_part', () {
      final seen = <AvatarPart, Set<int>>{
        for (final part in AvatarPart.values) part: <int>{},
      };

      for (var seed = 0; seed < 500; seed++) {
        final config = AvatarCatalog.random(_SeededRandom(seed));
        for (final part in AvatarPart.values) {
          seen[part]!.add(config.indexOf(part));
        }
      }

      for (final part in AvatarPart.values) {
        expect(
          seen[part]!.length,
          AvatarCatalog.optionCount(part),
          reason: 'part $part never reached every option in 500 draws',
        );
      }
    });

    test('should_order_the_paint_layers_back_to_front', () {
      // The renderer paints in enum order, so background must come first and
      // mouth last. Changing the enum order changes every stored avatar.
      expect(AvatarCatalog.paintOrder(AvatarPart.background), 0);
      expect(AvatarCatalog.paintOrder(AvatarPart.backdrop), 1);
      expect(AvatarCatalog.paintOrder(AvatarPart.shape), 2);
      expect(AvatarCatalog.paintOrder(AvatarPart.eyes), 3);
      expect(AvatarCatalog.paintOrder(AvatarPart.mouth), 4);
    });
  });
}

/// A tiny deterministic `Random`, so the catalog tests do not depend on
/// `dart:math`'s implementation staying stable across SDK upgrades.
class _SeededRandom implements Random {
  _SeededRandom(this._state);

  int _state;

  @override
  int nextInt(int max) {
    // A cheap xorshift, then folded into range.
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
