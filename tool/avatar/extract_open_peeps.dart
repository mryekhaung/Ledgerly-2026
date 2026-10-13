// Build-time extractor for the Avatar v2 art (docs/Avatar.md Â§3, Â§9).
//
// Turns the DiceBear `open-peeps` definition (CC0 1.0, Open Peeps by Pablo
// Stanley) into committed assets:
//
//   assets/avatar/open_peeps/
//     LICENSE.txt Â· manifest.json Â· base/body.svg
//     head/<id>.svg Â· expression/<id>.svg Â· facial_hair/<id>.svg
//     accessories/<id>.svg Â· mask/<id>.svg
//
// Run from the repo root (pure Dart, no Flutter toolchain needed):
//
//   dart run tool/avatar/extract_open_peeps.dart
//
// The output is deterministic and idempotent: same source in, byte-identical
// files out (no timestamps, no tool versions, no absolute paths), so re-running
// leaves `git status` clean.
//
// The logic lives in [buildPlan] (pure, no file I/O) so tests can call it
// directly; [writePlan] is the only function that touches the disk.
import 'dart:convert';
import 'dart:io';

/// Version of the `manifest.json` layout. Bump when the shape changes.
const int manifestSchemaVersion = 1;

/// Date the CC0 1.0 license was verified on dicebear.com/licenses
/// (docs/Versions.md Â§Avatar). A constant, never `DateTime.now()`.
const String licenseVerifiedOn = '2026-10-12';

/// Source colour group name -> output token (docs/Avatar.md Â§9.4, Â§9.8).
///
/// The source calls the hair slot `headContrast`; we expose it as `@hair`.
const Map<String, String> tokenBySourceColor = <String, String>{
  'skin': '@skin',
  'clothing': '@clothing',
  'headContrast': '@hair',
  'ink': '@ink',
};

/// Human role of each token, in manifest order. `@background` is composer-only.
const Map<String, String> tokenRoles = <String, String>{
  '@skin': 'Skin tone',
  '@clothing': 'Outfit',
  '@hair': 'Hair',
  '@ink': 'Outline',
  '@background': 'Background',
};

/// Literal fills that are intentional local accents: passed through untouched.
const List<String> allowedLiteralFills = <String>[
  '#000000',
  '#9ddadb',
  '#ff6c6c',
  '#ff8181',
  '#ffffff',
  'none',
];

/// Groups that must exist in the source `components` object.
const List<String> _expectedGroups = <String>[
  'head',
  'expression',
  'facialHair',
  'accessories',
  'mask',
];

const Map<String, List<String>> _elementAttributes = <String, List<String>>{
  'path': <String>['d'],
  'ellipse': <String>['cx', 'cy', 'rx', 'ry'],
  'circle': <String>['cx', 'cy', 'r'],
};

const List<String> _paintAttributes = <String>[
  'fill',
  'fill-rule',
  'clip-rule',
];

const List<String> _allowedFillRules = <String>['evenodd', 'nonzero'];

const String _idRule =
    'Source variant key -> lowercase snake_case. An underscore is inserted '
    'before an uppercase letter that follows a lowercase letter or a digit, '
    'and before the last capital of an acronym that precedes a lowercase '
    'letter; digits stay attached to the preceding word (lovingGrin1 -> '
    'loving_grin1, smileLOL -> smile_lol, facialHair -> facial_hair). Ids are '
    'persisted by the app and are NEVER renamed.';

/// Raised for any source problem; the CLI turns it into a non-zero exit.
final class ExtractionException implements Exception {
  /// Creates an exception carrying a human-readable [message].
  const ExtractionException(this.message);

  /// Names the offending group/variant/element.
  final String message;

  @override
  String toString() => 'ExtractionException: $message';
}

/// Everything the extractor will write: relative path (forward slashes) ->
/// file content. Keys are sorted, so iteration order is deterministic.
final class ExtractionPlan {
  /// Creates a plan from already sorted [files].
  const ExtractionPlan(this.files);

  /// Relative path -> UTF-8 text content (LF line endings).
  final Map<String, String> files;
}

// ---------------------------------------------------------------------------
// Typed JSON access (strict-casts friendly, with a location in every error).
// ---------------------------------------------------------------------------

Map<String, Object?> _map(Object? value, String where) {
  if (value is Map<String, Object?>) return value;
  if (value is Map<Object?, Object?>) {
    return value.map((key, v) => MapEntry(key.toString(), v));
  }
  throw ExtractionException('$where: expected an object');
}

List<Object?> _list(Object? value, String where) {
  if (value is List<Object?>) return value;
  throw ExtractionException('$where: expected an array');
}

String _string(Object? value, String where) {
  if (value is String) return value;
  throw ExtractionException('$where: expected a string');
}

int _int(Object? value, String where) {
  if (value is int) return value;
  if (value is double && value == value.truncateToDouble()) {
    return value.toInt();
  }
  throw ExtractionException('$where: expected an integer');
}

// ---------------------------------------------------------------------------
// Naming and number/XML formatting.
// ---------------------------------------------------------------------------

bool _isUpper(int c) => c >= 0x41 && c <= 0x5a;
bool _isLower(int c) => c >= 0x61 && c <= 0x7a;
bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

/// Converts a source key (`lovingGrin1`, `facialHair`) to stable snake_case.
///
/// See the id rule recorded in `manifest.json`. Throws for keys that are not
/// plain ASCII alphanumerics starting with a letter.
String toSnakeCase(String key) {
  if (!RegExp(r'^[A-Za-z][A-Za-z0-9]*$').hasMatch(key)) {
    throw ExtractionException('key "$key": not a plain alphanumeric key');
  }
  final codes = key.codeUnits;
  final out = StringBuffer();
  for (var i = 0; i < codes.length; i++) {
    final c = codes[i];
    if (_isUpper(c) && i > 0) {
      final prev = codes[i - 1];
      final startsWord = _isLower(prev) || _isDigit(prev);
      final endsAcronym =
          _isUpper(prev) && i + 1 < codes.length && _isLower(codes[i + 1]);
      if (startsWord || endsAcronym) out.write('_');
    }
    out.writeCharCode(_isUpper(c) ? c + 0x20 : c);
  }
  return out.toString();
}

/// Canonical number formatting: shortest round-trip, "." separator, no
/// exponent, no trailing ".0".
///
/// The source stores some geometry values as numeric strings ("135"); those
/// are parsed first so both spellings produce the same output.
String _formatNumber(Object? raw, String where) {
  var value = raw;
  if (value is String && RegExp(r'^-?\d+(\.\d+)?$').hasMatch(value)) {
    value = num.parse(value);
  }
  if (value is int) return value.toString();
  if (value is double && value.isFinite) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    final text = value.toString();
    if (!text.contains('e') && !text.contains('E')) return text;
  }
  throw ExtractionException('$where: unsupported number "$value"');
}

String _escapeAttribute(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

// ---------------------------------------------------------------------------
// Colour handling.
// ---------------------------------------------------------------------------

/// Resolves a source `fill` to its output form or throws loudly.
String _resolveFill(Object? fill, String where) {
  if (fill is String) {
    if (allowedLiteralFills.contains(fill)) return fill;
    throw ExtractionException('$where: literal colour "$fill" is not allowed');
  }
  if (fill is Map<Object?, Object?>) {
    final data = _map(fill, where);
    final type = data['type'];
    final name = data['name'];
    if (type != 'color' || name is! String) {
      throw ExtractionException('$where: unsupported fill object $fill');
    }
    final token = tokenBySourceColor[name];
    if (token == null) {
      throw ExtractionException('$where: unknown colour name "$name"');
    }
    return token;
  }
  throw ExtractionException('$where: missing or unsupported fill');
}

// ---------------------------------------------------------------------------
// SVG rendering.
// ---------------------------------------------------------------------------

String _renderElement(Map<String, Object?> element, String where) {
  if (element['type'] != 'element') {
    throw ExtractionException('$where: expected type "element"');
  }
  final name = _string(element['name'], '$where.name');
  final geometry = _elementAttributes[name];
  if (geometry == null) {
    throw ExtractionException('$where: unsupported element "$name"');
  }
  final attributes = _map(element['attributes'], '$where.attributes');
  final known = <String>{...geometry, ..._paintAttributes};
  for (final key in attributes.keys) {
    if (!known.contains(key)) {
      throw ExtractionException('$where: unsupported attribute "$key"');
    }
  }

  final out = StringBuffer('<$name');
  for (final key in geometry) {
    final value = attributes[key];
    if (value == null) {
      throw ExtractionException('$where: missing attribute "$key"');
    }
    final text = key == 'd'
        ? _string(value, '$where.$key')
        : _formatNumber(value, '$where.$key');
    out.write(' $key="${_escapeAttribute(text)}"');
  }
  out.write(
    ' fill="${_escapeAttribute(_resolveFill(attributes['fill'], where))}"',
  );
  for (final key in const <String>['fill-rule', 'clip-rule']) {
    final value = attributes[key];
    if (value == null) continue;
    final text = _string(value, '$where.$key');
    if (!_allowedFillRules.contains(text)) {
      throw ExtractionException('$where.$key: unsupported value "$text"');
    }
    out.write(' $key="$text"');
  }
  out.write('/>');
  return out.toString();
}

String _renderSvg({
  required int width,
  required int height,
  required Map<String, String> rootAttributes,
  required List<String> body,
}) {
  final out = StringBuffer()
    ..write('<svg xmlns="http://www.w3.org/2000/svg" ')
    ..write('viewBox="0 0 $width $height"');
  for (final entry in rootAttributes.entries) {
    out.write(' ${entry.key}="${_escapeAttribute(entry.value)}"');
  }
  out.write('>\n');
  for (final line in body) {
    out.write('  $line\n');
  }
  out.write('</svg>\n');
  return out.toString();
}

/// Validates the global `attributes` block and returns it in fixed order.
Map<String, String> _rootAttributes(Object? raw) {
  final source = _map(raw, 'attributes');
  const allowedKeys = <String>['fill', 'shape-rendering'];
  for (final key in source.keys) {
    if (!allowedKeys.contains(key)) {
      throw ExtractionException('attributes: unsupported attribute "$key"');
    }
  }
  final result = <String, String>{};
  for (final key in allowedKeys) {
    final value = source[key];
    if (value == null) continue;
    final text = _string(value, 'attributes.$key');
    if (key == 'fill') {
      _resolveFill(text, 'attributes.fill');
    } else if (text != 'auto') {
      throw ExtractionException('attributes.$key: unsupported value "$text"');
    }
    result[key] = text;
  }
  return result;
}

// ---------------------------------------------------------------------------
// Plan.
// ---------------------------------------------------------------------------

/// Builds the full output tree from the decoded `open-peeps.json` [source].
///
/// Pure: no file I/O, no clock. Throws [ExtractionException] on anything that
/// is not understood, never passing unknown data through silently.
ExtractionPlan buildPlan(Map<String, Object?> source) {
  final meta = _map(source['meta'], 'meta');
  final license = _map(meta['license'], 'meta.license');
  final licenseName = _string(license['name'], 'meta.license.name');
  if (!licenseName.contains('CC0')) {
    throw ExtractionException(
      'meta.license.name: expected CC0, found "$licenseName"',
    );
  }
  final creator = _map(meta['creator'], 'meta.creator');
  final origin = _map(meta['source'], 'meta.source');

  final canvas = _map(source['canvas'], 'canvas');
  final canvasWidth = _int(canvas['width'], 'canvas.width');
  final canvasHeight = _int(canvas['height'], 'canvas.height');
  final rootAttributes = _rootAttributes(source['attributes']);

  final components = _map(source['components'], 'components');
  for (final key in components.keys) {
    if (!_expectedGroups.contains(key)) {
      throw ExtractionException('components.$key: unexpected group');
    }
  }
  for (final key in _expectedGroups) {
    if (!components.containsKey(key)) {
      throw ExtractionException('components.$key: group is missing');
    }
  }

  final colorSource = _map(source['colors'], 'colors');
  for (final key in colorSource.keys) {
    if (!tokenBySourceColor.containsKey(key)) {
      throw ExtractionException('colors.$key: unknown colour name');
    }
  }

  final files = <String, String>{};
  final layerOrder = <Object?>[];
  final groupTransforms = <String, String?>{};
  final bodyLines = <String>[];

  // Canvas: leading plain elements form the body; the rest are components.
  final canvasElements = _list(canvas['elements'], 'canvas.elements');
  var sawComponent = false;
  for (var i = 0; i < canvasElements.length; i++) {
    final where = 'canvas.elements[$i]';
    final entry = _map(canvasElements[i], where);
    final type = entry['type'];
    if (type == 'element') {
      if (sawComponent) {
        throw ExtractionException(
          '$where: a body element after a component is not supported',
        );
      }
      final line = _renderElement(entry, where);
      bodyLines.add(line);
      final attributes = _map(entry['attributes'], '$where.attributes');
      layerOrder.add(<String, Object?>{
        'order': i + 1,
        'type': 'element',
        'name': 'body_${bodyLines.length}',
        'file': 'base/body.svg',
        'fill': _resolveFill(attributes['fill'], where),
        'transform': null,
      });
    } else if (type == 'component') {
      sawComponent = true;
      final sourceName = _string(entry['name'], '$where.name');
      if (!_expectedGroups.contains(sourceName)) {
        throw ExtractionException('$where: unknown component "$sourceName"');
      }
      final attributes = _map(entry['attributes'], '$where.attributes');
      for (final key in attributes.keys) {
        if (key != 'transform') {
          throw ExtractionException('$where: unsupported attribute "$key"');
        }
      }
      final transform = attributes['transform'];
      final text = transform == null
          ? null
          : _string(transform, '$where.attributes.transform');
      groupTransforms[sourceName] = text;
      layerOrder.add(<String, Object?>{
        'order': i + 1,
        'type': 'component',
        'name': toSnakeCase(sourceName),
        'file': null,
        'fill': null,
        'transform': text,
      });
    } else {
      throw ExtractionException('$where: unsupported type "$type"');
    }
  }
  for (final key in _expectedGroups) {
    if (!groupTransforms.containsKey(key)) {
      throw ExtractionException('canvas: component "$key" is not placed');
    }
  }
  if (bodyLines.isEmpty) {
    throw const ExtractionException('canvas: no body elements found');
  }

  files['base/body.svg'] = _renderSvg(
    width: canvasWidth,
    height: canvasHeight,
    rootAttributes: rootAttributes,
    body: bodyLines,
  );

  // Component groups.
  final groups = <Object?>[];
  for (final sourceKey in _expectedGroups) {
    final groupName = toSnakeCase(sourceKey);
    final where = 'components.$sourceKey';
    final group = _map(components[sourceKey], where);
    final width = _int(group['width'], '$where.width');
    final height = _int(group['height'], '$where.height');
    final probability = group['probability'];
    if (probability != null && probability is! int) {
      throw ExtractionException('$where.probability: expected an integer');
    }
    final variants = _map(group['variants'], '$where.variants');

    final idToSource = <String, String>{};
    for (final variantKey in variants.keys) {
      final id = toSnakeCase(variantKey);
      final clash = idToSource[id];
      if (clash != null) {
        throw ExtractionException(
          '$where.variants: "$variantKey" and "$clash" both map to id "$id"',
        );
      }
      idToSource[id] = variantKey;
    }
    final ids = idToSource.keys.toList()..sort();

    for (final id in ids) {
      final variantKey = idToSource[id]!;
      final variantWhere = '$where.variants.$variantKey';
      final variant = _map(variants[variantKey], variantWhere);
      final elements = _list(variant['elements'], '$variantWhere.elements');
      if (elements.isEmpty) {
        throw ExtractionException('$variantWhere: no elements');
      }
      final lines = <String>[
        for (var i = 0; i < elements.length; i++)
          _renderElement(
            _map(elements[i], '$variantWhere.elements[$i]'),
            '$variantWhere.elements[$i]',
          ),
      ];
      files['$groupName/$id.svg'] = _renderSvg(
        width: width,
        height: height,
        rootAttributes: rootAttributes,
        body: lines,
      );
    }

    groups.add(<String, Object?>{
      'name': groupName,
      'dir': groupName,
      'sourceKey': sourceKey,
      'width': width,
      'height': height,
      'transform': groupTransforms[sourceKey],
      'optional': probability != null,
      'probability': probability,
      'ids': ids,
      'sourceKeys': <String, Object?>{for (final id in ids) id: idToSource[id]},
    });
  }

  // Colours: output token -> role + the source default values.
  final colors = <String, Object?>{};
  for (final entry in tokenRoles.entries) {
    final sourceName = tokenBySourceColor.entries
        .where((e) => e.value == entry.key)
        .map((e) => e.key)
        .firstOrNull;
    final values = sourceName == null
        ? const <Object?>[]
        : _list(
            _map(colorSource[sourceName], 'colors.$sourceName')['values'],
            'colors.$sourceName.values',
          );
    colors[entry.key] = <String, Object?>{
      'role': entry.value,
      'sourceName': sourceName,
      'composerOnly': sourceName == null,
      'sourceValues': values,
    };
  }

  final creatorName = _string(creator['name'], 'meta.creator.name');
  final creatorUrl = _string(creator['url'], 'meta.creator.url');
  final originName = _string(origin['name'], 'meta.source.name');
  final originUrl = _string(origin['url'], 'meta.source.url');
  final licenseUrl = _string(license['url'], 'meta.license.url');
  final licenseText = _string(license['text'], 'meta.license.text');

  final optionalGroups = <Object?>[
    for (final g in groups)
      if (_map(g, 'group')['optional'] == true) _map(g, 'group')['name'],
  ];
  final requiredGroups = <Object?>[
    for (final g in groups)
      if (_map(g, 'group')['optional'] != true) _map(g, 'group')['name'],
  ];

  final manifest = <String, Object?>{
    'schemaVersion': manifestSchemaVersion,
    'idRule': _idRule,
    'canvas': <String, Object?>{'width': canvasWidth, 'height': canvasHeight},
    'base': <String, Object?>{
      'file': 'base/body.svg',
      'width': canvasWidth,
      'height': canvasHeight,
    },
    'layerOrder': layerOrder,
    'groups': groups,
    'colors': colors,
    'literalFills': allowedLiteralFills,
    'optionality': <String, Object?>{
      'requiredGroups': requiredGroups,
      'optionalGroups': optionalGroups,
      'noneTile': 'synthetic: optional groups get a "none" tile, no file',
    },
    'license': <String, Object?>{
      'name': licenseName,
      'url': licenseUrl,
      'creator': creatorName,
      'creatorUrl': creatorUrl,
      'source': originName,
      'sourceUrl': originUrl,
      'verifiedOn': licenseVerifiedOn,
    },
  };
  // Key order is insertion order by construction (not a hash dump), so the
  // output is stable.
  files['manifest.json'] =
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n';

  files['LICENSE.txt'] = [
    '$originName - avatar art',
    '',
    'License: $licenseName',
    '         $licenseUrl',
    'Creator: $creatorName ($creatorUrl)',
    'Source:  $originName ($originUrl)',
    '',
    licenseText,
    '',
    'The SVG parts in this directory are extracted at build time from the',
    'DiceBear "open-peeps" style definition by tool/avatar/extract_open_peeps.dart.',
    '',
  ].join('\n');

  final sortedKeys = files.keys.toList()..sort();
  return ExtractionPlan(<String, String>{
    for (final key in sortedKeys) key: files[key]!,
  });
}

/// Writes [plan] under [outDir] and removes files the plan no longer lists.
///
/// Idempotent: unchanged files are not rewritten. All directory listings are
/// sorted before use. Returns the sorted relative paths that were written.
List<String> writePlan(ExtractionPlan plan, Directory outDir) {
  final written = <String>[];
  outDir.createSync(recursive: true);
  final root = outDir.absolute.path.replaceAll(r'\', '/');
  final prefix = root.endsWith('/') ? root : '$root/';

  for (final entry in plan.files.entries) {
    final file = File('$prefix${entry.key}');
    file.parent.createSync(recursive: true);
    if (file.existsSync() && file.readAsStringSync() == entry.value) continue;
    file.writeAsStringSync(entry.value);
    written.add(entry.key);
  }

  final onDisk = outDir.listSync(recursive: true).whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in onDisk) {
    final relative = file.absolute.path
        .replaceAll(r'\', '/')
        .substring(prefix.length);
    if (!plan.files.containsKey(relative)) file.deleteSync();
  }
  return written;
}

/// CLI entry point: reads the committed source, writes the committed assets.
void main(List<String> args) {
  final root = File.fromUri(Platform.script).parent.parent.parent;
  final sourceFile = File('${root.path}/tool/avatar/source/open-peeps.json');
  final outDir = Directory('${root.path}/assets/avatar/open_peeps');

  try {
    if (!sourceFile.existsSync()) {
      throw ExtractionException('source not found: tool/avatar/source/');
    }
    final decoded = jsonDecode(sourceFile.readAsStringSync());
    final plan = buildPlan(_map(decoded, 'document'));
    final written = writePlan(plan, outDir);
    stdout.writeln(
      'extract_open_peeps: ${plan.files.length} files, '
      '${written.length} written, ${plan.files.length - written.length} '
      'unchanged.',
    );
  } on ExtractionException catch (error) {
    stderr.writeln('extract_open_peeps: FAILED: ${error.message}');
    exit(1);
  } on FormatException catch (error) {
    stderr.writeln(
      'extract_open_peeps: FAILED: invalid JSON: ${error.message}',
    );
    exit(1);
  }
}
