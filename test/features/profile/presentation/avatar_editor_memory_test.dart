import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/profile/data/datasources/avatar_svg_composer.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';
import 'package:ledgerly/features/profile/presentation/pages/avatar_editor_page.dart';
import 'package:ledgerly/features/profile/presentation/providers/profile_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';

/// Memory and lifecycle test: verifies opening and closing the editor 10 times
/// in a row causes no leaks, crashes, or unbound cache growth (docs/Avatar.md §7).
void main() {
  testWidgets('open and close editor 10x with bounded cache and zero errors', (
    tester,
  ) async {
    await pumpAppHost(
      tester,
      overrides: <Override>[
        userProfileProvider.overrideWith(
          (_) => Stream.value(UserProfile.initial),
        ),
      ],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AvatarEditorPage(),
                  ),
                );
              },
              child: const Text('Open Editor'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 10; i++) {
      // 1. Open editor
      await tester.tap(find.text('Open Editor'));
      await tester.pumpAndSettle();

      expect(find.byType(AvatarEditorPage), findsOneWidget);

      // 2. Close editor via top-bar close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(AvatarEditorPage), findsNothing);
      expect(tester.takeException(), isNull);
    }

    // Verify composer LRU cache does not leak or exceed bound
    final cacheSize = AvatarSvgComposer.instance.cache.length;
    expect(
      cacheSize,
      lessThanOrEqualTo(32),
      reason: 'Composer LRU cache exceeded 32 limit',
    );
  });
}
