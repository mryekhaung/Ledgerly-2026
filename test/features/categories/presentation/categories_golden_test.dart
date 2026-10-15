import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/presentation/category_list_state.dart';
import 'package:ledgerly/features/categories/presentation/pages/category_list_page.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_list_notifier.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
import '../../../support/tolerant_golden.dart';
import '../domain/fake_category_repository.dart';

/// The categories list screen, compact, light + dark (`docs/Design.md` §8).
///
/// First run: `flutter test <this file> --update-goldens`, then commit the
/// PNGs under `goldens/`.
void main() {
  setUpAll(() => useTolerantGoldens('categories_golden_test.dart'));

  final categories = <Category>[
    fakeCategory(
      id: 'a',
      name: 'Food',
      iconKey: 'food',
      colorValue: 0xFFE8735A,
    ),
    fakeCategory(
      id: 'b',
      name: 'Transport',
      iconKey: 'transport',
      colorValue: 0xFF5A8FE8,
    ),
    fakeCategory(
      id: 'c',
      name: 'Salary',
      iconKey: 'salary',
      colorValue: 0xFF6FB98F,
    ),
  ];

  Future<void> host(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) => pumpAppHost(
    tester,
    size: const Size(TestWidths.phone, 900),
    brightness: brightness,
    overrides: <Override>[
      categoryListProvider.overrideWith(
        () => _FixedCategoryListNotifier(CategoryListState.of(categories)),
      ),
    ],
    home: const CategoryListPage(),
  );

  group('Categories screen goldens', () {
    testWidgets('light theme', (tester) async {
      await host(tester, brightness: Brightness.light);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CategoryListPage),
        matchesGoldenFile('goldens/categories_light.png'),
      );
    });

    testWidgets('dark theme', (tester) async {
      await host(tester, brightness: Brightness.dark);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CategoryListPage),
        matchesGoldenFile('goldens/categories_dark.png'),
      );
    });
  });
}

/// A [CategoryListNotifier] that emits one fixed state.
class _FixedCategoryListNotifier extends CategoryListNotifier {
  _FixedCategoryListNotifier(this._state);

  final CategoryListState _state;

  @override
  Stream<CategoryListState> build() => Stream<CategoryListState>.value(_state);
}
