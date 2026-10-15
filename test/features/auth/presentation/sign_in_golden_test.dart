import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/features/auth/presentation/pages/sign_in_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
import '../../../support/tolerant_golden.dart';
import '../domain/fake_auth_repository.dart';
import '../support/auth_overrides.dart';

/// The email sign-in / sign-up screen, compact, light + dark
/// (`docs/Design.md` §8).
///
/// First run: `flutter test <this file> --update-goldens`, then commit the
/// PNGs under `goldens/`.
void main() {
  setUpAll(() => useTolerantGoldens('sign_in_golden_test.dart'));

  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  tearDown(() => repository.dispose());

  Future<void> host(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) => pumpAppHost(
    tester,
    size: const Size(TestWidths.phone, 900),
    brightness: brightness,
    overrides: authOverridesFor(repository),
    home: const SignInPage(),
  );

  group('Sign-in screen goldens', () {
    testWidgets('light theme', (tester) async {
      await host(tester, brightness: Brightness.light);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(SignInPage),
        matchesGoldenFile('goldens/signin_light.png'),
      );
    });

    testWidgets('dark theme', (tester) async {
      await host(tester, brightness: Brightness.dark);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(SignInPage),
        matchesGoldenFile('goldens/signin_dark.png'),
      );
    });
  });
}
