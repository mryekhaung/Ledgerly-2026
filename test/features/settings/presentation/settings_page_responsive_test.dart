import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/settings/presentation/pages/settings_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';

/// The settings page across the window size classes.
///
/// Settings is a short list of rows, so the only responsive decision worth
/// testing is that it does **not** stretch into an unreadably wide column on a
/// desktop. Rows keep their intrinsic height and the column stops at
/// [AppSpacing.proseMaxWidth] — the same cap the transaction form uses, so the
/// two read as one product rather than two layout systems.
///
/// The cap is declared on `AppScaffold` (`contentMaxWidth`) rather than on the
/// body, because the frame has to know the column's inset in order to put the
/// app-bar title on its left edge (`docs/Roadmap.md` §G.8 R2). These tests
/// therefore measure the **frame's** column rather than a page-level widget.
void main() {
  /// Hosts [SettingsPage] at a real surface [width] wide.
  ///
  /// The width has to be a genuine surface, not just `MediaQuery` data: the
  /// column is an `Align`ed `ConstrainedBox`, which is as wide as its parent, so
  /// with only `MediaQuery` overridden every measurement would come back 800
  /// regardless of the width asked for.
  Future<void> host(
    WidgetTester tester,
    double width, {
    double textScale = 1,
  }) => pumpAppHost(
    tester,
    size: Size(width, 900),
    textScaler: TextScaler.linear(textScale),
    home: const SettingsPage(),
  );

  /// The frame's content column — the box the rows are actually laid out in.
  ///
  /// Found by walking outward from the body's `ListView` to its nearest
  /// `ConstrainedBox`, which is the scaffold's column. The page declares no cap
  /// of its own, so that is the only one above the list.
  Finder columnFinder() => find
      .ancestor(
        of: find.byType(ListView),
        matching: find.byType(ConstrainedBox),
      )
      .first;

  /// The width the rows are actually laid out at.
  double columnWidth(WidgetTester tester) =>
      tester.getSize(columnFinder()).width;

  group('content column', () {
    testWidgets('should_declare_the_prose_cap_on_the_frame', (tester) async {
      await host(tester, TestWidths.wide);
      await tester.pumpAndSettle();

      final scaffold = tester.widget<AppScaffold>(find.byType(AppScaffold));
      expect(scaffold.contentMaxWidth, AppSpacing.proseMaxWidth);
    });

    testWidgets('should_cap_the_column_on_a_wide_window', (tester) async {
      await host(tester, TestWidths.wide);
      await tester.pumpAndSettle();

      expect(columnWidth(tester), closeTo(AppSpacing.proseMaxWidth, 0.01));
    });

    testWidgets('should_not_stretch_the_rows_past_the_prose_cap', (
      tester,
    ) async {
      await host(tester, TestWidths.desktop);
      await tester.pumpAndSettle();

      expect(columnWidth(tester), lessThanOrEqualTo(AppSpacing.proseMaxWidth));
    });

    testWidgets('should_use_the_full_width_of_a_phone', (tester) async {
      await host(tester, TestWidths.smallPhone);
      await tester.pumpAndSettle();

      // 360 px is narrower than the cap, so nothing should be wasted.
      expect(columnWidth(tester), TestWidths.smallPhone);
    });
  });

  group('every mandated width', () {
    testWidgets('should_lay_out_without_overflowing_at_any_width', (
      tester,
    ) async {
      for (final width in TestWidths.all) {
        await host(tester, width);
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'SettingsPage threw at width $width',
        );
      }
    });

    testWidgets('should_lay_out_without_overflowing_at_text_scale_2', (
      tester,
    ) async {
      for (final width in TestWidths.all) {
        await host(tester, width, textScale: 2);
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'SettingsPage threw at width $width, text scale 2.0',
        );
      }
    });
  });
}
