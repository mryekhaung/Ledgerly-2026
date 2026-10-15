import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// A row that navigates somewhere: optional leading widget, label, chevron.
///
/// Extracted from `settings_page.dart` (`docs/Conventions.md` §1).
class SettingsNavRow extends StatelessWidget {
  /// Creates a [SettingsNavRow].
  const SettingsNavRow({
    required this.label,
    required this.onTap,
    this.leading,
    this.subtitle,
    this.trailingText,
    super.key,
  });

  /// The row label.
  final String label;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// Shown before the label — the user's avatar, for the profile row.
  final Widget? leading;

  /// Optional supporting text below the label.
  final String? subtitle;

  /// Optional value text shown before the chevron.
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppRowHeight.absoluteMinimum,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                if (leading case final leading?) ...<Widget>[
                  leading,
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: colors.textPrimary),
                      ),
                      if (subtitle case final subtitle?) ...<Widget>[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingText case final trailingText?) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    trailingText,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ],
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  AppIcons.chevronRight,
                  size: 20,
                  color: colors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A read-only row: label on the left, value on the right.
///
/// Extracted from `settings_page.dart` (`docs/Conventions.md` §1).
class SettingsInfoRow extends StatelessWidget {
  /// Creates a [SettingsInfoRow].
  const SettingsInfoRow({required this.label, required this.value, super.key});

  /// The row label.
  final String label;

  /// The value text.
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppRowHeight.absoluteMinimum,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: colors.textPrimary),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
