import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show IOS26Switch;
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/widgets/app_switch_tile.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: AppThemeColors(
      colors: const AppColorsLight(),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  group('AppSwitchTile on Material', () {
    testWidgets('should_toggle_value_on_tap', (tester) async {
      bool value = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => AppSwitchTile(
              title: const Text('Notifications'),
              value: value,
              platform: AppPlatform.android,
              onChanged: (val) {
                setState(() => value = val);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(value, isTrue);
    });
  });

  group('AppSwitchTile on iOS', () {
    testWidgets('should_render_title_and_switch', (tester) async {
      bool value = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => AppSwitchTile(
              title: const Text('Notifications'),
              subtitle: const Text('Enable alerts'),
              value: value,
              platform: AppPlatform.ios,
              onChanged: (val) {
                setState(() => value = val);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Enable alerts'), findsOneWidget);
    });
  });

  group('AppSwitchTile on iOS 26+', () {
    testWidgets('should_render_ios26_switch_when_isIOS26_is_true', (
      tester,
    ) async {
      bool value = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => AppSwitchTile(
              title: const Text('Notifications'),
              subtitle: const Text('Enable alerts'),
              value: value,
              platform: AppPlatform.ios,
              isIOS26: true,
              onChanged: (val) {
                setState(() => value = val);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IOS26Switch), findsOneWidget);
    });
  });
}
