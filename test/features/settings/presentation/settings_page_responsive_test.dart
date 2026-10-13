import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/features/settings/presentation/pages/settings_page.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';

/// The settings page across the window size classes.
///
/// Settings is a short list of rows, so the only responsive decision worth
/// testing is that it does **not** stretch into an unreadably wide column on a
/// desktop. Rows keep their intrinsic height and the prose stops at
/// [AppSpacing.proseMaxWidth] — the same cap the transaction form uses, so the
/// two read as one product rather than two layout systems.
void main() {
  /// Hosts [SettingsPage] at a real surface [width] wide.
  ///
  /// The width has to be a genuine surface, not just `MediaQuery` data: the
  /// assertions below measure a [ConstrainedPane], which is an `Align` and so is
  /// exactly as wide as its parent. With only `MediaQuery` overridden the layout
  /// still runs against the 800 px test window and every measurement comes back
  /// 800 regardless of the width asked for.
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

  group('width cap', () {
    /// The width the rows are actually laid out at.
    ///
    /// `ConstrainedPane` is an `Align`, so the pane *widget* is always as wide
    /// as its parent — measuring it reports the window (1440 on a desktop) and
    /// would pass or fail for the wrong reason. The cap lives on the
    /// `ConstrainedBox` inside, so that is what the assertions below measure.
    ///
    /// `.first` because the pane is `Align → ConstrainedBox(child: …)` and the
    /// rows themselves contain further `ConstrainedBox`es; the descendant
    /// search finds them all, and only the outermost one carries the pane cap.
    double cappedWidth(WidgetTester tester) => tester
        .getSize(
          find
              .descendant(
                of: find.byType(ConstrainedPane),
                matching: find.byType(ConstrainedBox),
              )
              .first,
        )
        .width;

    testWidgets('should_cap_the_content_column_on_a_wide_window', (
      tester,
    ) async {
      await host(tester, TestWidths.wide);
      await tester.pumpAndSettle();

      // The pane exists at every width; on wide it is what stops the rows
      // spanning the full 1440 px.
      expect(find.byType(ConstrainedPane), findsOneWidget);

      final pane = tester.widget<ConstrainedPane>(find.byType(ConstrainedPane));
      expect(pane.maxWidth, AppSpacing.proseMaxWidth);
    });

    testWidgets('should_not_stretch_rows_past_the_prose_cap', (tester) async {
      await host(tester, TestWidths.wide);
      await tester.pumpAndSettle();

      expect(cappedWidth(tester), lessThanOrEqualTo(AppSpacing.proseMaxWidth));
    });

    testWidgets('should_use_the_full_width_of_a_phone', (tester) async {
      await host(tester, TestWidths.smallPhone);
      await tester.pumpAndSettle();

      // 360 px is narrower than the cap, so nothing should be wasted.
      expect(cappedWidth(tester), TestWidths.smallPhone);
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
