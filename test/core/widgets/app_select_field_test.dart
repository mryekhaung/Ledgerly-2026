import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveBlurView;
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/widgets/app_select_field.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    builder: (context, content) =>
        AppThemeColors(colors: const AppColorsLight(), child: content!),
    home: Scaffold(body: Center(child: child)),
  );

  const options = <AppSelectOption<String>>[
    AppSelectOption<String>(value: 'one', child: Text('One')),
    AppSelectOption<String>(value: 'two', child: Text('Two')),
  ];

  testWidgets('uses a Material dropdown on Android', (tester) async {
    await tester.pumpWidget(
      host(
        const AppSelectField<String>(
          value: 'one',
          options: options,
          onChanged: _ignore,
          platform: AppPlatform.android,
        ),
      ),
    );

    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });

  testWidgets('uses an iOS selection sheet on iOS 18', (tester) async {
    String? selected;
    await tester.pumpWidget(
      host(
        AppSelectField<String>(
          value: 'one',
          options: options,
          onChanged: (value) => selected = value,
          platform: AppPlatform.ios,
          isIOS26: false,
        ),
      ),
    );

    await tester.tap(find.text('One').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Two').last);
    await tester.pumpAndSettle();

    expect(selected, 'two');
  });

  testWidgets('uses a glass sheet on iOS 26+', (tester) async {
    await tester.pumpWidget(
      host(
        const AppSelectField<String>(
          value: 'one',
          options: options,
          onChanged: _ignore,
          platform: AppPlatform.ios,
          isIOS26: true,
        ),
      ),
    );

    await tester.tap(find.text('One'));
    await tester.pumpAndSettle();

    expect(find.byType(AdaptiveBlurView), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
  });
}

void _ignore(String? _) {}
