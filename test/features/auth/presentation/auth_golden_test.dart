import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/features/auth/presentation/pages/welcome_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
import '../../../support/tolerant_golden.dart';
import '../../../support/width_walk.dart';
import '../domain/fake_auth_repository.dart';
import '../support/auth_overrides.dart';

/// The welcome / first-run screen, compact, light + dark (`docs/Design.md` §8).
///
/// The auth use cases and the settings store are substituted, so the page
/// renders its real hero and buttons instead of an error treatment.
///
/// First run: `flutter test <this file> --update-goldens`, then commit the
/// PNGs under `goldens/`.
void main() {
  setUpAll(() => useTolerantGoldens('auth_golden_test.dart', tolerance: 0.05));

  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  tearDown(() => repository.dispose());

  Future<void> host(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double width = TestWidths.phone,
    double textScale = 1,
  }) => pumpAppHost(
    tester,
    size: Size(width, 900),
    brightness: brightness,
    textScaler: TextScaler.linear(textScale),
    overrides: authOverridesFor(repository),
    home: const WelcomePage(),
  );

  widthWalkGroup(pageName: 'WelcomePage', host: host);

  group('Welcome screen goldens', () {
    testWidgets('light theme', (tester) async {
      await host(tester, brightness: Brightness.light);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(WelcomePage),
        matchesGoldenFile('goldens/welcome_light.png'),
      );
    });

    testWidgets('dark theme', (tester) async {
      await host(tester, brightness: Brightness.dark);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(WelcomePage),
        matchesGoldenFile('goldens/welcome_dark.png'),
      );
    });
  });
}
