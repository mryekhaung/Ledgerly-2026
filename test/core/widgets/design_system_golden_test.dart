import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/core/widgets/list_row.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
import 'package:material_ui/material_ui.dart';

/// Tolerant comparator allowing minor rasterizer differences across OSes.
///
/// Same treatment as `avatar_golden_test.dart`: goldens are generated on one
/// machine and asserted on CI's Linux runner, so pixel-exact equality is a
/// trap. A diff above 2% is a real regression.
class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(super.testFile, {this.tolerance = 0.02});

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (!result.passed && result.diffPercent > tolerance) {
      final error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    return result.passed || result.diffPercent <= tolerance;
  }
}

/// Design-system component goldens (docs/Design.md §8, docs/Conventions.md §6).
///
/// Pins the three components Option B migrated every screen onto — [AppCard]
/// (Rule 10), [ListRow] (Rule 9) and [SegmentedTabs] (Rule 11) — in light and
/// dark. AppScaffold is deliberately excluded: it is viewport-dependent, so
/// a golden of it would pin the test window rather than the component.
///
/// First run: `flutter test test/core/widgets/design_system_golden_test.dart
/// --update-goldens`, then commit the PNGs under `goldens/`.
void main() {
  setUpAll(() {
    final current = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenComparator(
      Uri.parse('${current.basedir}design_system_golden_test.dart'),
      tolerance: 0.02,
    );
  });

  Widget host({required bool isDark, required Widget child}) {
    final themeColors = isDark ? const AppColorsDark() : const AppColorsLight();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDark ? AppTheme.dark() : AppTheme.light(),
      home: AppThemeColors(
        colors: themeColors,
        child: ColoredBox(
          color: themeColors.surface,
          child: Center(
            child: RepaintBoundary(
              child: Container(
                width: 360,
                padding: const EdgeInsets.all(16),
                color: themeColors.surface,
                alignment: Alignment.center,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget cardFixture() => const AppCard(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Spent today'),
        SizedBox(height: 8),
        Text('-12,500 Ks'),
      ],
    ),
  );

  Widget rowFixture() => const ListRow(
    leading: CategoryGem(
      colorValue: 0xFF0E7C66,
      iconKey: 'groceries',
      size: CategoryGemSize.md,
    ),
    title: Text('Groceries'),
    subtitle: Text('Cash'),
    amount: Money.minor(-3200, CurrencyCode.mmk),
    isExpense: true,
    showDivider: true,
  );

  Widget segmentsFixture() => SegmentedTabs<String>(
    tabs: const <SegmentedTab<String>>[
      SegmentedTab<String>(value: 'expense', label: 'Expense'),
      SegmentedTab<String>(value: 'income', label: 'Income'),
    ],
    selected: 'expense',
    onChanged: (_) {},
  );

  group('design system goldens', () {
    testWidgets('app card in light theme', (tester) async {
      await tester.pumpWidget(host(isDark: false, child: cardFixture()));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AppCard),
        matchesGoldenFile('goldens/app_card_light.png'),
      );
    });

    testWidgets('app card in dark theme', (tester) async {
      await tester.pumpWidget(host(isDark: true, child: cardFixture()));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AppCard),
        matchesGoldenFile('goldens/app_card_dark.png'),
      );
    });

    testWidgets('list row in light theme', (tester) async {
      await tester.pumpWidget(host(isDark: false, child: rowFixture()));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ListRow),
        matchesGoldenFile('goldens/list_row_light.png'),
      );
    });

    testWidgets('list row in dark theme', (tester) async {
      await tester.pumpWidget(host(isDark: true, child: rowFixture()));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ListRow),
        matchesGoldenFile('goldens/list_row_dark.png'),
      );
    });

    testWidgets('segmented tabs in light theme', (tester) async {
      await tester.pumpWidget(host(isDark: false, child: segmentsFixture()));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(SegmentedTabs<String>),
        matchesGoldenFile('goldens/segmented_tabs_light.png'),
      );
    });

    testWidgets('segmented tabs in dark theme', (tester) async {
      await tester.pumpWidget(host(isDark: true, child: segmentsFixture()));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(SegmentedTabs<String>),
        matchesGoldenFile('goldens/segmented_tabs_dark.png'),
      );
    });
  });
}
