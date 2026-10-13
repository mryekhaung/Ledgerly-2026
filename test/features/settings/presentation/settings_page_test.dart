import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
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
      // so the service rows at the bottom do not exist until they are scrolled
      // into range. Walk the list down in steps and assert each label the first
      // time it appears, rather than assuming a 600 px window fits the whole
      // list.
      //
      // `scrollUntilVisible` is deliberately not used: it drags until its target
      // resolves, and throws `Bad state: No element` if the target never
      // materialises — which turns a "the row is missing" bug into an opaque
      // framework error. A bounded `drag` loop keeps the failure message on the
      // assertion that actually matters.
      const labels = <String>[
        'Settings',
        'Currency',
        'Appearance',
        'Week starts on',
        'Language',
        'Version',
      ];
      final missing = <String>{...labels};

      for (var step = 0; step < 12 && missing.isNotEmpty; step++) {
        for (final label in labels.toList(growable: false)) {
          if (find.text(label).evaluate().isNotEmpty) missing.remove(label);
        }
        if (missing.isEmpty) break;
        await tester.dragUntilVisible(
          find.text(labels.last),
          find.byType(ListView),
          const Offset(0, -120),
        );
        await tester.pump();
      }

      expect(missing, isEmpty, reason: 'rows never built: $missing');
      for (final label in labels) {
        expect(find.text(label), findsWidgets, reason: 'missing row $label');
      }
    });

    testWidgets('shows the current currency', (tester) async {
      await host(
        tester,
        AppSettings.defaults.copyWith(currency: CurrencyCode.usd),
      );
      await tester.pumpAndSettle();

      expect(find.text(r'$  USD'), findsOneWidget);
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

      final button = tester.widget<SegmentedButton<int>>(
        find.byType(SegmentedButton<int>).last,
      );
      // Sunday is index 1 in the options list.
      expect(button.selected, <int>{1});
    });
  });
}
