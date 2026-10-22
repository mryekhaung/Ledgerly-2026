import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: AppThemeColors(
      colors: const AppColorsLight(),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  const tabs = <SegmentedTab<String>>[
    SegmentedTab<String>(value: 'exp', label: 'Expense'),
    SegmentedTab<String>(value: 'inc', label: 'Income'),
  ];

  group('SegmentedTabs on Material', () {
    testWidgets('should_render_tabs_and_trigger_onChanged', (tester) async {
      String selected = 'exp';
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => SegmentedTabs<String>(
              tabs: tabs,
              selected: selected,
              platform: AppPlatform.android,
              onChanged: (val) {
                setState(() => selected = val);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);

      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      expect(selected, 'inc');
    });
  });

  group('SegmentedTabs on iOS', () {
    testWidgets('should_render_tabs_and_trigger_onChanged', (tester) async {
      String selected = 'exp';
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => SegmentedTabs<String>(
              tabs: tabs,
              selected: selected,
              platform: AppPlatform.ios,
              onChanged: (val) {
                setState(() => selected = val);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);

      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      expect(selected, 'inc');
    });
  });
}
