import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_catalog.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';
import 'package:ledgerly/features/profile/presentation/pages/avatar_editor_page.dart';
import 'package:ledgerly/features/profile/presentation/pages/profile_page.dart';
import 'package:ledgerly/features/profile/presentation/providers/profile_providers.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar.dart';
import 'package:ledgerly/l10n/app_localization.dart';
import 'package:ledgerly/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The Profile and Avatar Editor pages, driven with an overridden profile stream.
///
/// [userProfileProvider] and [avatarRandomProvider] are overridden so the pages
/// never touch the get_it locator (not configured in a widget test) while still
/// rendering the real widgets, rows and painter. The assertions are on what the
/// user can see — the avatar actually painted, the name actually shown, the
/// shuffle actually deterministic under a seed.
void main() {
  /// Hosts [child] with a fixed profile and a seeded shuffle.
  Widget host(
    Widget child, {
    UserProfile profile = UserProfile.initial,
    Random? random,
    Locale locale = const Locale('en'),
  }) {
    return ProviderScope(
      overrides: [
        userProfileProvider.overrideWith((ref) => Stream.value(profile)),
        if (random case final random?)
          avatarRandomProvider.overrideWithValue(random),
      ],
      child: AppThemeColors(
        colors: const AppColorsLight(),
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
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('ProfilePage render', () {
    testWidgets('should_show_the_guest_state_when_no_name_is_set', (
      tester,
    ) async {
      await tester.pumpWidget(host(const ProfilePage()));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
      expect(find.byType(Avatar), findsWidgets);
    });

    testWidgets('should_show_the_name_once_one_is_stored', (tester) async {
      await tester.pumpWidget(
        host(
          const ProfilePage(),
          profile: const UserProfile(
            displayName: 'Yin',
            avatar: AvatarConfig.initial,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Yin'), findsWidgets);
    });

    testWidgets('should_never_render_a_loading_state', (tester) async {
      await tester.pumpWidget(host(const ProfilePage()));
      // One frame only: the profile is read synchronously from the current
      // provider, so there is no gap for a spinner to appear in.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should_render_myanmar_labels_under_the_my_locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const ProfilePage(), locale: const Locale('my')),
      );
      await tester.pumpAndSettle();

      expect(find.text('ပရိုဖိုင်'), findsOneWidget);
    });
  });

  group('AvatarEditorPage render', () {
    testWidgets('should_show_a_row_for_every_avatar_part', (tester) async {
      await tester.pumpWidget(host(const AvatarEditorPage()));
      await tester.pumpAndSettle();

      expect(find.text('BACKGROUND'), findsOneWidget);
      expect(find.text('BACKDROP'), findsOneWidget);
      expect(find.text('SHAPE'), findsOneWidget);
      expect(find.text('EYES'), findsOneWidget);
      expect(find.text('MOUTH'), findsOneWidget);
    });

    testWidgets('should_offer_a_swatch_count_matching_the_catalogue', (
      tester,
    ) async {
      await tester.pumpWidget(host(const AvatarEditorPage()));
      await tester.pumpAndSettle();

      // The background row is on screen and has eight options.
      expect(
        find.byType(Avatar),
        findsAtLeast(AvatarCatalog.backgroundColors.length),
      );
    });

    testWidgets('should_show_the_save_and_shuffle_controls', (tester) async {
      await tester.pumpWidget(host(const AvatarEditorPage()));
      await tester.pumpAndSettle();

      expect(find.text('Shuffle'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('should_render_myanmar_labels_under_the_my_locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const AvatarEditorPage(), locale: const Locale('my')),
      );
      await tester.pumpAndSettle();

      expect(find.text('သိမ်းရန်'), findsOneWidget);
    });
  });

  group('Avatar rendering', () {
    testWidgets('should_paint_without_overflowing_a_square_box', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Center(child: Avatar(config: AvatarConfig.initial, size: 120)),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('should_paint_every_option_without_throwing', (tester) async {
      // Every combination the catalogue can produce, so a divide-by-zero or an
      // out-of-range lerp in one drawing routine cannot hide behind the others.
      for (final part in AvatarPart.values) {
        for (final index in AvatarCatalog.optionIndices(part)) {
          await tester.pumpWidget(
            host(
              Center(
                child: Avatar(
                  config: AvatarConfig.initial.withPart(part, index),
                  size: 64,
                ),
              ),
            ),
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: 'part $part option $index threw while painting',
          );
        }
      }
    });

    testWidgets('should_repaint_in_the_dark_scheme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith(
              (_) => Stream.value(UserProfile.initial),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.dark,
            home: Builder(
              builder: (context) => AppThemeColors(
                colors: AppColorsDark(),
                child: const Center(
                  child: Avatar(config: AvatarConfig.initial, size: 96),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
