import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/widgets/app_date_picker.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: AppThemeColors(
      colors: const AppColorsLight(),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  group('AppDatePicker on Material', () {
    testWidgets('should_open_material_date_picker', (tester) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                unawaited(
                  AppDatePicker.show(
                    context: context,
                    initialDate: DateTime(2025, 6, 15),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    platform: AppPlatform.android,
                  ),
                );
              },
              child: const Text('Pick Date'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pick Date'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
  });

  group('AppDatePicker on iOS', () {
    testWidgets('should_open_cupertino_date_picker_modal', (tester) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                unawaited(
                  AppDatePicker.show(
                    context: context,
                    initialDate: DateTime(2025, 6, 15),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    platform: AppPlatform.ios,
                  ),
                );
              },
              child: const Text('Pick Date'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pick Date'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Done'), findsNothing);
    });
  });
}
