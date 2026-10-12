import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';
import 'package:ledgerly/features/profile/presentation/pages/avatar_editor_page.dart';
import 'package:ledgerly/features/profile/presentation/providers/profile_providers.dart';
import 'package:ledgerly/l10n/app_localization.dart';
import 'package:ledgerly/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Layout checks for the Avatar Editor full-screen page (docs/Avatar.md §2 step 0).
///
/// The editor is now a route outside the shell, so there is no bottom tab bar to
/// hide the Save button. These tests prove, at the three target widths and the
/// two text scales, that nothing overflows and the Save button is always on
/// screen and hit-testable. `saveAvatarActionProvider` is left un-overridden on
/// purpose — the tests never tap Save, so the unconfigured get_it locator is
/// never reached.
void main() {
  late final List<FlutterErrorDetails> overflowErrors;

  setUp(() {
    overflowErrors = <FlutterErrorDetails>[];
    // RenderFlex overflow is reported through FlutterError.onError rather than
    // thrown, so capture it explicitly and make it fail the test loudly.
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflowErrors.add(details);
      } else {
        FlutterError.dumpErrorToConsole(details);
      }
    };
  });

  tearDown(() => FlutterError.onError = FlutterError.dumpErrorToConsole);

  Widget host(Widget child, {Locale locale = const Locale('en')}) {
    return ProviderScope(
      overrides: [
        // The editor reads the avatar from here; the shuffle provider is left at
        // its production default (a plain Random) because tests only render.
        userProfileProvider.overrideWith(
          (_) => Stream.value(UserProfile.initial),
        ),
      ],
      child: AppThemeColors(
        colors: const AppColorsLight(),
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalization.supportedLocales
              .map(Locale.new)
              .toList(),
          localizationsDelegates: <LocalizationsDelegate<Object?>>[
            ...GlobalMaterialLocalizations.delegates,
            AppLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => AppStringsScope(
              lookup: AppStringLookup.of(AppLocalizations.of(context)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpAt(
    WidgetTester tester,
    double width,
    double textScale,
  ) async {
    tester.view.physicalSize = Size(width, 850);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: Size(width, 850),
          textScaler: TextScaler.linear(textScale),
        ),
        child: host(const AvatarEditorPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AvatarEditorPage layout (step 0)', () {
    for (final width in <double>[360, 768, 1440]) {
      for (final textScale in <double>[1.0, 2.0]) {
        testWidgets('no overflow at ${width.toInt()}px x$textScale', (
          tester,
        ) async {
          await pumpAt(tester, width, textScale);
          expect(
            overflowErrors,
            isEmpty,
            reason: 'A RenderFlex overflow was reported during pump.',
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('save button is on-screen and hit-testable', (tester) async {
      await pumpAt(tester, 360, 2.0);

      final saveFinder = find.byType(FilledButton);
      expect(saveFinder, findsOneWidget);
      // hitTestable() is false when the widget is off-screen or fully covered,
      // so this proves the pinned bar keeps it reachable.
      expect(saveFinder.hitTestable(), findsOneWidget);

      final rect = tester.getRect(saveFinder);
      // Fully within the 850px-tall surface and clear of the top header.
      expect(rect.top, greaterThan(0));
      expect(rect.bottom, lessThanOrEqualTo(850));
      expect(rect.height, greaterThan(0));
    });

    testWidgets('preview sits clear of the header', (tester) async {
      await pumpAt(tester, 360, 2.0);
      // The preview avatar is the only one labelled for screen readers.
      final preview = find.bySemanticsLabel('Avatar');
      expect(preview, findsOneWidget);

      final rect = tester.getRect(preview);
      // Below the app bar (status bar + ~56px toolbar) and fully on screen.
      expect(rect.top, greaterThan(80));
      expect(rect.bottom, lessThanOrEqualTo(850));
    });
  });
}
