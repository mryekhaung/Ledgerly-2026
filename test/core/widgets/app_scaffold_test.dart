import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/app_test_host.dart';

/// `AppScaffold`'s content column, and the app-bar title that has to sit on it
/// (`docs/Roadmap.md` §G.8 R2).
///
/// A page used to cap its own body at 560 px and centre it, while `AppBar`
/// insets its title by a fixed `titleSpacing` (16 px). On any window wider than
/// the cap the two disagreed — **55 px** at an 894 px window — so the page read
/// as indented under its own heading. The scaffold now owns the column and
/// derives the title's inset from it, so the two edges agree by construction.
/// These tests pin that at every mandated width rather than at the one width the
/// defect happened to be seen on.
void main() {
  /// A page whose body is a single inset row, mirroring the migrated pages: the
  /// body insets itself with the shared page padding, and declares the prose cap
  /// on the scaffold.
  ///
  /// The inset is derived from [width] exactly as the real pages derive it from
  /// `MediaQuery.sizeOf(context).width`, so the assertion compares the title
  /// against the body's *content* edge rather than against a token the page does
  /// not actually use.
  Widget cappedPage(double width) => AppScaffold(
    title: 'Page Title',
    contentMaxWidth: AppSpacing.proseMaxWidth,
    body: ListView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal(width),
      ),
      children: const <Widget>[Text('First row')],
    ),
  );

  /// A page that declares no column — the default shape.
  Widget uncappedPage() =>
      const AppScaffold(title: 'Page Title', body: Text('First row'));

  Future<void> host(WidgetTester tester, double width, {Widget? page}) =>
      pumpAppHost(
        tester,
        size: Size(width, 800),
        home: page ?? cappedPage(width),
      );

  group('title aligns with the content column', () {
    testWidgets('should_put_the_title_on_the_columns_left_edge', (
      tester,
    ) async {
      // 894 is the width the defect was measured at: the column sits at 71 px
      // while the title sat at 16. The rest are the mandated widths, so the
      // invariant is pinned where the app is actually required to work.
      for (final width in <double>[894, ...TestWidths.all]) {
        await host(tester, width);
        await tester.pump();

        final titleLeft = tester.getTopLeft(find.text('Page Title')).dx;
        final contentLeft = tester.getTopLeft(find.text('First row')).dx;

        expect(
          titleLeft,
          closeTo(contentLeft, 0.01),
          reason:
              'the title and its content disagree at width $width — the page '
              'is indented under its own heading',
        );
      }
    });

    testWidgets('should_not_move_the_title_of_a_page_that_declares_no_column', (
      tester,
    ) async {
      // The opt-in has to be exactly that. A page that never passed
      // `contentMaxWidth` must keep the platform's default title inset, or
      // every uncapped screen silently shifts.
      const width = TestWidths.wide;

      await host(tester, width, page: uncappedPage());
      await tester.pump();
      final uncappedTitle = tester.getTopLeft(find.text('Page Title')).dx;

      await host(tester, width, page: cappedPage(width));
      await tester.pump();
      final cappedTitle = tester.getTopLeft(find.text('Page Title')).dx;

      // The capped page's title has moved onto its column's edge...
      expect(cappedTitle, greaterThan(uncappedTitle));
      // ...and the uncapped page's is still the bare M3 default.
      expect(uncappedTitle, closeTo(16, 0.01));
    });

    testWidgets('should_centre_the_column_and_leave_the_gutter_even', (
      tester,
    ) async {
      // Both gutters must match, or "centred" is only a word. Measured at a
      // width the column cannot fill.
      const width = 1200.0;
      await host(tester, width);
      await tester.pump();

      final column = tester.getRect(
        find
            .ancestor(
              of: find.text('First row'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );

      expect(column.width, closeTo(AppSpacing.proseMaxWidth, 0.01));
      expect(column.left, closeTo(width - column.right, 0.01));
    });
  });

  testWidgets('reserves the native tab bar overlay only when requested', (
    tester,
  ) async {
    await pumpAppHost(
      tester,
      size: const Size(400, 800),
      home: const AppScaffold(
        body: SizedBox.expand(),
        reserveNativeTabBarSpace: true,
        isIOS26: true,
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == const EdgeInsets.only(bottom: 96),
      ),
      findsOneWidget,
    );
  });

  testWidgets('does not reserve native tab bar space by default', (
    tester,
  ) async {
    await pumpAppHost(
      tester,
      size: const Size(400, 800),
      home: const AppScaffold(body: SizedBox.expand(), isIOS26: true),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == const EdgeInsets.only(bottom: 96),
      ),
      findsNothing,
    );
  });
}
