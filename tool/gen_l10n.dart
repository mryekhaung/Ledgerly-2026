// Regenerates the app's lib/l10n/generated from its ARB files, without the
// flutter tool in the loop.
//
// WHY: `flutter gen-l10n` crashes on this machine with "CreateFile failed 231
// (All pipe instances are busy)" during the tool's own version check — it runs
// `git`/`where`/`cmd` before ever reaching the generator. LocalizationsGenerator
// needs none of that.
//
// HOW TO RUN: this file must execute *inside* the flutter_tools package, because
// it imports `package:flutter_tools/...` and only flutter_tools' own
// .dart_tool/package_config.json resolves that package. So it is invoked as:
//
//   cp tool/gen_l10n.dart $FLUTTER_ROOT/packages/flutter_tools/bin/gen_l10n_local.dart
//   cd $FLUTTER_ROOT/packages/flutter_tools
//   dart run bin/gen_l10n_local.dart <path-to-app-project>
//
// `tool/gen_l10n.sh` does exactly that. Do not `dart run` it from the app repo.
import 'dart:io';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/localizations/gen_l10n.dart';
import 'package:flutter_tools/src/localizations/localizations_utils.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('usage: gen_l10n_local.dart <path-to-app-project>');
    exit(64);
  }

  // Loads the ICU language/region tables the generator validates locales
  // against. `generateLocalizations` does this for us; constructing
  // LocalizationsGenerator directly means doing it by hand, or every locale
  // fails with '"en" is not a supported language code'.
  precacheLanguageAndRegionTags();

  final projectPath = args.first;
  final fileSystem = LocalFileSystem.test(signals: Signals.test());
  final logger = BufferLogger.test();

  final generator =
      LocalizationsGenerator(
          fileSystem: fileSystem,
          projectPathString: projectPath,
          inputPathString: 'lib/l10n',
          templateArbFileName: 'app_en.arb',
          outputFileString: 'app_localizations.dart',
          outputPathString: 'lib/l10n/generated',
          classNameString: 'AppLocalizations',
          untranslatedMessagesFile: 'l10n_untranslated.json',
          usesNullableGetter: false,
          logger: logger,
        )
        ..loadResources()
        ..writeOutputFiles(isFromYaml: true, useCRLF: false);

  for (final file in generator.outputFileList) {
    stdout.writeln('wrote $file');
  }
}
