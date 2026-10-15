import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The key-based lookup contract (`docs/Conventions.md` §5).
///
/// Every ARB key the app can produce at runtime must resolve; anything else
/// must throw loudly. A silent fallback once rendered "Please check the
/// highlighted fields." for half a dozen real keys, which is how this file
/// earned its existence.
void main() {
  AppLocalizations en() => lookupAppLocalizations(const Locale('en'));

  group('AppStrings lookup', () {
    test('should_resolve_recently_added_keys', () {
      final lookup = AppStringLookup.of(en());

      expect(lookup('goalNoAccountOption'), 'None (General Saved)');
      expect(lookup('goalNoDate'), 'Not set');
      expect(lookup('signInOrDivider'), 'OR');
      expect(lookup('accountNameHint'), isNotEmpty);
      expect(lookup('authErrorSignInFailed'), isNotEmpty);
    });

    test('should_throw_for_an_unknown_key', () {
      final lookup = AppStringLookup.of(en());

      expect(() => lookup('no_such_key_anywhere'), throwsFlutterError);
    });

    test('should_cover_every_arb_key', () {
      // A key with no case renders as whatever the wildcard does — which is
      // how half a dozen real keys once shipped as "Please check the
      // highlighted fields." Reading the ARB keeps this test honest when keys
      // are added: add the case in the same commit or this goes red.
      final arb = File('lib/l10n/app_en.arb').readAsStringSync();
      final keys = RegExp(
        r'^  "([A-Za-z][A-Za-z0-9]*)":',
        multiLine: true,
      ).allMatches(arb).map((m) => m.group(1)!).toSet();
      final source = File('lib/core/presentation/app_strings.dart')
          .readAsStringSync();

      expect(keys, isNotEmpty);
      final uncovered = keys
          .where((key) => !source.contains("'$key' =>"))
          .toList();
      expect(
        uncovered,
        isEmpty,
        reason: 'ARB keys with no lookup case: $uncovered',
      );
    });
  });

  group('AppStrings.fill', () {
    Future<String> fillInApp(
      WidgetTester tester,
      String key,
      Map<String, Object> values,
    ) async {
      late String result;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            ...GlobalMaterialLocalizations.delegates,
            AppLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              result = AppStrings.fill(context, key, values);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('should_fill_the_scheduler_summary', (tester) async {
      final text = await fillInApp(tester, 'recurringProcessedSuccess', const {
        'count': 3,
      });

      expect(text, contains('3'));
    });

    testWidgets('should_throw_for_an_unknown_fill_key', (tester) async {
      late Object? error;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            ...GlobalMaterialLocalizations.delegates,
            AppLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              try {
                AppStrings.fill(context, 'no_such_key', const {});
              } catch (e) {
                error = e;
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(error, isFlutterError);
    });
  });
}
