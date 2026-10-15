import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/features/auth/presentation/pages/account_page.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/presentation/providers/profile_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
import '../../../support/tolerant_golden.dart';
import '../../../support/width_walk.dart';
import '../domain/fake_auth_repository.dart';
import '../support/auth_overrides.dart';

/// The account management screen, compact, light + dark (`docs/Design.md` §8).
///
/// The avatar is pinned to [AvatarConfig.initial] so the golden does not depend
/// on a stored profile.
///
/// First run: `flutter test <this file> --update-goldens`, then commit the
/// PNGs under `goldens/`.
void main() {
  setUpAll(() => useTolerantGoldens('account_golden_test.dart'));

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
    overrides: <Override>[
      ...authOverridesFor(repository),
      currentAvatarProvider.overrideWithValue(AvatarConfig.initial),
    ],
    home: const AccountPage(),
  );

  widthWalkGroup(pageName: 'AccountPage', host: host);

  group('Account screen goldens', () {
    testWidgets('light theme', (tester) async {
      await host(tester, brightness: Brightness.light);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AccountPage),
        matchesGoldenFile('goldens/account_light.png'),
      );
    });

    testWidgets('dark theme', (tester) async {
      await host(tester, brightness: Brightness.dark);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AccountPage),
        matchesGoldenFile('goldens/account_dark.png'),
      );
    });
  });
}
