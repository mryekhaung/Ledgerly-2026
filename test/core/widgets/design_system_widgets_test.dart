import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveButton, AdaptiveButtonStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/widgets/app_button.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/core/widgets/list_row.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
import 'package:material_ui/material_ui.dart';

Widget host(Widget child, {AppColors colors = const AppColorsLight()}) {
  return MaterialApp(
    home: AppThemeColors(
      colors: colors,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('AppCard', () {
    testWidgets('should_render_with_surface_raised_and_radius_lg', (
      tester,
    ) async {
      await tester.pumpWidget(host(const AppCard(child: Text('Card Content'))));

      expect(find.text('Card Content'), findsOneWidget);
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Card Content'),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, const AppColorsLight().surfaceRaised);
      expect(decoration.borderRadius, AppRadius.borderLg);
    });

    testWidgets('should_trigger_on_tap_when_pressed', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        host(
          AppCard(onTap: () => tapped = true, child: const Text('Tappable')),
        ),
      );

      await tester.tap(find.text('Tappable'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('should_assert_against_nested_app_cards', (tester) async {
      await tester.pumpWidget(
        host(const AppCard(child: AppCard(child: Text('Nested')))),
      );
      expect(tester.takeException(), isAssertionError);
    });
  });

  group('ListRow', () {
    testWidgets('should_render_title_and_single_line_min_height', (
      tester,
    ) async {
      await tester.pumpWidget(host(const ListRow(title: Text('Salary'))));

      expect(find.text('Salary'), findsOneWidget);
      final container = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints?.minHeight == AppRowHeight.singleLine,
        ),
      );
      expect(container.constraints?.minHeight, AppRowHeight.singleLine);
    });

    testWidgets('should_render_two_line_min_height_when_subtitle_present', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const ListRow(
            title: Text('Groceries'),
            subtitle: Text('Supermarket'),
          ),
        ),
      );

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Supermarket'), findsOneWidget);
      final container = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints?.minHeight == AppRowHeight.twoLine,
        ),
      );
      expect(container.constraints?.minHeight, AppRowHeight.twoLine);
    });

    testWidgets('should_render_amount_with_amount_text', (tester) async {
      await tester.pumpWidget(
        host(
          const ListRow(
            title: Text('Dinner'),
            amount: Money.minor(-15000, CurrencyCode.mmk),
            isExpense: true,
          ),
        ),
      );

      expect(find.text('Dinner'), findsOneWidget);
      expect(find.textContaining('15,000'), findsOneWidget);
    });

    testWidgets('should_render_inset_divider_when_show_divider_is_true', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const ListRow(title: Text('Divided Row'), showDivider: true)),
      );

      expect(find.byType(Divider), findsOneWidget);
      final padding = tester.widget<Padding>(
        find
            .ancestor(of: find.byType(Divider), matching: find.byType(Padding))
            .first,
      );
      expect(padding.padding, const EdgeInsets.only(left: 72.0));
    });

    testWidgets('should_trigger_on_tap_callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        host(ListRow(title: const Text('Tap Me'), onTap: () => tapped = true)),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('SegmentedTabs', () {
    testWidgets('should_render_active_and_inactive_tabs', (tester) async {
      String selected = 'expense';
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => SegmentedTabs<String>(
              tabs: const <SegmentedTab<String>>[
                SegmentedTab(value: 'expense', label: 'Expense'),
                SegmentedTab(value: 'income', label: 'Income'),
              ],
              selected: selected,
              onChanged: (val) => setState(() => selected = val),
            ),
          ),
        ),
      );

      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);

      final expenseText = tester.widget<Text>(find.text('Expense'));
      // `onBrandSubtle`, not `brandPrimary`: the selected segment is filled
      // `brandSubtle`, and `brandPrimary` on that fill measured 3.90:1 light —
      // below AA for a 13 px label (docs/Roadmap.md §K.1-2).
      expect(expenseText.style?.color, const AppColorsLight().onBrandSubtle);

      final incomeText = tester.widget<Text>(find.text('Income'));
      expect(incomeText.style?.color, const AppColorsLight().textSecondary);

      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();
      expect(selected, 'income');
    });
  });

  group('AppButton', () {
    testWidgets('should_render_primary_button_and_respond_to_tap', (
      tester,
    ) async {
      var pressed = false;
      await tester.pumpWidget(
        host(AppButton(label: 'Save', onPressed: () => pressed = true)),
      );

      expect(find.text('Save'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });

    testWidgets('should_use_native_adaptive_button_on_iOS_26', (tester) async {
      await tester.pumpWidget(
        host(
          const AppButton(
            label: 'Save',
            onPressed: null,
            platform: AppPlatform.ios,
            isIOS26: true,
          ),
        ),
      );

      final button = tester.widget<AdaptiveButton>(find.byType(AdaptiveButton));
      expect(button.style, AdaptiveButtonStyle.prominentGlass);
    });

    testWidgets('should_show_spinner_when_is_loading', (tester) async {
      await tester.pumpWidget(
        host(AppButton(label: 'Submit', isLoading: true, onPressed: () {})),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('should_be_disabled_when_on_pressed_is_null', (tester) async {
      await tester.pumpWidget(
        host(const AppButton(label: 'Disabled', onPressed: null)),
      );

      expect(find.text('Disabled'), findsOneWidget);
    });

    // `AppButton` sizes its label with a `Flexible`, which is what lets a long
    // label ellipsize at 2× type (`docs/Design.md` §8) instead of overflowing.
    //
    // The label must still render in full whenever the caller gives it room, and
    // `AppButton` has two callers with opposite constraint shapes: most put it
    // in a bounded column, but `data_transfer/widgets/import_tab.dart` uses it
    // as a non-flex child of a `Row`, which measures it with an **unbounded**
    // main axis. This pins the second shape — a `Flexible` must not truncate
    // there (it does not: `RenderFlex` only allocates space to flexible children
    // when the main axis is bounded).
    testWidgets('should_keep_its_full_label_in_an_unbounded_row', (
      tester,
    ) async {
      const label = 'Save';

      await tester.pumpWidget(
        host(
          const Row(
            children: <Widget>[
              // Reference: the same string at the same size, unconstrained.
              Text(label, style: AppTypography.title),
              AppButton(label: label, onPressed: null),
            ],
          ),
        ),
      );

      final reference = tester.getSize(find.text(label).first).width;
      final inButton = tester.getSize(find.text(label).last).width;

      expect(reference, greaterThan(0));
      expect(
        inButton,
        reference,
        reason:
            'AppButton truncated its label inside an unbounded row — a '
            '`Flexible` there collapses to zero width.',
      );
    });
  });

  group('AppScaffold', () {
    testWidgets('should_render_title_actions_and_body', (tester) async {
      await tester.pumpWidget(
        host(
          const AppScaffold(
            title: 'Test Title',
            actions: <Widget>[Icon(Icons.settings)],
            body: Text('Page Body'),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.text('Page Body'), findsOneWidget);
    });

    testWidgets('should_constrain_content_to_max_width', (tester) async {
      await tester.pumpWidget(
        host(const AppScaffold(body: Text('Constrained Body'))),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find
            .ancestor(
              of: find.text('Constrained Body'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(constrainedBox.constraints.maxWidth, AppSpacing.contentMaxWidth);
    });
  });
}
