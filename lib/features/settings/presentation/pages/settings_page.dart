import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_dialog.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/settings/presentation/widgets/about_section.dart';
import 'package:ledgerly/features/settings/presentation/widgets/features_section.dart';
import 'package:ledgerly/features/settings/presentation/widgets/preferences_section.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// App settings: currency, language, appearance and week start.
///
/// **No local state.** Every row reads the current value from
/// [currentSettingsProvider] and writes through [saveSettingsActionProvider], so
/// the Drift stream stays the single source of truth: a toggle repaints the app
/// (theme, locale, every amount) without this page holding a copy that could go
/// stale (`docs/Architecture.md` §5).
///
/// The page never fails to render. A preference that cannot be read decodes to
/// its default rather than an error (`SettingsLocalDataSource._decode`), so the
/// only state that can actually fail is the *write* — which surfaces as a
/// snackbar and leaves the switch where it was, because the stream will not have
/// emitted the change.
///
/// Composition root only: sections live in `widgets/`
/// (`docs/Conventions.md` §1).
class SettingsPage extends ConsumerWidget {
  /// Creates the page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final settings = ref.watch(currentSettingsProvider);

    Future<void> save(AppSettings next) => _save(context, ref, next, strings);

    return AppScaffold(
      title: strings('settingsTitle'),
      // Width-capped rather than stretched: a preference row reads as a row at
      // 560 px and as a stranded label at 1200 (`docs/Design.md` §8). Declared
      // on the scaffold rather than on the body so it can line the title up with
      // the column it is centring.
      contentMaxWidth: AppSpacing.proseMaxWidth,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal(MediaQuery.sizeOf(context).width),
          AppSpacing.lg,
          AppSpacing.pageHorizontal(MediaQuery.sizeOf(context).width),
          AppSpacing.lg + MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: <Widget>[
          PreferencesSection(settings: settings, onSave: save),
          const SizedBox(height: AppSpacing.lg),
          FeaturesSection(settings: settings, onSave: save),
          const SizedBox(height: AppSpacing.lg),
          AboutSection(
            version: _AppVersion.display,
            onCreditsTap: () => _showCreditsDialog(context, strings),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  /// Persists [next] and reports the outcome.
  ///
  /// Deliberately does **not** optimistically update anything: the Drift stream
  /// is what repaints the page, which means a failed write leaves the control
  /// showing the old value — the honest result — instead of a change that did
  /// not stick.
  static Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    AppSettings next,
    String Function(String key) strings,
  ) async {
    final result = await ref.read(saveSettingsActionProvider)((
      settings: next,
      partial: false,
    ));

    // The page can be popped mid-write (a fast back-tap), and mounted is the
    // guard that keeps this from touching a disposed element.
    if (!context.mounted) return;

    if (result.isSuccess) {
      // A settings change already repaints the row, so the tap is the
      // acknowledgement and the snack bar is only the confirmation
      // (`docs/Platform.md` §6).
      AppFeedback.selection();
      AppFeedback.confirm(context, message: strings('settingsSaved'));
      return;
    }
    AppFeedback.destructive();
    AppFeedback.failure(context, message: strings('settingsSaveFailed'));
  }

  static void _showCreditsDialog(
    BuildContext context,
    String Function(String key) strings,
  ) {
    unawaited(
      AppDialog.show<void>(
        context: context,
        title: strings('settingsCreditsTitle'),
        content: strings('settingsCreditsAvatar'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings('actionDone')),
          ),
        ],
      ),
    );
  }
}

/// The app version shown in the About section.
///
/// A constant rather than a `package_info_plus` read: the plugin adds a platform
/// channel and an async startup dependency for a string that changes once per
/// release. `pubspec.yaml` is the source of truth and this is updated with it —
/// the release checklist in `docs/Platform.md` §7 names it.
abstract final class _AppVersion {
  const _AppVersion._();

  /// Semver + build, matching `pubspec.yaml` `version:`.
  static const String display = '1.0.0 (1)';
}
