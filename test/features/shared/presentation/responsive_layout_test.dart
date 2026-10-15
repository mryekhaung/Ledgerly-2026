import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';

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
  /// default 800×600 window. The app's scopes come from [appTestHost], because
  /// these widgets read `AppThemeColors`/`AppStrings`.
  Future<void> host(WidgetTester tester, Widget child, double width) =>
      pumpAppHost(
        tester,
        home: Scaffold(body: child),
        size: Size(width, 800),
      );

  group('TwoPaneLayout', () {
    /// The rendered width of the leading pane.
    ///
    /// Measured off the `SizedBox` the layout wraps the master in, not off the
    /// master's own widget: a `Flexible`/`Expanded` pane reports its *share*,
    /// and it is the box the pane's content actually lives in that decides
    /// whether that content clips.
    ///
    /// `.first` because `find.ancestor` walks outward from the target, so the
    /// nearest enclosing `SizedBox` is the pane's.
    double masterPaneWidth(WidgetTester tester) => tester
        .getSize(
          find
              .ancestor(
                of: find.text('master'),
                matching: find.byType(SizedBox),
              )
              .first,
        )
        .width;

    /// Whether the layout is currently split side by side.
    bool isSplit() => find
        .descendant(of: find.byType(TwoPaneLayout), matching: find.byType(Row))
        .evaluate()
        .isNotEmpty;

    testWidgets('should_stack_the_panes_below_medium', (tester) async {
      await host(
        tester,
        const TwoPaneLayout(master: Text('master'), detail: Text('detail')),
        TestWidths.smallPhone,
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
      await host(
        tester,
        const TwoPaneLayout(master: Text('master'), detail: Text('detail')),
        TestWidths.tablet,
      );

      expect(find.byType(Row), findsWidgets);
      // Both panes still present — the split rearranges, it never drops content.
      expect(find.text('master'), findsOneWidget);
      expect(find.text('detail'), findsOneWidget);
    });

    testWidgets('should_split_at_expanded', (tester) async {
      await host(
        tester,
        const TwoPaneLayout(master: Text('master'), detail: Text('detail')),
        TestWidths.desktop,
      );

      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('should_cap_the_master_pane_width_on_a_wide_desktop', (
      tester,
    ) async {
      await host(
        tester,
        const TwoPaneLayout(
          master: Text('master'),
          detail: Text('detail'),
          masterMaxWidth: 300,
        ),
        TestWidths.wide,
      );

      // The ceiling is now an explicit width on the master rather than a
      // `ConstrainedBox` around it, so it is measured the same way the floor is.
      expect(masterPaneWidth(tester), lessThanOrEqualTo(300));
    });

    testWidgets('should_apply_the_configured_spacing_when_stacked', (
      tester,
    ) async {
      await host(
        tester,
        const TwoPaneLayout(
          master: Text('master'),
          detail: Text('detail'),
          stackSpacing: 24,
        ),
        TestWidths.smallPhone,
      );

      final masterBottom = tester.getBottomLeft(find.text('master')).dy;
      final detailTop = tester.getTopLeft(find.text('detail')).dy;
      expect(detailTop - masterBottom, greaterThanOrEqualTo(24));
    });

    // --- the floor (docs/Roadmap.md §G.8 R1) ---------------------------------

    testWidgets('should_never_give_the_master_less_than_its_floor', (
      tester,
    ) async {
      // The regression this guards: a bare flex share has **no floor**, so the
      // master shrank with the window while the content inside it did not. On
      // the calendar that left the month label 108 px at an 894 px window, and
      // it ellipsized — silently, because `TextOverflow.ellipsis` does not
      // throw, so no overflow-based walk could ever have seen it.
      //
      // 320 sits above the 4-of-10 share at these widths (700 px → 270), so it
      // is the floor that decides the width rather than the share.
      const floor = 320.0;
      for (final width in <double>[700, 800, TestWidths.tablet]) {
        await host(
          tester,
          const TwoPaneLayout(
            master: Text('master'),
            detail: Text('detail'),
            masterMinWidth: floor,
          ),
          width,
        );

        expect(isSplit(), isTrue, reason: 'expected a split at width $width');
        expect(
          masterPaneWidth(tester),
          greaterThanOrEqualTo(floor),
          reason: 'the master fell below its floor at width $width',
        );
      }
    });

    testWidgets('should_fill_the_row_exactly_with_both_panes_and_the_gap', (
      tester,
    ) async {
      // The explicit-width split must not leave a gap or overflow: master + gap
      // + detail has to come to the body width exactly, or the detail pane is
      // being silently squeezed.
      const width = 900.0;
      await host(
        tester,
        const TwoPaneLayout(master: Text('master'), detail: Text('detail')),
        width,
      );

      final master = masterPaneWidth(tester);
      final detail = tester.getSize(find.text('detail')).width;

      expect(master + AppSpacing.xl + detail, closeTo(width, 0.01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('should_stack_when_the_body_cannot_hold_both_floors', (
      tester,
    ) async {
      // A size class alone is not enough to justify a split. 768 px is
      // two-pane-capable, but two 400 px floors plus the gap need 824 — and a
      // squeezed pair is worse than the single column it replaced.
      await host(
        tester,
        const TwoPaneLayout(
          master: Text('master'),
          detail: Text('detail'),
          masterMinWidth: 400,
          detailMinWidth: 400,
        ),
        TestWidths.tablet,
      );

      expect(isSplit(), isFalse);
      // Stacking rearranges; it never drops a pane.
      expect(find.text('master'), findsOneWidget);
      expect(find.text('detail'), findsOneWidget);
    });

    testWidgets(
      'should_keep_both_panes_at_or_above_their_floors_at_every_width',
      (tester) async {
        // The calendar's floors, walked across every mandated width. Whichever
        // arrangement results, neither pane may be handed less than its floor —
        // that is the invariant the whole layout exists to hold.
        const masterFloor = 300.0;
        const detailFloor = 260.0;
        for (final width in TestWidths.all) {
          await host(
            tester,
            const TwoPaneLayout(
              master: Text('master'),
              detail: Text('detail'),
              masterMinWidth: masterFloor,
              detailMinWidth: detailFloor,
            ),
            width,
          );

          expect(
            tester.takeException(),
            isNull,
            reason: 'TwoPaneLayout threw at width $width',
          );
          if (!isSplit()) continue;

          expect(
            masterPaneWidth(tester),
            greaterThanOrEqualTo(masterFloor),
            reason: 'master below its floor at width $width',
          );
          expect(
            tester.getSize(find.text('detail')).width,
            greaterThanOrEqualTo(detailFloor),
            reason: 'detail below its floor at width $width',
          );
        }
      },
    );

    test('should_report_a_minimum_body_width_of_both_floors_plus_the_gap', () {
      const layout = TwoPaneLayout(master: SizedBox(), detail: SizedBox());
      expect(layout.minBodyWidth, 280 + AppSpacing.xl + 280);
    });

    test('should_split_exactly_at_the_sum_of_the_floors', () {
      // `fits` is the calendar's branch condition, so it has to agree with what
      // `build` does: a hair under the floors must mean "stack".
      const master = 300.0;
      const detail = 260.0;
      const minBody = master + AppSpacing.xl + detail;

      expect(
        TwoPaneLayout.fits(
          minBody,
          masterMinWidth: master,
          detailMinWidth: detail,
        ),
        isTrue,
      );
      expect(
        TwoPaneLayout.fits(
          minBody - 0.1,
          masterMinWidth: master,
          detailMinWidth: detail,
        ),
        isFalse,
      );
    });
  });

  group('ModalFormScaffold', () {
    testWidgets('should_render_a_plain_page_on_compact', (tester) async {
      await host(
        tester,
        const ModalFormScaffold(title: 'New', child: Text('form')),
        TestWidths.smallPhone,
      );

      expect(find.text('New'), findsOneWidget);
      expect(find.text('form'), findsOneWidget);
      // Compact gets no floating card.
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('should_render_a_centred_card_at_medium', (tester) async {
      await host(
        tester,
        const ModalFormScaffold(title: 'New', child: Text('form')),
        TestWidths.tablet,
      );

      expect(find.text('New'), findsOneWidget);
      expect(find.text('form'), findsOneWidget);
    });

    testWidgets('should_keep_the_app_bar_in_both_presentations', (
      tester,
    ) async {
      for (final width in <double>[TestWidths.smallPhone, TestWidths.desktop]) {
        await host(
          tester,
          const ModalFormScaffold(title: 'Edit', child: Text('form')),
          width,
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
        await host(
          tester,
          ModalFormScaffold(
            title: 'Edit',
            actions: <Widget>[
              TextButton(onPressed: () {}, child: const Text('Save')),
            ],
            child: const Text('form'),
          ),
          width,
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
      await host(
        tester,
        Builder(
          builder: (context) {
            padding = ResponsiveInsets.page(context, bottom: 0);
            return const SizedBox.shrink();
          },
        ),
        TestWidths.smallPhone,
      );

      expect(padding.left, 16);
      expect(padding.right, 16);
    });

    testWidgets('should_use_24_horizontal_padding_at_medium_and_up', (
      tester,
    ) async {
      late EdgeInsets padding;
      await host(
        tester,
        Builder(
          builder: (context) {
            padding = ResponsiveInsets.page(context, bottom: 0);
            return const SizedBox.shrink();
          },
        ),
        TestWidths.desktop,
      );

      expect(padding.left, 24);
      expect(padding.right, 24);
    });

    testWidgets('should_carry_the_requested_bottom_gap', (tester) async {
      late EdgeInsets padding;
      await host(
        tester,
        Builder(
          builder: (context) {
            padding = ResponsiveInsets.page(context, bottom: 88);
            return const SizedBox.shrink();
          },
        ),
        TestWidths.smallPhone,
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
        await host(
          tester,
          const TwoPaneLayout(master: Text('master'), detail: Text('detail')),
          width,
        );
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'TwoPaneLayout threw at width $width',
        );
      }
    });

    testWidgets('should_lay_out_a_form_constrained_by_width', (tester) async {
      for (final width in TestWidths.all) {
        await host(
          tester,
          const ModalFormScaffold(
            title: 'Form',
            child: SizedBox(height: 40, child: Text('field')),
          ),
          width,
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
        await pumpAppHost(
          tester,
          size: Size(width, 800),
          textScaler: const TextScaler.linear(2),
          home: const Scaffold(
            body: TwoPaneLayout(master: Text('master'), detail: Text('detail')),
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
