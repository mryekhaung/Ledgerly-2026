import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';

/// Supported shape silhouettes for the composed avatar.
enum AvatarShape {
  /// Circular avatar (default).
  circle,

  /// Rounded squircle avatar.
  squircle,
}

/// A fixed-capacity Least-Recently-Used (LRU) cache for composed SVG strings.
///
/// Spec: `docs/Avatar.md` §5 (capacity ≤ 32 entries).
final class AvatarSvgLruCache {
  AvatarSvgLruCache({this.maxEntries = 32}) : assert(maxEntries > 0);

  /// Maximum number of cached items before older items are evicted.
  final int maxEntries;

  final LinkedHashMap<String, String> _map = LinkedHashMap<String, String>();

  /// Returns the cached SVG string for [key], moving it to the most-recently-used position.
  String? get(String key) {
    final value = _map.remove(key);
    if (value != null) {
      _map[key] = value;
      return value;
    }
    return null;
  }

  /// Stores [value] under [key], evicting the oldest entry if [maxEntries] is exceeded.
  void put(String key, String value) {
    if (_map.containsKey(key)) {
      _map.remove(key);
    } else if (_map.length >= maxEntries) {
      _map.remove(_map.keys.first);
    }
    _map[key] = value;
  }

  /// The current number of cached items.
  int get length => _map.length;

  /// Checks if [key] is in cache.
  bool containsKey(String key) => _map.containsKey(key);

  /// Clears all entries from the cache.
  void clear() => _map.clear();
}

/// Composes Open Peeps vector parts into a single valid SVG string.
///
/// Spec: `docs/Avatar.md` §5, §9.2, §9.8.
/// - Canvas: 704 x 704
/// - Token replacement: `@skin`, `@clothing`, `@hair`, `@headContrast`, `@ink`, `@background`
/// - Layer draw order:
///   1. background (`@background`)
///   2. body (`base/body.svg`)
///   3. head (`head/<id>.svg`)
///   4. expression (`expression/<id>.svg`)
///   5. facial_hair (`facial_hair/<id>.svg`)
///   6. mask (`mask/<id>.svg`)
///   7. accessories (`accessories/<id>.svg`)
class AvatarSvgComposer {
  AvatarSvgComposer({
    Future<String> Function(String assetPath)? assetLoader,
    AvatarSvgLruCache? cache,
  }) : _assetLoader = assetLoader ?? rootBundle.loadString,
       _cache = cache ?? AvatarSvgLruCache(maxEntries: 32);

  /// Global singleton instance.
  static final AvatarSvgComposer instance = AvatarSvgComposer();

  final Future<String> Function(String assetPath) _assetLoader;
  final AvatarSvgLruCache _cache;
  final Map<String, String> _rawAssetCache = <String, String>{};
  final Map<String, String> _partThumbnailCache = <String, String>{};

  /// The LRU cache used by this composer.
  AvatarSvgLruCache get cache => _cache;

  /// Checks if the composed SVG for [config] is currently memoized in cache.
  String? getCached(
    AvatarConfig config, {
    AvatarShape shape = AvatarShape.circle,
  }) {
    final key = _cacheKey(config, shape);
    return _cache.get(key);
  }

  /// Returns the cached thumbnail SVG string for [group], [id], and [config] if available.
  ///
  /// Spec: `docs/Avatar.md` §5: "Part thumbnails in the editor are also cached by (group, id, colors)."
  String? getCachedPartThumbnail({
    required String group,
    required String id,
    required AvatarConfig config,
  }) {
    final key = _thumbnailKey(group, id, config);
    return _partThumbnailCache[key];
  }

  /// Composes a part thumbnail for [group], [id], and [config], caching the result.
  Future<String> composePartThumbnail({
    required String group,
    required String id,
    required AvatarConfig config,
  }) async {
    final key = _thumbnailKey(group, id, config);
    final cached = _partThumbnailCache[key];
    if (cached != null) return cached;
    final composed = await compose(config, shape: AvatarShape.circle);
    _partThumbnailCache[key] = composed;
    return composed;
  }

  String _thumbnailKey(String group, String id, AvatarConfig config) =>
      '$group:$id:${config.colors.encode()}';

  /// Composes a single SVG string for [config] and [shape].
  ///
  /// Returns the cached result immediately if available, otherwise loads the
  /// individual part SVGs, substitutes color tokens, and caches the result.
  Future<String> compose(
    AvatarConfig config, {
    AvatarShape shape = AvatarShape.circle,
  }) async {
    final key = _cacheKey(config, shape);
    final cached = _cache.get(key);
    if (cached != null) return cached;

    final buffer = StringBuffer();
    buffer.writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 704 704" fill="none" shape-rendering="auto">',
    );

    // 1. Background layer
    final bgElement = switch (shape) {
      AvatarShape.circle =>
        '<circle cx="352" cy="352" r="352" fill="@background"/>',
      AvatarShape.squircle =>
        '<rect width="704" height="704" rx="160" ry="160" fill="@background"/>',
    };
    buffer.writeln('  $bgElement');

    // 2. Base body layer
    final bodyRaw = await _loadAsset('assets/avatar/open_peeps/base/body.svg');
    buffer.writeln('  ${_extractSvgContent(bodyRaw)}');

    // 3. Head layer (transform: "matrix(.99789 0 0 1 6 -58)")
    if (config.headId.isNotEmpty) {
      final headRaw = await _loadAsset(
        'assets/avatar/open_peeps/head/${config.headId}.svg',
      );
      buffer.writeln(
        '  <g transform="matrix(.99789 0 0 1 6 -58)">${_extractSvgContent(headRaw)}</g>',
      );
    }

    // 4. Expression / Face layer (transform: "translate(351 275)")
    if (config.faceId.isNotEmpty) {
      final faceRaw = await _loadAsset(
        'assets/avatar/open_peeps/expression/${config.faceId}.svg',
      );
      buffer.writeln(
        '  <g transform="translate(351 275)">${_extractSvgContent(faceRaw)}</g>',
      );
    }

    // 5. Facial Hair layer (transform: "translate(58 333)")
    if (config.facialHairId != null && config.facialHairId!.isNotEmpty) {
      final beardRaw = await _loadAsset(
        'assets/avatar/open_peeps/facial_hair/${config.facialHairId}.svg',
      );
      buffer.writeln(
        '  <g transform="translate(58 333)">${_extractSvgContent(beardRaw)}</g>',
      );
    }

    // 6. Mask layer (transform: "translate(207 331)")
    if (config.maskId != null && config.maskId!.isNotEmpty) {
      final maskRaw = await _loadAsset(
        'assets/avatar/open_peeps/mask/${config.maskId}.svg',
      );
      buffer.writeln(
        '  <g transform="translate(207 331)">${_extractSvgContent(maskRaw)}</g>',
      );
    }

    // 7. Accessories layer (transform: "translate(190 243)")
    if (config.accessoryId != null && config.accessoryId!.isNotEmpty) {
      final accRaw = await _loadAsset(
        'assets/avatar/open_peeps/accessories/${config.accessoryId}.svg',
      );
      buffer.writeln(
        '  <g transform="translate(190 243)">${_extractSvgContent(accRaw)}</g>',
      );
    }

    buffer.writeln('</svg>');

    // Apply color token replacements
    final composed = _replaceTokens(buffer.toString(), config);
    _cache.put(key, composed);
    return composed;
  }

  String _cacheKey(AvatarConfig config, AvatarShape shape) =>
      '${config.encode()}_${shape.name}';

  Future<String> _loadAsset(String path) async {
    final cached = _rawAssetCache[path];
    if (cached != null) return cached;
    final content = await _assetLoader(path);
    _rawAssetCache[path] = content;
    return content;
  }

  String _extractSvgContent(String svg) {
    final openIdx = svg.indexOf('>');
    final closeIdx = svg.lastIndexOf('</svg>');
    if (openIdx != -1 && closeIdx != -1 && closeIdx > openIdx) {
      return svg.substring(openIdx + 1, closeIdx).trim();
    }
    return svg;
  }

  String _replaceTokens(String svg, AvatarConfig config) {
    return svg
        .replaceAll('@background', _toHex(config.colors.background))
        .replaceAll('@skin', _toHex(config.colors.skin))
        .replaceAll('@clothing', _toHex(config.colors.clothing))
        .replaceAll('@hair', _toHex(config.colors.hair))
        .replaceAll('@headContrast', _toHex(config.colors.hair))
        .replaceAll('@ink', _toHex(config.colors.ink));
  }

  static String _toHex(int argb) {
    final rgb = argb & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }
}
