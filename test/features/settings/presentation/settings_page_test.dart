import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/di/app_environment.dart';
import 'package:ledgerly/app/di/injection.dart';
import 'package:ledgerly/core/database/connection/database_connection.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/pages/settings_page.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';

/// The Settings page, driven with an overridden settings stream.
///
/// `settingsProvider` is overridden so the page never reaches the get_it locator
/// (not configured in a widget test) while still exercising the real page,
/// rows and controls. The assertions are on what the user can actually see —
/// a stale label on a settings row is the whole class of bug this catches.
void main() {
  /// Hosts [SettingsPage] with a fixed settings snapshot.
  ///
  /// The string lookup comes from the shared harness, so the page's
  /// `AppStrings.of` resolves real translations rather than being stubbed.
  Future<void> host(
    WidgetTester tester,
    AppSettings settings, {
    Locale locale = const Locale('en'),
  }) => pumpAppHost(
    tester,
    locale: locale,
    overrides: <Override>[
      settingsProvider.overrideWith((ref) => Stream.value(settings)),
    ],
    home: const SettingsPage(),
  );

  group('render', () {
    testWidgets('shows every section and row', (tester) async {
      await host(tester, AppSettings.defaults);
      await tester.pumpAndSettle();

      // A lazy `ListView` only builds the rows in (and just past) the viewport,
      // so the rows at the bottom do not exist until they are scrolled into
      // range. Scroll in fixed steps, recording every label seen at any point,
      // rather than assuming a 900 px window fits the whole list on one screen.
      //
      // `scrollUntilVisible` is deliberately not used: it drags until its target
      // resolves and throws `Bad state: No element` if the target never
      // materialises, which turns a "the row is missing" bug into an opaque
      // framework error. Dragging explicitly keeps the failure on the assertion
      // that names the missing row.
      const labels = <String>[
        'Settings',
        'Currency',
        'Appearance',
        'Week starts on',
        'Month starts on',
        'Language',
        'Version',
        'Credits',
      ];
      final seen = <String>{};

      // Match case-insensitively: section headers are upper-cased by
      // `_SectionHeader` (so "Language" renders as "LANGUAGE"), while row
      // titles keep their sentence case. The test's claim is "this text is on
      // screen", not "it has this exact casing" — the design system owns
      // casing, and pinning it here would fail the moment a header stops being
      // upper-cased for a legitimate styling reason.
      void recordVisible() {
        final onScreen = tester
            .widgetList<Text>(find.byType(Text))
            .map((widget) => widget.data?.toLowerCase())
            .whereType<String>()
            .toSet();
        for (final label in labels) {
          if (onScreen.contains(label.toLowerCase())) seen.add(label);
        }
      }

      recordVisible();
      for (var step = 0; step < 10; step++) {
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pump();
        recordVisible();
      }

      expect(seen, containsAll(labels), reason: 'rows never built');
    });

    testWidgets('shows the current currency', (tester) async {
      await host(
        tester,
        AppSettings.defaults.copyWith(currency: CurrencyCode.usd),
      );
      await tester.pumpAndSettle();

      expect(find.text(r'$  USD'), findsOneWidget);
    });

    testWidgets('shows the current month start day', (tester) async {
      await host(tester, AppSettings.defaults.copyWith(monthStartDay: 10));
      await tester.pumpAndSettle();

      expect(find.text('Day 10'), findsOneWidget);
    });

    testWidgets('shows System default when no language is pinned', (
      tester,
    ) async {
      await host(tester, AppSettings.defaults);
      await tester.pumpAndSettle();

      expect(find.text('System default'), findsOneWidget);
    });

    testWidgets('shows the pinned language name, not the tag', (tester) async {
      await host(tester, AppSettings.defaults.copyWith(localeCode: 'ja'));
      await tester.pumpAndSettle();

      expect(find.text('日本語'), findsOneWidget);
      expect(find.text('System default'), findsNothing);
    });

    testWidgets('shows credits entry and opens credits dialog', (tester) async {
      await host(tester, AppSettings.defaults);
      await tester.pumpAndSettle();

      for (var step = 0; step < 6; step++) {
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();
      }

      expect(find.text('Credits'), findsOneWidget);
      expect(find.textContaining('Open Peeps'), findsOneWidget);

      await tester.tap(find.text('Credits'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(
            'Avatar art: Open Peeps by Pablo Stanley (CC0 1.0), via DiceBear',
          ),
        ),
        findsOneWidget,
      );
    });
  });

  group('localization', () {
    testWidgets('renders Burmese labels under the my locale', (tester) async {
      await host(tester, AppSettings.defaults, locale: const Locale('my'));
      await tester.pumpAndSettle();

      expect(find.text('ဆက်တင်'), findsOneWidget);
      expect(find.text('ငွေကြေး'), findsOneWidget);
    });

    testWidgets('renders Japanese labels under the ja locale', (tester) async {
      await host(tester, AppSettings.defaults, locale: const Locale('ja'));
      await tester.pumpAndSettle();

      expect(find.text('設定'), findsOneWidget);
      expect(find.text('通貨'), findsOneWidget);
    });
  });

  group('segmented controls', () {
    testWidgets('exposes the three appearance options', (tester) async {
      await host(tester, AppSettings.defaults);
      await tester.pumpAndSettle();

      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('exposes both week-start options', (tester) async {
      await host(tester, AppSettings.defaults);
      await tester.pumpAndSettle();

      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);
    });

    testWidgets('marks the stored week start as selected', (tester) async {
      await host(
        tester,
        AppSettings.defaults.copyWith(weekStart: WeekStart.sunday),
      );
      await tester.pumpAndSettle();

      final control = tester.widget<SegmentedTabs<int>>(
        find.byType(SegmentedTabs<int>).last,
      );
      // Sunday is index 1 in the options list.
      expect(control.selected, 1);
    });

    testWidgets(
      'renders without error when configured with real DI container',
      (tester) async {
        await resetDependencies();
        await configureDependencies(
          environment: AppEnvironment.dev,
          connectionFactory: openInMemoryDatabase,
        );

        try {
          await pumpAppHost(
            tester,
            locale: const Locale('en'),
            home: const SettingsPage(),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(SettingsPage), findsOneWidget);
        } finally {
          await resetDependencies();
        }
      },
    );
  });
}
