import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/presentation/category_list_state.dart';
import 'package:ledgerly/features/categories/presentation/pages/category_form_page.dart';
import 'package:ledgerly/features/categories/presentation/pages/category_list_page.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_list_notifier.dart';
import 'package:ledgerly/l10n/app_localization.dart';
import 'package:ledgerly/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/fake_category_repository.dart';

/// The categories list at each window size class.
///
/// The interesting behaviour is the **master–detail split**: the same list and
/// the same form, arranged differently, with the row highlight being the only
/// thing that tells the user which category the right-hand form belongs to. The
/// form itself is not driven here — `category_form_state_test.dart` owns its
/// logic — so this focuses on the geometry and the wiring.
void main() {
  /// Hosts [CategoryListPage] at a given logical width with a fixed list.
  ///
  /// `categoryListProvider` is overridden so the page never reaches the get_it
  /// locator (not configured in a widget test) while still exercising the real
  /// page, rows and layout.
  Widget host(List<Category> categories, double width, {Locale? locale}) {
    return ProviderScope(
      overrides: [
        categoryListProvider.overrideWith(
          () => _FixedCategoryListNotifier(CategoryListState.of(categories)),
        ),
      ],
      child: MaterialApp(
        locale: locale ?? const Locale('en'),
        supportedLocales: AppLocalization.supportedLocales
            .map(Locale.new)
            .toList(growable: false),
        localizationsDelegates: const <LocalizationsDelegate<Object?>>[
          ...GlobalMaterialLocalizations.delegates,
          AppLocalizations.delegate,
        ],
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 900)),
          child: Builder(
            builder: (context) => AppStringsScope(
              lookup: AppStringLookup.of(AppLocalizations.of(context)),
              child: const CategoryListPage(),
            ),
          ),
        ),
      ),
    );
  }

  final categories = <Category>[
    fakeCategory(id: 'a', name: 'Food'),
    fakeCategory(id: 'b', name: 'Transport'),
    fakeCategory(id: 'c', name: 'Old stuff', isArchived: true),
  ];

  group('compact', () {
    testWidgets('should_show_the_list_without_a_detail_pane', (tester) async {
      await tester.pumpWidget(host(categories, TestWidths.smallPhone));
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      // No detail pane means no hint telling the user to pick something.
      expect(
        find.text('Pick a category to edit, or create a new one.'),
        findsNothing,
      );
    });

    testWidgets('should_not_show_a_form_inline_before_anything_is_tapped', (
      tester,
    ) async {
      await tester.pumpWidget(host(categories, TestWidths.smallPhone));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryFormBody), findsNothing);
    });

    testWidgets('should_show_the_archived_section', (tester) async {
      await tester.pumpWidget(host(categories, TestWidths.smallPhone));
      await tester.pumpAndSettle();

      expect(find.text('ARCHIVED'), findsOneWidget);
      expect(find.text('Old stuff'), findsOneWidget);
    });

    testWidgets('should_show_the_new_category_action', (tester) async {
      await tester.pumpWidget(host(categories, TestWidths.smallPhone));
      await tester.pumpAndSettle();

      expect(find.text('New category'), findsOneWidget);
    });
  });

  group('expanded master-detail', () {
    testWidgets('should_show_the_detail_hint_before_a_selection', (
      tester,
    ) async {
      await tester.pumpWidget(host(categories, TestWidths.desktop));
      await tester.pumpAndSettle();

      // The pane is not dead space: it says what to do.
      expect(
        find.text('Pick a category to edit, or create a new one.'),
        findsOneWidget,
      );
    });

    testWidgets('should_keep_the_list_visible_beside_the_pane', (tester) async {
      await tester.pumpWidget(host(categories, TestWidths.desktop));
      await tester.pumpAndSettle();

      // Master–detail means the list never disappears while editing.
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
    });

    testWidgets('should_open_the_form_in_the_pane_when_a_row_is_tapped', (
      tester,
    ) async {
      await tester.pumpWidget(host(categories, TestWidths.desktop));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // The form is inline, not a pushed route.
      expect(find.byType(CategoryFormBody), findsOneWidget);
      expect(
        find.text('Pick a category to edit, or create a new one.'),
        findsNothing,
      );
    });

    testWidgets('should_highlight_the_open_row', (tester) async {
      await tester.pumpWidget(host(categories, TestWidths.desktop));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // The tint is the only cue linking the row to the pane, so it must be a
      // real surface change. Find the Material wrapping the Food row.
      final foodMaterial = tester.widget<Material>(
        find
            .ancestor(of: find.text('Food'), matching: find.byType(Material))
            .first,
      );
      final transportMaterial = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('Transport'),
              matching: find.byType(Material),
            )
            .first,
      );

      expect(foodMaterial.color, isNot(Colors.transparent));
      expect(transportMaterial.color, Colors.transparent);
    });

    testWidgets('should_show_the_edit_title_in_the_pane', (tester) async {
      await tester.pumpWidget(host(categories, TestWidths.desktop));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      expect(find.text('Edit category'), findsWidgets);
    });

    testWidgets('should_render_the_myanmar_pane_hint_under_the_my_locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(categories, TestWidths.desktop, locale: const Locale('my')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'တည်းဖြတ်ရန် အမျိုးအစားတစ်ခု ရွေးပါ၊ သို့မဟုတ် အသစ်တစ်ခု ဖန်တီးပါ။',
        ),
        findsOneWidget,
      );
    });
  });

  group('every mandated width', () {
    testWidgets('should_lay_out_without_overflowing_at_any_width', (
      tester,
    ) async {
      for (final width in TestWidths.all) {
        await tester.pumpWidget(host(categories, width));
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'CategoryListPage threw at width $width',
        );
      }
    });

    testWidgets('should_lay_out_without_overflowing_at_text_scale_2', (
      tester,
    ) async {
      for (final width in <double>[TestWidths.smallPhone, TestWidths.desktop]) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              categoryListProvider.overrideWith(
                () => _FixedCategoryListNotifier(
                  CategoryListState.of(categories),
                ),
              ),
            ],
            child: MaterialApp(
              supportedLocales: AppLocalization.supportedLocales
                  .map(Locale.new)
                  .toList(growable: false),
              localizationsDelegates: const <LocalizationsDelegate<Object?>>[
                ...GlobalMaterialLocalizations.delegates,
                AppLocalizations.delegate,
              ],
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 900),
                  textScaler: const TextScaler.linear(2),
                ),
                child: Builder(
                  builder: (context) => AppStringsScope(
                    lookup: AppStringLookup.of(AppLocalizations.of(context)),
                    child: const CategoryListPage(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'CategoryListPage threw at width $width, text scale 2.0',
        );
      }
    });
  });

  group('empty state', () {
    testWidgets('should_show_the_empty_placeholder_at_every_width', (
      tester,
    ) async {
      for (final width in <double>[TestWidths.smallPhone, TestWidths.desktop]) {
        await tester.pumpWidget(host(const <Category>[], width));
        await tester.pumpAndSettle();

        expect(
          find.text('No categories yet'),
          findsOneWidget,
          reason: 'empty state missing at width $width',
        );
      }
    });
  });
}

/// A [CategoryListNotifier] that emits one fixed state.
///
/// Overriding the real notifier would require the get_it locator, which a widget
/// test does not have. Emitting the state directly keeps the page's own logic —
/// the responsive split, the row highlight, the pane — under test.
class _FixedCategoryListNotifier extends CategoryListNotifier {
  _FixedCategoryListNotifier(this._state);

  final CategoryListState _state;

  @override
  Stream<CategoryListState> build() => Stream<CategoryListState>.value(_state);
}
