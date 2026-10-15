import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/widgets/choice_row.dart';
import 'package:ledgerly/features/settings/presentation/widgets/nav_row.dart';
import 'package:ledgerly/features/settings/presentation/widgets/settings_group.dart';
import 'package:material_ui/material_ui.dart';

/// Language picker plus links to the feature hubs.
///
/// Extracted from `settings_page.dart` (`docs/Conventions.md` §1).
class FeaturesSection extends ConsumerWidget {
  /// Creates a [FeaturesSection].
  const FeaturesSection({
    required this.settings,
    required this.onSave,
    super.key,
  });

  /// The current settings snapshot.
  final AppSettings settings;

  /// Persists the next settings value.
  final void Function(AppSettings next) onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(label: strings('settingsLanguageLabel')),
        const SizedBox(height: AppSpacing.sm),
        SettingsGroup(
          children: <Widget>[
            ChoiceRow<String?>(
              // Uses the section header as the visible label, so the row shows
              // only the current choice — a second copy of the word "Language"
              // next to a header that already says it is noise.
              label: null,
              value: settings.localeCode,
              options: <Choice<String?>>[
                // Null is a real option, not the absence of one: it is how
                // "follow the device" is stored, and it survives a round-trip
                // through the table by *deleting* the row rather than writing
                // a sentinel string.
                Choice<String?>(
                  value: null,
                  label: strings('settingsLanguageSystem'),
                ),
                const Choice<String?>(value: 'en', label: 'English'),
                const Choice<String?>(value: 'my', label: 'မြန်မာ'),
                const Choice<String?>(value: 'ja', label: '日本語'),
              ],
              onChanged: (value) => onSave(
                value == null
                    ? settings.clearLocale()
                    : settings.copyWith(localeCode: value),
              ),
            ),
            const GroupDivider(),
            SettingsNavRow(
              label: strings('accountsTitle'),
              subtitle: strings('accountsSubtitle'),
              leading: const Icon(AppIcons.wallet),
              onTap: () => context.pushNamed(AppRoutes.accountsName),
            ),
            const GroupDivider(),
            SettingsNavRow(
              label: strings('budgetsTitle'),
              subtitle: strings('budgetsTotal'),
              leading: const Icon(AppIcons.insights),
              onTap: () => context.pushNamed(AppRoutes.budgetsName),
            ),
            const GroupDivider(),
            SettingsNavRow(
              label: strings('recurringTitle'),
              subtitle: strings('recurringSubtitle'),
              leading: const Icon(AppIcons.pending),
              onTap: () => context.pushNamed(AppRoutes.recurringName),
            ),
            const GroupDivider(),
            SettingsNavRow(
              label: strings('settingsSavingsGoals'),
              subtitle: strings('settingsSavingsGoalsSubtitle'),
              leading: const Icon(AppIcons.goal),
              onTap: () => context.pushNamed(AppRoutes.goalsName),
            ),
          ],
        ),
      ],
    );
  }
}
