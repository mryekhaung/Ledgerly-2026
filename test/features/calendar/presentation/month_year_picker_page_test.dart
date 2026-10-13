import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/month_year_picker_page.dart';
import 'package:ledgerly/l10n/app_localization.dart';
import 'package:ledgerly/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';

/// A fixed month so the tests do not depend on the clock.
///
/// `LocalDate` has a validating factory, so it can never be `const` — this is a
/// `final` top-level, not a compile-time constant.
final _may2026 = LocalDate(2026, 5, 1);

/// The month/year picker opened from the calendar header.
///
/// The behaviours worth pinning are the ones a user would notice: the tapped
/// month is returned as a *first day* (the calendar's invariant), the year
/// arrows move the grid without choosing anything, and the range edges disable
/// the arrow rather than offering a tap that does nothing.
void main() {
  /// Hosts the picker over [initialMonth] and captures whatever it pops.
  Future<LocalDate?> Function() host(
    WidgetTester tester,
    LocalDate initialMonth, {
    int range = 50,
    Locale? locale,
  }) {
    LocalDate? popped;

    final app = MaterialApp(
      theme: AppTheme.light(),
      locale: locale ?? const Locale('en'),
      supportedLocales: AppLocalization.supportedLocales
          .map(Locale.new)
          .toList(growable: false),
      localizationsDelegates: const <LocalizationsDelegate<Object?>>[
        ...GlobalMaterialLocalizations.delegates,
        AppLocalizations.delegate,
      ],
      // `builder` (not `home`) so the scopes sit above the `Navigator`: the
      // picker is pushed onto it and needs `AppThemeColors`/`AppStrings` too.
      builder: (context, child) =>
          AppTestScopes(child: child ?? const SizedBox.shrink()),
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (inner) => TextButton(
              onPressed: () async {
                popped = await Navigator.of(inner).push<LocalDate>(
                  MaterialPageRoute<LocalDate>(
                    builder: (_) => MonthYearPickerPage(
                      initialMonth: initialMonth,
                      selectableYearRange: range,
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    return () async {
      await tester.pumpWidget(app);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return popped;
    };
  }

  testWidgets('should_highlight_the_initial_month_and_its_year', (
    tester,
  ) async {
    await host(tester, LocalDate(2026, 5, 1))();
    await tester.pumpAndSettle();

    // The year header.
    expect(find.text('2026'), findsOneWidget);
    // Twelve month tiles are on screen. Each label is CLDR's month+year (via
    // `MaterialLocalizations.formatMonthYear`), not a bare month name — the
    // picker deliberately reuses the platform's locale data instead of putting
    // 12 names × 3 locales in the ARB.
    expect(find.text('May 2026'), findsOneWidget);
    expect(find.text('January 2026'), findsOneWidget);
    expect(find.text('December 2026'), findsOneWidget);
  });

  testWidgets('should_return_the_first_day_of_the_tapped_month', (
    tester,
  ) async {
    final read = host(tester, LocalDate(2026, 5, 17));
    await read();
    await tester.pumpAndSettle();

    await tester.tap(find.text('August 2026'));
    await tester.pumpAndSettle();

    // Key assertion: the *17th* was the initial day, but the result must be the
    // 1st — the calendar's `visibleMonth` invariant is a first-of-month.
    expect(read(), completion(LocalDate(2026, 8, 1)));
  });

  testWidgets('should_move_the_year_without_choosing_a_month', (tester) async {
    final read = host(tester, LocalDate(2026, 5, 1));
    await read();
    await tester.pumpAndSettle();

    // Tap "next year" — the picker is still open, so nothing has popped.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('2027'), findsOneWidget);
    expect(find.text('2026'), findsNothing);
    // Still on the picker: browsing is not choosing.
    expect(find.text('January 2027'), findsOneWidget);
  });

  testWidgets('should_go_back_a_year_too', (tester) async {
    await host(tester, LocalDate(2026, 5, 1))();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('2025'), findsOneWidget);
  });

  testWidgets('should_disable_the_back_arrow_at_the_lower_year_bound', (
    tester,
  ) async {
    // Range 0 puts both bounds on the initial year.
    await host(tester, LocalDate(2026, 5, 1), range: 0)();
    await tester.pumpAndSettle();

    final back = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.chevron_left),
        matching: find.byType(IconButton),
      ),
    );
    final forward = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.chevron_right),
        matching: find.byType(IconButton),
      ),
    );

    expect(back.onPressed, isNull);
    expect(forward.onPressed, isNull);
  });

  testWidgets('should_clamp_the_lower_bound_to_year_1', (tester) async {
    // A 50-year range around year 10 would reach year -40; it must stop at 1.
    await host(tester, LocalDate(10, 5, 1))();
    await tester.pumpAndSettle();

    // Tap back until the arrow disables, then assert we stopped at year 1.
    for (var i = 0; i < 12; i++) {
      final button = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.chevron_left),
          matching: find.byType(IconButton),
        ),
      );
      if (button.onPressed == null) break;
      button.onPressed!();
      await tester.pumpAndSettle();
    }

    expect(find.text('1'), findsOneWidget);
    final back = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.chevron_left),
        matching: find.byType(IconButton),
      ),
    );
    expect(back.onPressed, isNull);
  });

  testWidgets('should_render_the_myanmar_title', (tester) async {
    await host(tester, LocalDate(2026, 5, 1), locale: const Locale('my'))();
    await tester.pumpAndSettle();

    expect(find.text('လသို့ ခုန်ရန်'), findsOneWidget);
  });

  testWidgets('should_lay_out_without_overflow_at_a_phone_width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await host(tester, LocalDate(2026, 5, 1))();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('should_lay_out_without_overflow_at_text_scale_2', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        supportedLocales: AppLocalization.supportedLocales
            .map(Locale.new)
            .toList(growable: false),
        localizationsDelegates: const <LocalizationsDelegate<Object?>>[
          ...GlobalMaterialLocalizations.delegates,
          AppLocalizations.delegate,
        ],
        builder: (context, child) => AppTestScopes(
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: MonthYearPickerPage(initialMonth: _may2026),
      ),
    );
    await tester.pumpAndSettle();

    // The 3x4 grid at double text scale is the real risk: each tile's label
    // wraps to two lines, so a too-short aspect ratio would overflow.
    expect(tester.takeException(), isNull);
  });
}
