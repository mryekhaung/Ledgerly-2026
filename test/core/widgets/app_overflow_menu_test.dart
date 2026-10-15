import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/widgets/app_overflow_menu.dart';
import 'package:material_ui/material_ui.dart';

/// The adaptive overflow menu (`docs/Platform.md` §2).
///
/// Material hosts get the popup menu; iOS gets an action sheet — verified by
/// flipping the test host's target platform, which is what
/// `AppPlatform.resolve()` reads.
void main() {
  Widget host(AppOverflowMenu<String> menu) => MaterialApp(
    home: AppThemeColors(
      colors: const AppColorsLight(),
      child: Scaffold(body: Center(child: menu)),
    ),
  );

  AppOverflowMenu<String> menu(
    ValueChanged<String> onSelected, {
    AppPlatform? platform,
  }) => AppOverflowMenu<String>(
    cancelLabel: 'Cancel',
    onSelected: onSelected,
    platform: platform,
    items: const <OverflowMenuItem<String>>[
      OverflowMenuItem<String>(value: 'edit', label: 'Edit'),
      OverflowMenuItem<String>(
        value: 'delete',
        label: 'Delete',
        destructive: true,
      ),
    ],
  );

  group('AppOverflowMenu on Material', () {
    testWidgets('should_select_the_tapped_action', (tester) async {
      String? picked;
      await tester.pumpWidget(host(menu((v) => picked = v)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_horiz_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(picked, 'delete');
    });
  });

  group('AppOverflowMenu on iOS', () {
    testWidgets('should_show_an_action_sheet_with_cancel', (tester) async {
      String? picked;
      await tester.pumpWidget(
        host(menu((v) => picked = v, platform: AppPlatform.ios)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_horiz_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(picked, 'edit');
    });

    testWidgets('should_dismiss_without_picking_on_cancel', (tester) async {
      String? picked;
      await tester.pumpWidget(
        host(menu((v) => picked = v, platform: AppPlatform.ios)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_horiz_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(picked, isNull);
      expect(find.text('Edit'), findsNothing);
    });
  });
}
