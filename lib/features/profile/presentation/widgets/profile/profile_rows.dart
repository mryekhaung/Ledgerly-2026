import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show
        AdaptiveAlertDialog,
        AdaptiveAlertDialogInput,
        AlertAction,
        AlertActionStyle,
        PlatformInfo;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';
import 'package:ledgerly/features/profile/domain/usecases/save_display_name.dart';
import 'package:ledgerly/features/profile/presentation/providers/profile_providers.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar.dart';
import 'package:ledgerly/features/profile/presentation/widgets/profile/rename_dialog.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// The avatar row — tap to open the editor.
///
/// Extracted from `profile_page.dart` (`docs/Conventions.md` §1).
class AvatarRow extends StatelessWidget {
  /// Creates an [AvatarRow].
  const AvatarRow({required this.profile, super.key});

  /// The profile to render.
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);

    return TappableRow(
      onTap: () => context.pushNamed(AppRoutes.avatarEditorName),
      leading: Avatar(config: profile.avatar, size: 40),
      label: strings('profileAvatarLabel'),
      value: strings('profileEditAvatar'),
      valueColor: colors.brandPrimary,
    );
  }
}

/// The display-name row — tap to open the rename dialog.
///
/// Extracted from `profile_page.dart` (`docs/Conventions.md` §1).
class NameRow extends ConsumerWidget {
  /// Creates a [NameRow].
  const NameRow({required this.profile, super.key});

  /// The profile to render.
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);

    return TappableRow(
      onTap: () => _rename(context, ref),
      leading: Icon(AppIcons.badge, size: 24, color: colors.textTertiary),
      label: strings('profileNameLabel'),
      value: profile.hasName
          ? profile.displayName
          : strings('profileNamePlaceholder'),
      valueColor: profile.hasName ? colors.textSecondary : colors.textTertiary,
    );
  }

  /// Opens the rename dialog and persists whatever comes back.
  ///
  /// A dialog rather than a sub-page: it is one text field, and a route
  /// transition for a single field makes the back gesture ambiguous (does it
  /// cancel, or save?).
  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final strings = AppStrings.of(context);
    final current = profile.displayName;

    final entered =
        AppPlatform.resolve().usesCupertino && PlatformInfo.isIOS26OrHigher()
        ? await AdaptiveAlertDialog.inputShow(
            context: context,
            title: strings('profileEditName'),
            actions: <AlertAction>[
              AlertAction(
                title: strings('actionCancel'),
                style: AlertActionStyle.cancel,
                onPressed: () {},
              ),
              AlertAction(
                title: strings('actionSave'),
                style: AlertActionStyle.primary,
                onPressed: () {},
              ),
            ],
            input: AdaptiveAlertDialogInput(
              placeholder: strings('profileNameHint'),
              initialValue: current,
              maxLength: SaveDisplayName.maxLength,
            ),
          )
        : await showDialog<String>(
            context: context,
            builder: (dialogContext) => RenameDialog(initial: current),
          );

    // Null is "cancelled"; an unchanged value is a no-op the user did not ask
    // for, so neither reaches the use case.
    if (entered == null || entered.trim() == current) return;

    final result = await ref.read(saveDisplayNameActionProvider)((
      displayName: entered,
    ));

    if (!context.mounted) return;

    final message = result.fold(
      onSuccess: (_) => strings('profileNameSaved'),
      // The field's own key when the validator produced one (too long,
      // control characters) so the message names the actual problem; a
      // storage error has no field and falls back to the generic text.
      onErr: (failure) => switch (failure) {
        ValidationFailure(:final fieldErrors) => strings(
          fieldErrors['displayName'] ?? 'failureValidation',
        ),
        _ => strings('settingsSaveFailed'),
      },
    );
    if (result.isSuccess) {
      AppFeedback.confirm(
        context,
        message: message,
        duration: const Duration(seconds: 3),
      );
    } else {
      AppFeedback.failure(
        context,
        message: message,
        duration: const Duration(seconds: 3),
      );
    }
  }
}

/// A row with a leading glyph, a label and a trailing value.
///
/// Local to this feature: the settings equivalent carries sheet/segmented
/// behaviour this page does not need, and sharing it would mean exporting a
/// widget whose only two call sites want different halves of it.
///
/// Extracted from `profile_page.dart` (`docs/Conventions.md` §1).
class TappableRow extends StatelessWidget {
  /// Creates a [TappableRow].
  const TappableRow({
    required this.onTap,
    required this.leading,
    required this.label,
    required this.value,
    required this.valueColor,
    super.key,
  });

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// The leading glyph.
  final Widget leading;

  /// The row label.
  final String label;

  /// The trailing value.
  final String value;

  /// The value color.
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return InkWell(
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
              leading,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: colors.textPrimary),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Flexible, not Expanded: a 40-character name in a wide font is
              // wider than the row and must ellipsise rather than overflow.
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: valueColor),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(AppIcons.chevronRight, size: 20, color: colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
