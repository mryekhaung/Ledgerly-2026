import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/profile/data/datasources/avatar_svg_composer.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_colors.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';

void main() {
  group('AvatarSvgLruCache', () {
    test('should_store_and_retrieve_cached_values', () {
      final cache = AvatarSvgLruCache(maxEntries: 3);

      cache.put('a', 'svg_a');
      cache.put('b', 'svg_b');

      expect(cache.get('a'), 'svg_a');
      expect(cache.get('b'), 'svg_b');
      expect(cache.get('c'), isNull);
    });

    test('should_evict_least_recently_used_entry_at_capacity', () {
      final cache = AvatarSvgLruCache(maxEntries: 3);

      cache.put('a', 'svg_a');
      cache.put('b', 'svg_b');
      cache.put('c', 'svg_c');

      // Access 'a' so 'b' becomes the oldest
      expect(cache.get('a'), 'svg_a');

      // Insert 'd' -> 'b' should be evicted
      cache.put('d', 'svg_d');

      expect(cache.containsKey('b'), isFalse);
      expect(cache.containsKey('a'), isTrue);
      expect(cache.containsKey('c'), isTrue);
      expect(cache.containsKey('d'), isTrue);
      expect(cache.length, 3);
    });

    test('should_clear_all_entries', () {
      final cache = AvatarSvgLruCache(maxEntries: 32);
      cache.put('k1', 'v1');
      cache.put('k2', 'v2');
      expect(cache.length, 2);

      cache.clear();
      expect(cache.length, 0);
      expect(cache.get('k1'), isNull);
    });
  });

  group('AvatarSvgComposer', () {
    late AvatarSvgComposer composer;

    setUp(() {
      // Asset loader reading real files from assets/ directory during test
      composer = AvatarSvgComposer(
        assetLoader: (path) async {
          final file = File(path);
          if (file.existsSync()) {
            return file.readAsString();
          }
          throw Exception('Asset not found: $path');
        },
      );
    });

    test('should_compose_valid_svg_with_correct_layers_and_order', () async {
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

      final svg = await composer.compose(config, shape: AvatarShape.circle);

      // 1. Root SVG viewBox
      expect(
        svg,
        contains(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 704 704"',
        ),
      );

      // 2. Layer positions and ordering (docs/Avatar.md §9.2)
      final circleIdx = svg.indexOf('<circle cx="352" cy="352" r="352"');
      final headIdx = svg.indexOf('matrix(.99789 0 0 1 6 -58)');
      final faceIdx = svg.indexOf('translate(351 275)');
      final beardIdx = svg.indexOf('translate(58 333)');
      final maskIdx = svg.indexOf('translate(207 331)');
      final accIdx = svg.indexOf('translate(190 243)');

      expect(circleIdx, isNonNegative);
      expect(headIdx, isNonNegative);
      expect(faceIdx, isNonNegative);
      expect(beardIdx, isNonNegative);
      expect(maskIdx, isNonNegative);
      expect(accIdx, isNonNegative);

      // Verify draw order: background < head < face < facialHair < mask < accessories
      expect(circleIdx < headIdx, isTrue);
      expect(headIdx < faceIdx, isTrue);
      expect(faceIdx < beardIdx, isTrue);
      expect(beardIdx < maskIdx, isTrue);
      expect(maskIdx < accIdx, isTrue);
    });

    test('should_replace_all_color_tokens_with_hex_values', () async {
      const config = AvatarConfig(
        headId: 'short1',
        faceId: 'calm',
        colors: AvatarColors(
          background: 0xFFE8F1F5,
          skin: 0xFFF1C27D,
          hair: 0xFF2C1B18,
          clothing: 0xFF5B7FFF,
          ink: 0xFF000000,
        ),
      );

      final svg = await composer.compose(config);

      // Verify no remaining template tokens
      expect(svg, isNot(contains('@skin')));
      expect(svg, isNot(contains('@clothing')));
      expect(svg, isNot(contains('@hair')));
      expect(svg, isNot(contains('@headContrast')));
      expect(svg, isNot(contains('@ink')));
      expect(svg, isNot(contains('@background')));

      // Verify hex substitutions exist
      expect(svg, contains('#e8f1f5')); // background
      expect(svg, contains('#f1c27d')); // skin
      expect(svg, contains('#5b7fff')); // clothing
      expect(svg, contains('#000000')); // ink
    });

    test('should_use_squircle_background_when_requested', () async {
      const config = AvatarConfig.initial;

      final svg = await composer.compose(config, shape: AvatarShape.squircle);

      expect(svg, contains('<rect width="704" height="704" rx="160" ry="160"'));
      expect(svg, isNot(contains('<circle cx="352"')));
    });

    test('should_memoize_and_hit_cache_on_subsequent_calls', () async {
      const config = AvatarConfig(
        headId: 'bun',
        faceId: 'cheeky',
        colors: AvatarColors.initial,
      );

      expect(composer.getCached(config), isNull);

      final first = await composer.compose(config);
      final cached = composer.getCached(config);

      expect(cached, isNotNull);
      expect(cached, first);

      final second = await composer.compose(config);
      expect(identical(first, second), isTrue);
    });
  });
}
