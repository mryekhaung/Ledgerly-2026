import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/settings/domain/entities/app_settings.dart';
import 'package:ledgerly/features/settings/presentation/widgets/choice_row.dart';
import 'package:ledgerly/features/settings/presentation/widgets/nav_row.dart';
import 'package:ledgerly/features/settings/presentation/widgets/settings_group.dart';
import 'package:material_ui/material_ui.dart';

/// Currency, appearance, week start and month-start rows.
///
/// Extracted from `settings_page.dart` (`docs/Conventions.md` §1).
class PreferencesSection extends ConsumerWidget {
  /// Creates a [PreferencesSection].
  const PreferencesSection({
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
        SectionHeader(label: strings('settingsPreferencesSection')),
        const SizedBox(height: AppSpacing.sm),
        SettingsGroup(
          children: <Widget>[
            ChoiceRow<CurrencyCode>(
              label: strings('settingsCurrencyLabel'),
              body: strings('settingsCurrencyBody'),
              value: settings.currency,
              // Every supported currency, symbol-first so the list reads as
              // "Ks / ¥ / $" rather than as ten ISO codes.
              options: <Choice<CurrencyCode>>[
                for (final currency in CurrencyCode.values)
                  Choice<CurrencyCode>(
                    value: currency,
                    label: '${currency.symbol}  ${currency.code}',
                  ),
              ],
              onChanged: (value) => onSave(settings.copyWith(currency: value)),
            ),
            const GroupDivider(),
            ChoiceRow<AppThemeMode>(
              label: strings('settingsThemeLabel'),
              value: settings.themeMode,
              options: <Choice<AppThemeMode>>[
                Choice<AppThemeMode>(
                  value: AppThemeMode.system,
                  label: strings('settingsThemeSystem'),
                ),
                Choice<AppThemeMode>(
                  value: AppThemeMode.light,
                  label: strings('settingsThemeLight'),
                ),
                Choice<AppThemeMode>(
                  value: AppThemeMode.dark,
                  label: strings('settingsThemeDark'),
                ),
              ],
              // Inline segments, not a sheet: three options that each change
              // the screen *behind* the control, so the result is visible
              // while choosing rather than after dismissing.
              layout: ChoiceLayout.segmented,
              onChanged: (value) => onSave(settings.copyWith(themeMode: value)),
            ),
            const GroupDivider(),
            ChoiceRow<WeekStart>(
              label: strings('settingsWeekStartLabel'),
              value: settings.weekStart,
              options: <Choice<WeekStart>>[
                Choice<WeekStart>(
                  value: WeekStart.monday,
                  label: strings('settingsWeekStartMonday'),
                ),
                Choice<WeekStart>(
                  value: WeekStart.sunday,
                  label: strings('settingsWeekStartSunday'),
                ),
              ],
              layout: ChoiceLayout.segmented,
              onChanged: (value) => onSave(settings.copyWith(weekStart: value)),
            ),
            const GroupDivider(),
            SettingsNavRow(
              label: strings('settingsMonthStartsOn'),
              subtitle: strings('settingsMonthStartsOnDescription'),
              trailingText: AppStrings.fill(context, 'monthStartsOnDayFormat', {
                'day': settings.monthStartDay,
              }),
              onTap: () =>
                  context.pushNamed(AppRoutes.settingsMonthStartsOnName),
            ),
          ],
        ),
      ],
    );
  }
}
