import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/widgets/app_bottom_sheet.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: AppThemeColors(
      colors: const AppColorsLight(),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  group('AppBottomSheet on Material', () {
    testWidgets('should_open_bottom_sheet_and_display_content', (tester) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await AppBottomSheet.show<void>(
                  context: context,
                  platform: AppPlatform.android,
                  builder: (ctx) => const Text('Material Sheet Content'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Material Sheet Content'), findsOneWidget);
    });
  });

  group('AppBottomSheet on iOS', () {
    testWidgets('should_open_cupertino_popup_and_display_content', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await AppBottomSheet.show<void>(
                  context: context,
                  platform: AppPlatform.ios,
                  builder: (ctx) => const Text('iOS Sheet Content'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('iOS Sheet Content'), findsOneWidget);
    });
  });
}
