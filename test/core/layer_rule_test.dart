import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the Clean Architecture dependency rule (docs/Agent.md §3.1,
/// docs/Conventions.md §2) for the pure-Dart `core/` libraries.
///
/// `core/result`, `core/usecase`, `core/money` and `core/utils` are the
/// innermost layer: they are imported by `domain` and must therefore be
/// framework-free. A single stray `import 'package:flutter/...'` would make the
/// whole domain untestable in pure Dart and would silently couple business
/// rules to a UI toolkit.
///
/// This is a *test* rather than a lint because it needs to inspect every file in
/// a directory, which `analysis_options.yaml` rules cannot express.
/// Strips the current working directory from [absolutePath] for readable output.
///
/// Local helper rather than `package:path` so this test adds no dependency to
/// the project (docs/Agent.md §3.14).
String _relative(String absolutePath) {
  final cwd = Directory.current.path;
  final normalizedCwd = cwd.endsWith(Platform.pathSeparator)
      ? cwd
      : '$cwd${Platform.pathSeparator}';
  return absolutePath.startsWith(normalizedCwd)
      ? absolutePath.substring(normalizedCwd.length)
      : absolutePath;
}

void main() {
  /// Directories whose contents must not import anything platform-specific.
  const pureDartLibraries = <String>[
    'lib/core/result',
    'lib/core/usecase',
    'lib/core/money',
    'lib/core/utils',
    'lib/core/period',
  ];

  /// Import prefixes `core/` may never use, with the reason they are banned.
  ///
  /// Matched against the import URI, so `package:flutter_riverpod/...` is caught
  /// by the `package:flutter` check and `package:material_ui` needs its own entry.
  const forbiddenPrefixes = <String, String>{
    'package:flutter/': 'Flutter UI framework',
    'package:flutter_riverpod': 'presentation-layer state management',
    'package:flutter_test': 'test-only dependency',
    'package:material_ui': 'Flutter UI package',
    'package:cupertino_ui': 'Flutter UI package',
    'package:go_router': 'presentation-layer routing',
    'package:get_it': 'DI wiring belongs in app/di',
    'package:drift': 'data-layer persistence',
    'package:dio': 'data-layer networking',
    'package:firebase': 'data-layer remote SDK',
    'package:supabase': 'data-layer remote SDK',
    'package:shared_preferences': 'data-layer storage',
    'package:file_picker': 'platform file access',
    'package:path_provider': 'platform file access',
    'package:share_plus': 'platform sharing',
  };

  /// `dart:` libraries that are unavailable or unsafe on web, or that pull in IO.
  const forbiddenDartLibraries = <String, String>{
    'dart:io': 'not available on web; IO belongs in data/',
    'dart:html': 'deprecated; use package:web behind a conditional import',
    'dart:js': 'deprecated; use package:web behind a conditional import',
    'dart:js_util': 'interop belongs in data/ behind an interface',
    'dart:isolate': 'concurrency is a data-layer concern',
    'dart:mirrors': 'unavailable on web and Flutter',
  };

  /// Extracts every `import`/`export` URI from Dart [source].
  ///
  /// Deliberately tolerant: it strips line comments so a commented-out import
  /// (banned by docs/Agent.md §8) cannot mask a real one, and ignores
  /// `library`/`part` directives since those are not imports.
  List<String> directiveUris(String source) {
    final results = <String>[];
    final pattern = RegExp(
      r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
      multiLine: true,
    );
    for (final match in pattern.allMatches(source)) {
      results.add(match.group(1)!);
    }
    return results;
  }

  /// All `.dart` files under [directory], recursively.
  List<File> dartFilesIn(String directory) {
    final dir = Directory(directory);
    if (!dir.existsSync()) {
      fail(
        'Expected directory "$directory" to exist (docs/Architecture.md §2).',
      );
    }
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  group('core layer purity', () {
    for (final library in pureDartLibraries) {
      group(library, () {
        test('should_contain_at_least_one_dart_file', () {
          expect(
            dartFilesIn(library),
            isNotEmpty,
            reason: '$library should hold at least one source file.',
          );
        });

        test('should_not_import_flutter_or_platform_packages', () {
          final violations = <String>[];

          for (final file in dartFilesIn(library)) {
            for (final uri in directiveUris(file.readAsStringSync())) {
              for (final entry in forbiddenPrefixes.entries) {
                if (uri.startsWith(entry.key)) {
                  violations.add(
                    '${_relative(file.path)} imports "$uri" '
                    '(${entry.value})',
                  );
                }
              }
            }
          }

          expect(
            violations,
            isEmpty,
            reason:
                'These libraries must stay pure Dart (docs/Agent.md §3.1):\n'
                '${violations.join('\n')}',
          );
        });

        test('should_not_import_forbidden_dart_libraries', () {
          final violations = <String>[];

          for (final file in dartFilesIn(library)) {
            for (final uri in directiveUris(file.readAsStringSync())) {
              final reason = forbiddenDartLibraries[uri];
              if (reason != null) {
                violations.add(
                  '${_relative(file.path)} imports "$uri" ($reason)',
                );
              }
            }
          }

          expect(
            violations,
            isEmpty,
            reason:
                'These libraries must stay portable (docs/Agent.md §3.11):\n'
                '${violations.join('\n')}',
          );
        });

        test('should_only_import_itself_or_the_sdk', () {
          // The innermost layer may depend on the Dart SDK and on sibling
          // `core/` libraries — nothing else. Any third-party package here
          // would have to be swapped out of the domain during a backend move.
          final allowedCoreLibraries = pureDartLibraries
              .map((path) => path.replaceFirst('lib/', 'package:ledgerly/'))
              .toList();

          // `intl` is the single sanctioned exception. It is a pure-Dart,
          // null-safe, ICU-backed formatting library with no Flutter or IO
          // dependency, and money formatting genuinely needs locale data.
          // It is a leaf dependency: it imports nothing from `ledgerly`, so it
          // cannot introduce a cycle back into the domain. Any second entry
          // here should be treated as an architectural decision, not a tweak.
          const allowedVendorPackages = <String>{'package:intl/'};

          final violations = <String>[];
          for (final file in dartFilesIn(library)) {
            for (final uri in directiveUris(file.readAsStringSync())) {
              if (uri.startsWith('dart:')) continue;
              if (allowedCoreLibraries.any(uri.startsWith)) continue;
              if (uri.startsWith('package:ledgerly/core/')) continue;
              if (allowedVendorPackages.any(uri.startsWith)) continue;
              violations.add('${_relative(file.path)} imports "$uri"');
            }
          }

          expect(
            violations,
            isEmpty,
            reason:
                'Unexpected dependencies in the innermost layer:\n'
                '${violations.join('\n')}',
          );
        });
      });
    }
  });

  group('feature domain layer purity', () {
    /// Every feature's `domain/` directory (docs/Architecture.md §2).
    List<String> domainDirectories() {
      final features = Directory('lib/features');
      if (!features.existsSync()) return const <String>[];
      return features
          .listSync()
          .whereType<Directory>()
          .map((dir) => '${dir.path}/domain')
          .toList()
        ..sort();
    }

    test('should_have_at_least_one_feature_with_a_domain_layer', () {
      // A tripwire rather than a nicety: if this fails, the loop below ran zero
      // times and the purity guarantee silently stopped applying.
      expect(
        domainDirectories().where((dir) => Directory(dir).existsSync()),
        isNotEmpty,
        reason: 'Phase 1+ features must each own a domain/ layer.',
      );
    });

    for (final library in domainDirectories()) {
      group(library, () {
        test('should_not_import_flutter_or_data_layer_packages', () {
          if (!Directory(library).existsSync()) return;

          final violations = <String>[];
          for (final file in dartFilesIn(library)) {
            for (final uri in directiveUris(file.readAsStringSync())) {
              for (final entry in forbiddenPrefixes.entries) {
                if (uri.startsWith(entry.key)) {
                  violations.add(
                    '${_relative(file.path)} imports "$uri" '
                    '(${entry.value})',
                  );
                }
              }
            }
          }

          expect(
            violations,
            isEmpty,
            reason:
                'domain/ must be pure Dart (docs/Agent.md §3.1, §3.2) — it may '
                'not see Flutter, Drift, or any remote SDK:\n'
                '${violations.join('\n')}',
          );
        });

        test('should_not_import_forbidden_dart_libraries', () {
          if (!Directory(library).existsSync()) return;

          final violations = <String>[];
          for (final file in dartFilesIn(library)) {
            for (final uri in directiveUris(file.readAsStringSync())) {
              final reason = forbiddenDartLibraries[uri];
              if (reason != null) {
                violations.add(
                  '${_relative(file.path)} imports "$uri" ($reason)',
                );
              }
            }
          }

          expect(
            violations,
            isEmpty,
            reason:
                'domain/ must stay portable (docs/Agent.md §3.11):\n'
                '${violations.join('\n')}',
          );
        });

        test('should_not_import_its_own_data_or_presentation_layer', () {
          // The dependency rule is presentation → domain ← data. A domain file
          // importing `../data/...` inverts it, which is how a repository
          // interface quietly becomes untestable and the backend stops being
          // swappable (docs/Architecture.md §4).
          if (!Directory(library).existsSync()) return;

          final featureRoot = library.substring(
            0,
            library.length - '/domain'.length,
          );
          final forbiddenSiblings = <String>[
            '$featureRoot/data/',
            '$featureRoot/presentation/',
          ];

          final violations = <String>[];
          for (final file in dartFilesIn(library)) {
            for (final uri in directiveUris(file.readAsStringSync())) {
              for (final sibling in forbiddenSiblings) {
                if (uri.contains(sibling)) {
                  violations.add('${_relative(file.path)} imports "$uri"');
                }
              }
            }
          }

          expect(
            violations,
            isEmpty,
            reason:
                'domain/ must not depend on data/ or presentation/ '
                '(docs/Conventions.md §2):\n'
                '${violations.join('\n')}',
          );
        });
      });
    }
  });

  group('forbidden-import policy self-check', () {
    test('should_flag_a_flutter_import', () {
      // Guards the detector itself: if the regex regressed, the layer tests
      // above would pass vacuously and stop protecting anything.
      const source = '''
import 'package:flutter/material.dart';
''';
      expect(directiveUris(source), contains('package:flutter/material.dart'));
    });

    test('should_flag_dart_io', () {
      const source = "import 'dart:io';";
      expect(directiveUris(source), contains('dart:io'));
    });

    test('should_not_flag_commented_out_imports', () {
      // Comments are stripped by the analyzer, not by us — an import inside a
      // line comment must not be reported as a real dependency.
      const source = '''
// import 'package:flutter/material.dart';
''';
      expect(directiveUris(source), isEmpty);
    });

    test('should_extract_export_directives', () {
      const source = "export 'src/thing.dart';";
      expect(directiveUris(source), contains('src/thing.dart'));
    });
  });
}
