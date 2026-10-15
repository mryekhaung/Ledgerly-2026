import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/domain/usecases/save_settings.dart';
import 'package:ledgerly/features/settings/presentation/pages/month_starts_on_page.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';
import '../../../support/width_walk.dart';

void main() {
  AppSettings savedSettings = AppSettings.defaults;

  Future<void> host(
    WidgetTester tester, {
    AppSettings? settings,
    Locale locale = const Locale('en'),
    double width = 360,
    double height = 800,
    double textScale = 1.0,
    Future<Result<AppSettings>> Function(SaveSettingsParams)? onSave,
  }) {
    final current = settings ?? savedSettings;
    return pumpAppHost(
      tester,
      size: Size(width, height),
      locale: locale,
      textScaler: TextScaler.linear(textScale),
      overrides: <Override>[
        settingsProvider.overrideWith((ref) => Stream.value(current)),
        if (onSave != null)
          saveSettingsActionProvider.overrideWithValue(onSave),
      ],
      home: const MonthStartsOnPage(),
    );
  }

  setUp(() {
    savedSettings = AppSettings.defaults;
  });

  group('MonthStartsOnPage rendering', () {
    testWidgets('renders all 28 day chips', (tester) async {
      await host(tester);
      await tester.pumpAndSettle();

      for (var day = 1; day <= 28; day++) {
        expect(find.text('$day'), findsOneWidget);
      }
    });

    testWidgets('displays title, description, and preview card', (
      tester,
    ) async {
      await host(
        tester,
        settings: AppSettings.defaults.copyWith(monthStartDay: 10),
      );
      await tester.pumpAndSettle();

      expect(find.text('Month starts on'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.textContaining('Current period:'), findsOneWidget);
      expect(find.textContaining('Previous:'), findsOneWidget);
    });

    testWidgets('tapping a day chip saves the setting', (tester) async {
      AppSettings? saved;
      await host(
        tester,
        onSave: (params) async {
          saved = params.settings;
          return Success(params.settings);
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      expect(saved?.monthStartDay, 15);
    });
  });

  group('MonthStartsOnPage localization', () {
    testWidgets('renders in Burmese', (tester) async {
      await host(tester, locale: const Locale('my'));
      await tester.pumpAndSettle();

      expect(find.text('လစတင်ရက်'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.textContaining('လက်ရှိကာလ'), findsOneWidget);
      expect(find.textContaining('ယခင်ကာလ'), findsOneWidget);
    });

    testWidgets('renders in Japanese', (tester) async {
      await host(tester, locale: const Locale('ja'));
      await tester.pumpAndSettle();

      expect(find.text('月の開始日'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.textContaining('現在の期間'), findsOneWidget);
      expect(find.textContaining('前の期間'), findsOneWidget);
    });
  });

  // Replaces a hand-rolled loop that covered three widths
  // (phone/tablet/desktop) and missed 360, 430 and 1440, and that re-pumped on
  // top of the previous tree rather than unmounting. The page was migrated onto
  // `AppScaffold.contentMaxWidth` (`docs/Roadmap.md` §J), so the widths it did
  // not cover were exactly the ones the migration was not checked at.
  widthWalkGroup(pageName: 'MonthStartsOnPage', host: host);
}
