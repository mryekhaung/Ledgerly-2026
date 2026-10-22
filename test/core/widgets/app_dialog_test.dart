import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/widgets/app_dialog.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: AppThemeColors(
      colors: const AppColorsLight(),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  group('AppDialog.confirm on Material', () {
    testWidgets('should_confirm_and_return_true_on_confirm_press', (
      tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await AppDialog.confirm(
                  context: context,
                  title: 'Delete Item',
                  message: 'Are you sure?',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                  isDestructive: true,
                  platform: AppPlatform.android,
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

      expect(find.text('Delete Item'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('should_cancel_and_return_false_on_cancel_press', (
      tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await AppDialog.confirm(
                  context: context,
                  title: 'Delete Item',
                  message: 'Are you sure?',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                  platform: AppPlatform.android,
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

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });

  group('AppDialog.confirm on iOS', () {
    testWidgets('should_confirm_and_return_true_on_confirm_press', (
      tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await AppDialog.confirm(
                  context: context,
                  title: 'Delete Item',
                  message: 'Are you sure?',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                  isDestructive: true,
                  platform: AppPlatform.ios,
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

      expect(find.text('Delete Item'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('should_cancel_and_return_false_on_cancel_press', (
      tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await AppDialog.confirm(
                  context: context,
                  title: 'Delete Item',
                  message: 'Are you sure?',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                  platform: AppPlatform.ios,
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

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
