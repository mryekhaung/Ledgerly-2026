import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveBlurView, BlurStyle;
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

  group('AppBottomSheet on iOS 26+', () {
    testWidgets('should_render_adaptive_blur_view_when_isIOS26_is_true', (
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
                  isIOS26: true,
                  builder: (ctx) => const Text('iOS 26 Glass Sheet Content'),
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

      final blurView = tester.widget<AdaptiveBlurView>(
        find.byType(AdaptiveBlurView),
      );
      expect(blurView.blurStyle, BlurStyle.systemUltraThinMaterial);
      expect(find.text('iOS 26 Glass Sheet Content'), findsOneWidget);
    });
  });
}
