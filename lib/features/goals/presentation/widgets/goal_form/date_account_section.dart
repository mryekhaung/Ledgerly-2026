import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveListTile;
import 'package:flutter/material.dart' as flutter_material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/app_select_field.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:material_ui/material_ui.dart';

/// Target-date tile and linked-account dropdown.
///
/// Extracted from `goal_form_page.dart` (`docs/Conventions.md` §1).
class GoalDateAccountSection extends StatelessWidget {
  /// Creates a [GoalDateAccountSection].
  const GoalDateAccountSection({
    required this.targetDate,
    required this.noDateLabel,
    required this.onPickDate,
    required this.onClearDate,
    required this.accounts,
    required this.accountId,
    required this.onAccountChanged,
    super.key,
  });

  /// The target date, if set.
  final LocalDate? targetDate;

  /// The placeholder when no date is set.
  final String noDateLabel;

  /// Called to open the date picker.
  final VoidCallback onPickDate;

  /// Called to clear the date.
  final VoidCallback onClearDate;

  /// The accounts for the dropdown (async: loading renders nothing).
  final AsyncValue<List<Account>> accounts;

  /// The linked account id, if any.
  final String? accountId;

  /// Called with the picked account id (null clears).
  final ValueChanged<String?> onAccountChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Target Date picker tile
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: AppRadius.borderSm,
            border: Border.all(color: colors.border),
          ),
          child: flutter_material.Material(
            type: flutter_material.MaterialType.transparency,
            child: AdaptiveListTile(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              backgroundColor: Colors.transparent,
              hideBottomDivider: true,
              title: Text(strings('goalTargetDateLabel')),
              subtitle: Text(
                // §7: dates render via intl for the active locale, never as a
                // hand-built ISO fragment.
                targetDate != null
                    ? DateFormat.yMd(
                        Localizations.localeOf(context).toLanguageTag(),
                      ).format(targetDate!.toDateTime())
                    : noDateLabel,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (targetDate != null)
                    IconButton(
                      icon: const Icon(AppIcons.close, size: 20),
                      onPressed: onClearDate,
                    ),
                  const Icon(AppIcons.calendar),
                ],
              ),
              onTap: onPickDate,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Account selection
        accounts.when(
          data: (accounts) => AppSelectField<String?>(
            value: accountId,
            decoration: InputDecoration(
              labelText: strings('goalAccountLabel'),
              border: const OutlineInputBorder(),
            ),
            options: [
              AppSelectOption<String?>(
                value: null,
                child: Text(strings('goalNoAccountOption')),
              ),
              for (final acc in accounts)
                AppSelectOption<String?>(value: acc.id, child: Text(acc.name)),
            ],
            onChanged: onAccountChanged,
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
