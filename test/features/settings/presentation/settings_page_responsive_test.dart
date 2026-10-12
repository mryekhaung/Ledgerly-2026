import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/settings/presentation/pages/settings_page.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:ledgerly/l10n/app_localization.dart';
import 'package:ledgerly/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The settings page across the window size classes.
///
/// Settings is a short list of rows, so the only responsive decision worth
/// testing is that it does **not** stretch into an unreadably wide column on a
/// desktop. Rows keep their intrinsic height and the prose stops at
/// [AppSpacing.proseMaxWidth] — the same cap the transaction form uses, so the
/// two read as one product rather than two layout systems.
void main() {
  Widget host(double width, {double textScale = 1}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        supportedLocales: AppLocalization.supportedLocales
            .map(Locale.new)
            .toList(growable: false),
        localizationsDelegates: <LocalizationsDelegate<Object?>>[
          ...GlobalMaterialLocalizations.delegates,
          AppLocalizations.delegate,
        ],
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 900),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Builder(
            builder: (context) => AppStringsScope(
              lookup: AppStringLookup.of(AppLocalizations.of(context)),
              child: const SettingsPage(),
            ),
          ),
        ),
      ),
    );
  }

  group('width cap', () {
    testWidgets('should_cap_the_content_column_on_a_wide_window', (
      tester,
    ) async {
      await tester.pumpWidget(host(TestWidths.wide));
      await tester.pumpAndSettle();

      // The pane exists at every width; on wide it is what stops the rows
      // spanning the full 1440 px.
      expect(find.byType(ConstrainedPane), findsOneWidget);

      final pane = tester.widget<ConstrainedPane>(find.byType(ConstrainedPane));
      expect(pane.maxWidth, AppSpacing.proseMaxWidth);
    });

    testWidgets('should_not_stretch_rows_past_the_prose_cap', (tester) async {
      await tester.pumpWidget(host(TestWidths.wide));
      await tester.pumpAndSettle();

      final paneSize = tester.getSize(find.byType(ConstrainedPane));
      expect(paneSize.width, lessThanOrEqualTo(AppSpacing.proseMaxWidth));
    });

    testWidgets('should_use_the_full_width_of_a_phone', (tester) async {
      await tester.pumpWidget(host(TestWidths.smallPhone));
      await tester.pumpAndSettle();

      // 360 px is narrower than the cap, so nothing should be wasted.
      final paneSize = tester.getSize(find.byType(ConstrainedPane));
      expect(paneSize.width, TestWidths.smallPhone);
    });
  });

  group('every mandated width', () {
    testWidgets('should_lay_out_without_overflowing_at_any_width', (
      tester,
    ) async {
      for (final width in TestWidths.all) {
        await tester.pumpWidget(host(width));
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
        await tester.pumpWidget(host(width, textScale: 2));
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
