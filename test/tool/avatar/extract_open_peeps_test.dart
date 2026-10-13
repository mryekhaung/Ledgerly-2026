import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The extractor lives in tool/ (outside lib/), so it cannot be a package: import.
// ignore: always_use_package_imports
import '../../../tool/avatar/extract_open_peeps.dart';

/// Tests for the Avatar v2 build-time extractor (docs/Avatar.md Â§3, Â§8).
///
/// They run from the repo root (as `flutter test` does) and read the committed
/// `tool/avatar/source/open-peeps.json` + `assets/avatar/open_peeps/`.
const String _sourcePath = 'tool/avatar/source/open-peeps.json';
const String _assetsPath = 'assets/avatar/open_peeps';

const Map<String, int> _expectedCounts = <String, int>{
  'head': 48,
  'expression': 30,
  'facial_hair': 16,
  'accessories': 8,
  'mask': 2,
};

const Set<String> _tokens = <String>{'@skin', '@clothing', '@hair', '@ink'};

Map<String, Object?> _obj(Object? value) => value! as Map<String, Object?>;

List<Object?> _arr(Object? value) => value! as List<Object?>;

Map<String, Object?> _loadSource() =>
    _obj(jsonDecode(File(_sourcePath).readAsStringSync()));

Map<String, Object?> _loadManifest() => _obj(
  jsonDecode(File('$_assetsPath/manifest.json').readAsStringSync()),
);

/// Every file under [root] as sorted forward-slash relative paths.
///
/// `Directory.list()` order is platform-defined, so it is always sorted here.
List<String> _filesUnder(String root) {
  final prefix = Directory(root).absolute.path.replaceAll(r'\', '/');
  final paths = Directory(root)
      .listSync(recursive: true)
      .whereType<File>()
      .map(
        (file) => file.absolute.path
            .replaceAll(r'\', '/')
            .substring(prefix.length + 1),
      )
      .toList()
    ..sort();
  return paths;
}

/// Reads [path] with CRLF folded to LF (Windows checkouts use autocrlf).
String _read(String path) =>
    File(path).readAsStringSync().replaceAll('\r\n', '\n');

/// Minimal strict well-formedness check for the extractor's SVG subset: only
/// elements with quoted attributes, no text nodes, one balanced root.
void _expectWellFormed(String xml, String name) {
  final tag = RegExp(
    r'<(/?)([A-Za-z][\w-]*)((?:\s+[\w:-]+="[^"<&]*(?:&(?:amp|lt|gt|quot);[^"<&]*)*")*)\s*(/?)>',
  );
  final stack = <String>[];
  var position = 0;
  var rootClosed = false;
  String? root;
  for (final match in tag.allMatches(xml)) {
    expect(
      xml.substring(position, match.start).trim(),
      isEmpty,
      reason: '$name: unexpected text outside tags',
    );
    position = match.end;
    expect(rootClosed, isFalse, reason: '$name: content after the root');
    final closing = match.group(1) == '/';
    final selfClosing = match.group(4) == '/';
    final tagName = match.group(2)!;
    root ??= tagName;
    if (closing) {
      expect(stack, isNotEmpty, reason: '$name: stray </$tagName>');
      expect(stack.removeLast(), tagName, reason: '$name: mismatched tag');
    } else if (!selfClosing) {
      stack.add(tagName);
    }
    if (stack.isEmpty) rootClosed = true;
  }
  expect(
    xml.substring(position).trim(),
    isEmpty,
    reason: '$name: trailing garbage',
  );
  expect(stack, isEmpty, reason: '$name: unclosed tags');
  expect(root, 'svg', reason: '$name: root element');
}

String _viewBox(String svg) =>
    RegExp(r'<svg[^>]*\sviewBox="([^"]*)"').firstMatch(svg)!.group(1)!;

void main() {
  late Map<String, Object?> manifest;

  setUpAll(() {
    manifest = _loadManifest();
  });

  group('manifest and files', () {
    test('should_have_exact_counts_when_reading_the_manifest', () {
      final groups = {
        for (final g in _arr(manifest['groups']))
          _obj(g)['name']! as String: _arr(_obj(g)['ids']).length,
      };
      expect(groups, _expectedCounts);
      expect(manifest['schemaVersion'], manifestSchemaVersion);
    });

    test('should_have_a_file_for_every_id_and_no_orphans', () {
      final expected = <String>{
        'LICENSE.txt',
        'manifest.json',
        'base/body.svg',
        for (final g in _arr(manifest['groups']))
          for (final id in _arr(_obj(g)['ids']))
            '${_obj(g)['dir']}/$id.svg',
      };
      final onDisk = _filesUnder(_assetsPath);

      expect(onDisk.toSet(), expected, reason: 'manifest <-> disk mismatch');
      expect(onDisk, hasLength(expected.length));
      for (final entry in _expectedCounts.entries) {
        expect(
          onDisk.where((p) => p.startsWith('${entry.key}/')),
          hasLength(entry.value),
          reason: 'file count for ${entry.key}',
        );
      }
      expect(onDisk.where((p) => p.startsWith('base/')), hasLength(1));
    });

    test('should_not_write_a_file_for_the_synthetic_none_tile', () {
      expect(
        _filesUnder(_assetsPath).where((p) => p.contains('none')),
        isEmpty,
      );
      final optionality = _obj(manifest['optionality']);
      expect(
        _arr(optionality['optionalGroups']),
        <Object?>['facial_hair', 'accessories', 'mask'],
      );
      expect(_arr(optionality['requiredGroups']), <Object?>[
        'head',
        'expression',
      ]);
    });

    test('should_list_the_eight_layers_in_draw_order_with_transforms', () {
      final layers = _arr(manifest['layerOrder']).map(_obj).toList();
      expect(layers.map((l) => l['order']), [1, 2, 3, 4, 5, 6, 7, 8]);
      expect(layers.skip(3).map((l) => l['name']), <Object?>[
        'head',
        'expression',
        'facial_hair',
        'mask',
        'accessories',
      ]);
      expect(layers[3]['transform'], 'matrix(.99789 0 0 1 6 -58)');
      expect(layers[4]['transform'], 'translate(351 275)');
      expect(layers[5]['transform'], 'translate(58 333)');
      expect(layers[6]['transform'], 'translate(207 331)');
      expect(layers[7]['transform'], 'translate(190 243)');
      expect(layers.take(3).map((l) => l['fill']), <Object?>[
        '@skin',
        '@clothing',
        '#000000',
      ]);
    });
  });

  group('svg files', () {
    test('should_be_well_formed_with_matching_viewbox_when_parsed', () {
      final canvas = _obj(manifest['canvas']);
      final body = _read('$_assetsPath/base/body.svg');
      _expectWellFormed(body, 'base/body.svg');
      expect(_viewBox(body), '0 0 ${canvas['width']} ${canvas['height']}');

      for (final g in _arr(manifest['groups']).map(_obj)) {
        for (final id in _arr(g['ids'])) {
          final path = '${g['dir']}/$id.svg';
          final svg = _read('$_assetsPath/$path');
          _expectWellFormed(svg, path);
          expect(
            _viewBox(svg),
            '0 0 ${g['width']} ${g['height']}',
            reason: path,
          );
        }
      }
    });

    test('should_contain_only_whitelisted_colours_when_scanned', () {
      final fillPattern = RegExp(r'\sfill="([^"]*)"');
      final tokenPattern = RegExp(r'@[A-Za-z]+');
      final hexPattern = RegExp(r'#[0-9a-fA-F]{3,8}');
      final allowedFills = <String>{..._tokens, ...allowedLiteralFills};

      for (final path in _filesUnder(_assetsPath).where(
        (p) => p.endsWith('.svg'),
      )) {
        final svg = _read('$_assetsPath/$path');
        for (final m in fillPattern.allMatches(svg)) {
          expect(allowedFills, contains(m.group(1)), reason: path);
        }
        for (final m in tokenPattern.allMatches(svg)) {
          expect(_tokens, contains(m.group(0)), reason: '$path token');
        }
        for (final m in hexPattern.allMatches(svg)) {
          expect(
            allowedLiteralFills,
            contains(m.group(0)!.toLowerCase()),
            reason: '$path literal',
          );
        }
        expect(svg, isNot(contains('headContrast')), reason: path);
        expect(svg, isNot(contains('@background')), reason: path);
        expect(svg, isNot(contains('stroke')), reason: path);
      }
    });
  });

  group('determinism', () {
    test('should_be_byte_identical_when_extracting_into_two_temp_dirs', () {
      final first = Directory.systemTemp.createTempSync('open_peeps_a_');
      final second = Directory.systemTemp.createTempSync('open_peeps_b_');
      addTearDown(() {
        first.deleteSync(recursive: true);
        second.deleteSync(recursive: true);
      });

      writePlan(buildPlan(_loadSource()), first);
      writePlan(buildPlan(_loadSource()), second);

      final firstFiles = _filesUnder(first.path);
      expect(firstFiles, _filesUnder(second.path));
      for (final path in firstFiles) {
        expect(
          File('${first.path}/$path').readAsBytesSync(),
          File('${second.path}/$path').readAsBytesSync(),
          reason: path,
        );
      }
    });

    test('should_write_nothing_when_run_again_into_the_same_dir', () {
      final dir = Directory.systemTemp.createTempSync('open_peeps_c_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final plan = buildPlan(_loadSource());
      expect(writePlan(plan, dir), hasLength(plan.files.length));
      expect(writePlan(plan, dir), isEmpty);
    });

    test('should_match_the_committed_assets_when_the_plan_is_rebuilt', () {
      final plan = buildPlan(_loadSource());

      expect(plan.files.keys.toList(), _filesUnder(_assetsPath));
      for (final entry in plan.files.entries) {
        expect(
          _read('$_assetsPath/${entry.key}'),
          entry.value,
          reason: '${entry.key} is stale; re-run the extractor',
        );
      }
    });

    test('should_contain_no_timestamp_or_absolute_path_when_emitted', () {
      for (final content in buildPlan(_loadSource()).files.values) {
        expect(content, isNot(contains(r'C:\')));
        expect(content, isNot(contains('/Users/')));
        expect(content, isNot(contains('\r')));
        expect(content, isNot(matches(RegExp(r'20\d\d-\d\d-\d\dT'))));
      }
    });
  });

  group('license', () {
    test('should_name_cc0_and_pablo_stanley_when_reading_license_txt', () {
      final text = _read('$_assetsPath/LICENSE.txt');
      expect(text, contains('CC0 1.0'));
      expect(text, contains('Pablo Stanley'));
      expect(text, contains('Open Peeps'));
      final license = _obj(manifest['license']);
      expect(license['name'], 'CC0 1.0');
      expect(license['creator'], 'Pablo Stanley');
      expect(license['source'], 'Open Peeps');
      expect(license['verifiedOn'], isNotEmpty);
    });
  });

  group('failure modes', () {
    Map<String, Object?> firstHeadElementAttributes(Map<String, Object?> doc) {
      final head = _obj(_obj(doc['components'])['head']);
      final afro = _obj(_obj(head['variants'])['afro']);
      return _obj(_obj(_arr(afro['elements']).first)['attributes']);
    }

    test('should_fail_loudly_when_a_literal_colour_is_not_whitelisted', () {
      final doc = _loadSource();
      firstHeadElementAttributes(doc)['fill'] = '#123456';

      expect(
        () => buildPlan(doc),
        throwsA(
          isA<ExtractionException>().having(
            (e) => e.message,
            'message',
            allOf(contains('components.head.variants.afro'), contains('#123456')),
          ),
        ),
      );
    });

    test('should_fail_loudly_when_a_colour_name_is_unknown', () {
      final doc = _loadSource();
      firstHeadElementAttributes(doc)['fill'] = <String, Object?>{
        'type': 'color',
        'name': 'mystery',
      };

      expect(
        () => buildPlan(doc),
        throwsA(
          isA<ExtractionException>().having(
            (e) => e.message,
            'message',
            contains('mystery'),
          ),
        ),
      );
    });

    test('should_fail_when_two_source_keys_collapse_to_one_id', () {
      final doc = _loadSource();
      final head = _obj(_obj(doc['components'])['head']);
      final variants = _obj(head['variants']);
      variants['FlatTop'] = variants['flatTop'];

X_is_no_longer_cc0', () {
      final doc = _loadSource();
      _obj(_obj(doc['meta'])['license'])['name'] = 'CC BY 4.0';

      expect(() => buildPlan(doc), throwsA(isA<ExtractionException>()));
    });
  });

  group('toSnakeCase', () {
    test('should_convert_source_keys_to_stable_ids', () {
      expect(toSnakeCase('afro'), 'afro');
      expect(toSnakeCase('facialHair'), 'facial_hair');
      expect(toSnakeCase('lovingGrin1'), 'loving_grin1');
      expect(toSnakeCase('smileLOL'), 'smile_lol');
      expect(toSnakeCase('flatTopLong'), 'flat_top_long');
      expect(toSnakeCase('noHair3'), 'no_hair3');
      expect(toSnakeCase('hatBeanie'), 'hat_beanie');
    });

    test('should_reject_keys_that_are_not_plain_alphanumerics', () {
      expect(() => toSnakeCase('bad key'), throwsA(isA<ExtractionException>()));
      expect(() => toSnakeCase('1abc'), throwsA(isA<ExtractionException>()));
    });
  });
}
