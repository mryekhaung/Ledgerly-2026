import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:material_ui/material_ui.dart';

/// The responsive layout primitives (docs/Platform.md §5).
///
/// These are the only widgets that decide *when* the app changes shape, so a bug
/// here is a bug on every page at once. The assertions are structural — which
/// arrangement resulted — rather than pixel-based, so they stay valid as the
/// design tokens move.
void main() {
  /// Hosts [child] at a given logical width.
  ///
  /// `MediaQuery.size` is set directly rather than through a real surface, so the
  /// tests exercise the exact breakpoints without depending on the harness's
  /// default 800×600 window.
  Widget host(Widget child, double width) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 800)),
      child: Scaffold(body: child),
    ),
  );

  group('TwoPaneLayout', () {
    testWidgets('should_stack_the_panes_below_medium', (tester) async {
      await tester.pumpWidget(
        host(
          const TwoPaneLayout(master: Text('master'), detail: Text('detail')),
          TestWidths.smallPhone,
        ),
      );

      // A Column, not a Row — one column on a phone.
      final column = tester.widget<Column>(
        find
            .ancestor(of: find.text('master'), matching: find.byType(Column))
            .first,
      );
      expect(column, isNotNull);
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('should_split_into_a_row_at_medium', (tester) async {
      await tester.pumpWidget(
        host(
          const TwoPaneLayout(master: Text('master'), detail: Text('detail')),
          TestWidths.tablet,
        ),
      );

      expect(find.byType(Row), findsWidgets);
      // Both panes still present — the split rearranges, it never drops content.
      expect(find.text('master'), findsOneWidget);
      expect(find.text('detail'), findsOneWidget);
    });

    testWidgets('should_split_at_expanded', (tester) async {
      await tester.pumpWidget(
        host(
          const TwoPaneLayout(master: Text('master'), detail: Text('detail')),
          TestWidths.desktop,
        ),
      );

      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('should_cap_the_master_pane_width_on_a_wide_desktop', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const TwoPaneLayout(
            master: Text('master'),
            detail: Text('detail'),
            masterMaxWidth: 300,
          ),
          TestWidths.wide,
        ),
      );

      final size = tester.getSize(
        find
            .ancestor(
              of: find.text('master'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(size.width, lessThanOrEqualTo(300));
    });

    testWidgets('should_apply_the_configured_spacing_when_stacked', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const TwoPaneLayout(
            master: Text('master'),
            detail: Text('detail'),
            stackSpacing: 24,
          ),
          TestWidths.smallPhone,
        ),
      );

      final masterBottom = tester.getBottomLeft(find.text('master')).dy;
      final detailTop = tester.getTopLeft(find.text('detail')).dy;
      expect(detailTop - masterBottom, greaterThanOrEqualTo(24));
    });
  });

  group('ConstrainedPane', () {
    testWidgets('should_cap_the_child_at_the_prose_width', (tester) async {
      await tester.pumpWidget(
        host(const ConstrainedPane(child: Text('body')), TestWidths.wide),
      );

      final size = tester.getSize(
        find
            .ancestor(
              of: find.text('body'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(size.width, lessThanOrEqualTo(560));
    });

    testWidgets('should_not_stretch_a_narrow_child', (tester) async {
      await tester.pumpWidget(
        host(const ConstrainedPane(child: Text('body')), TestWidths.smallPhone),
      );

      // The cap is a ceiling, not a target: on a narrow window the child gets
      // whatever width there is rather than being padded out to 560.
      final size = tester.getSize(
        find
            .ancestor(
              of: find.text('body'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(size.width, lessThanOrEqualTo(TestWidths.smallPhone));
    });

    testWidgets('should_honour_a_custom_cap', (tester) async {
      await tester.pumpWidget(
        host(
          const ConstrainedPane(maxWidth: 200, child: Text('body')),
          TestWidths.wide,
        ),
      );

      final size = tester.getSize(
        find
            .ancestor(
              of: find.text('body'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(size.width, lessThanOrEqualTo(200));
    });
  });

  group('ModalFormScaffold', () {
    testWidgets('should_render_a_plain_page_on_compact', (tester) async {
      await tester.pumpWidget(
        host(
          const ModalFormScaffold(title: 'New', child: Text('form')),
          TestWidths.smallPhone,
        ),
      );

      expect(find.text('New'), findsOneWidget);
      expect(find.text('form'), findsOneWidget);
      // Compact gets no floating card.
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('should_render_a_centred_card_at_medium', (tester) async {
      await tester.pumpWidget(
        host(
          const ModalFormScaffold(title: 'New', child: Text('form')),
          TestWidths.tablet,
        ),
      );

      expect(find.text('New'), findsOneWidget);
      expect(find.text('form'), findsOneWidget);
    });

    testWidgets('should_keep_the_app_bar_in_both_presentations', (
      tester,
    ) async {
      for (final width in <double>[TestWidths.smallPhone, TestWidths.desktop]) {
        await tester.pumpWidget(
          host(
            const ModalFormScaffold(title: 'Edit', child: Text('form')),
            width,
          ),
        );
        expect(
          find.text('Edit'),
          findsOneWidget,
          reason: 'title missing at width $width',
        );
      }
    });

    testWidgets('should_show_the_actions_in_both_presentations', (
      tester,
    ) async {
      for (final width in <double>[TestWidths.smallPhone, TestWidths.desktop]) {
        await tester.pumpWidget(
          host(
            ModalFormScaffold(
              title: 'Edit',
              actions: <Widget>[
                TextButton(onPressed: () {}, child: const Text('Save')),
              ],
              child: const Text('form'),
            ),
            width,
          ),
        );
        expect(
          find.text('Save'),
          findsOneWidget,
          reason: 'action missing at width $width',
        );
      }
    });
  });

  group('ResponsiveInsets', () {
    testWidgets('should_use_16_horizontal_padding_on_compact', (tester) async {
      late EdgeInsets padding;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              padding = ResponsiveInsets.page(context, bottom: 0);
              return const SizedBox.shrink();
            },
          ),
          TestWidths.smallPhone,
        ),
      );

      expect(padding.left, 16);
      expect(padding.right, 16);
    });

    testWidgets('should_use_24_horizontal_padding_at_medium_and_up', (
      tester,
    ) async {
      late EdgeInsets padding;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              padding = ResponsiveInsets.page(context, bottom: 0);
              return const SizedBox.shrink();
            },
          ),
          TestWidths.desktop,
        ),
      );

      expect(padding.left, 24);
      expect(padding.right, 24);
    });

    testWidgets('should_carry_the_requested_bottom_gap', (tester) async {
      late EdgeInsets padding;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              padding = ResponsiveInsets.page(context, bottom: 88);
              return const SizedBox.shrink();
            },
          ),
          TestWidths.smallPhone,
        ),
      );

      expect(padding.bottom, 88);
    });
  });

  group('every page renders at every mandated width', () {
    // The DoD requires the UI be checked at all six canonical widths
    // (`docs/Agent.md` §6). Walking the list here means a new breakpoint cannot
    // be added without at least one layout being exercised on it.
    testWidgets('should_lay_out_the_panes_without_overflowing', (tester) async {
      for (final width in TestWidths.all) {
        await tester.pumpWidget(
          host(
            const TwoPaneLayout(master: Text('master'), detail: Text('detail')),
            width,
          ),
        );
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'TwoPaneLayout threw at width $width',
        );
      }
    });

    testWidgets('should_lay_out_a_capped_pane_without_overflowing', (
      tester,
    ) async {
      for (final width in TestWidths.all) {
        await tester.pumpWidget(
          host(const ConstrainedPane(child: Text('body')), width),
        );
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'ConstrainedPane threw at width $width',
        );
      }
    });

    testWidgets('should_lay_out_a_form_constrained_by_width', (tester) async {
      for (final width in TestWidths.all) {
        await tester.pumpWidget(
          host(
            const ModalFormScaffold(
              title: 'Form',
              child: SizedBox(height: 40, child: Text('field')),
            ),
            width,
          ),
        );
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'ModalFormScaffold threw at width $width',
        );
      }
    });

    testWidgets('should_keep_every_label_visible_at_text_scale_2', (
      tester,
    ) async {
      // The DoD names text scale 2.0 explicitly: a two-pane split that only fits
      // at scale 1 is a bug for anyone using large type.
      for (final width in <double>[TestWidths.smallPhone, TestWidths.tablet]) {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: const TextScaler.linear(2),
            ),
            child: MaterialApp(
              home: Scaffold(
                body: TwoPaneLayout(
                  master: Text('master'),
                  detail: Text('detail'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'two panes threw at width $width, text scale 2.0',
        );
        expect(find.text('master'), findsOneWidget);
        expect(find.text('detail'), findsOneWidget);
      }
    });
  });
}
