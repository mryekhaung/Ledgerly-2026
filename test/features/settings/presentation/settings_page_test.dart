import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/pages/settings_page.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/l10n/app_localization.dart';
import 'package:ledgerly/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The Settings page, driven with an overridden settings stream.
///
/// `settingsProvider` is overridden so the page never reaches the get_it locator
/// (not configured in a widget test) while still exercising the real page,
/// rows and controls. The assertions are on what the user can actually see —
/// a stale label on a settings row is the whole class of bug this catches.
void main() {
  /// Hosts [SettingsPage] with a fixed settings snapshot.
  ///
  /// The string lookup is wired the way `app.dart` wires it, so the page's
  /// `AppStrings.of` resolves real translations rather than being stubbed.
  Widget host(AppSettings settings, {Locale locale = const Locale('en')}) {
    return ProviderScope(
      overrides: [
        settingsProvider.overrideWith((ref) => Stream.value(settings)),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalization.supportedLocales
            .map(Locale.new)
            .toList(growable: false),
        localizationsDelegates: <LocalizationsDelegate<Object?>>[
          ...GlobalMaterialLocalizations.delegates,
          AppLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => AppStringsScope(
            lookup: AppStringLookup.of(AppLocalizations.of(context)),
            child: const SettingsPage(),
          ),
        ),
      ),
    );
  }

  group('render', () {
    testWidgets('shows every section and row', (tester) async {
      await tester.pumpWidget(host(AppSettings.defaults));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Week starts on'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Version'), findsOneWidget);
    });

    testWidgets('shows the current currency', (tester) async {
      await tester.pumpWidget(
        host(AppSettings.defaults.copyWith(currency: CurrencyCode.usd)),
      );
      await tester.pumpAndSettle();

      expect(find.text(r'$  USD'), findsOneWidget);
    });

    testWidgets('shows System default when no language is pinned', (
      tester,
    ) async {
      await tester.pumpWidget(host(AppSettings.defaults));
      await tester.pumpAndSettle();

      expect(find.text('System default'), findsOneWidget);
    });

    testWidgets('shows the pinned language name, not the tag', (tester) async {
      await tester.pumpWidget(
        host(AppSettings.defaults.copyWith(localeCode: 'ja')),
      );
      await tester.pumpAndSettle();

      expect(find.text('日本語'), findsOneWidget);
      expect(find.text('System default'), findsNothing);
    });
  });

  group('localization', () {
    testWidgets('renders Burmese labels under the my locale', (tester) async {
      await tester.pumpWidget(
        host(AppSettings.defaults, locale: const Locale('my')),
      );
      await tester.pumpAndSettle();

      expect(find.text('ဆက်တင်'), findsOneWidget);
      expect(find.text('ငွေကြေး'), findsOneWidget);
    });

    testWidgets('renders Japanese labels under the ja locale', (tester) async {
      await tester.pumpWidget(
        host(AppSettings.defaults, locale: const Locale('ja')),
      );
      await tester.pumpAndSettle();

      expect(find.text('設定'), findsOneWidget);
      expect(find.text('通貨'), findsOneWidget);
    });
  });

  group('segmented controls', () {
    testWidgets('exposes the three appearance options', (tester) async {
      await tester.pumpWidget(host(AppSettings.defaults));
      await tester.pumpAndSettle();

      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('exposes both week-start options', (tester) async {
      await tester.pumpWidget(host(AppSettings.defaults));
      await tester.pumpAndSettle();

      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);
    });

    testWidgets('marks the stored week start as selected', (tester) async {
      await tester.pumpWidget(
        host(AppSettings.defaults.copyWith(weekStart: WeekStart.sunday)),
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
