import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/pages/settings_page.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';

/// Tolerant comparator allowing minor rasterizer differences across OSes.
class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(super.testFile, {this.tolerance = 0.02});

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (!result.passed && result.diffPercent > tolerance) {
      final error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    return result.passed || result.diffPercent <= tolerance;
  }
}

/// The settings screen, compact, light + dark (`docs/Design.md` §8).
///
/// First run: `flutter test <this file> --update-goldens`, then commit the
/// PNGs under `goldens/`.
void main() {
  setUpAll(() {
    final current = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenComparator(
      Uri.parse('${current.basedir}settings_golden_test.dart'),
      tolerance: 0.02,
    );
  });

  Future<void> host(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) => pumpAppHost(
    tester,
    size: const Size(TestWidths.phone, 900),
    brightness: brightness,
    overrides: <Override>[
      settingsProvider.overrideWith(
        (ref) => Stream.value(
          brightness == Brightness.dark
              ? AppSettings.defaults.copyWith(themeMode: AppThemeMode.dark)
              : AppSettings.defaults,
        ),
      ),
    ],
    home: const SettingsPage(),
  );

  group('Settings screen goldens', () {
    testWidgets('light theme', (tester) async {
      await host(tester, brightness: Brightness.light);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(SettingsPage),
        matchesGoldenFile('goldens/settings_light.png'),
      );
    });

    testWidgets('dark theme', (tester) async {
      await host(tester, brightness: Brightness.dark);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(SettingsPage),
        matchesGoldenFile('goldens/settings_dark.png'),
      );
    });
  });
}
