import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/features/auth/presentation/providers/auth_providers.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';
import 'package:ledgerly/features/profile/domain/usecases/save_display_name.dart';
import 'package:ledgerly/features/profile/presentation/providers/profile_providers.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar.dart';
import 'package:material_ui/material_ui.dart';

/// The profile: name and avatar, without an account.
///
/// Phase 1 is local-only — there is no sign-in. The page therefore shows a
/// **guest** badge rather than an empty avatar row, so "not signed in" reads as
/// the current state of the product (docs/Roadmap.md Phase 2 adds auth) instead
/// of as a missing feature or a broken screen.
///
/// Nothing here holds a copy of the profile: the name and avatar come from
/// [currentUserProfileProvider], which is fed by the Drift stream, so a rename or
/// a shuffle repaints this page and the editor alike with no manual sync
/// (`docs/Architecture.md` §5).
class ProfilePage extends ConsumerWidget {
  /// Creates the page.
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final profile = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings('profileTitle'))),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal(
            MediaQuery.sizeOf(context).width,
          ),
          vertical: AppSpacing.lg,
        ),
        children: <Widget>[
          _IdentityCard(profile: profile),
          const SizedBox(height: AppSpacing.lg),
          _ProfileGroup(
            children: <Widget>[
              _AvatarRow(profile: profile),
              const _GroupDivider(),
              _NameRow(profile: profile),
              const _GroupDivider(),
              _TappableRow(
                onTap: () => context.pushNamed(AppRoutes.accountName),
                leading: Icon(
                  Icons.manage_accounts_outlined,
                  size: 24,
                  color: AppThemeColors.of(context).textTertiary,
                ),
                label: strings('accountTitle'),
                value: ref.watch(isGuestProvider)
                    ? strings('accountGuestBadge')
                    : (ref.watch(currentUserProvider)?.email ??
                          strings('accountLinkedBadge')),
                valueColor: AppThemeColors.of(context).brandPrimary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

/// The avatar, the display name and the guest badge.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);

    return Column(
      children: <Widget>[
        Avatar(
          config: profile.avatar,
          size: 96,
          semanticLabel: strings('profileAvatarLabel'),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          profile.hasName
              ? profile.displayName
              : strings('profileNamePlaceholder'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: profile.hasName ? colors.textPrimary : colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _GuestBadge(),
        const SizedBox(height: AppSpacing.md),
        Text(
          strings('profileSignedOutBody'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

/// A small capsule reading "Guest".
///
/// Deliberately not a button: signing in does not exist yet, and a disabled
/// button is a promise the build cannot keep. Phase 2 turns this into the real
/// entry point.
class _GuestBadge extends StatelessWidget {
  const _GuestBadge();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.brandSubtle,
        borderRadius: AppRadius.borderFull,
      ),
      child: Text(
        strings('profileGuestBadge'),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.brandPrimary,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A group of rows with the standard raised-card treatment.
///
/// Matches `SettingsPage`'s group deliberately: the two pages sit next to each
/// other in the back stack and a different card treatment between them would read
/// as two design languages.
class _ProfileGroup extends StatelessWidget {
  const _ProfileGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.border),
        boxShadow: AppElevation.raised(colors),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// A hairline between rows inside a group.
class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    indent: AppSpacing.lg,
    color: AppThemeColors.of(context).border,
  );
}

/// The avatar row — tap to open the editor.
class _AvatarRow extends StatelessWidget {
  const _AvatarRow({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);

    return _TappableRow(
      onTap: () => context.pushNamed(AppRoutes.avatarEditorName),
      leading: Avatar(config: profile.avatar, size: 40),
      label: strings('profileAvatarLabel'),
      value: strings('profileEditAvatar'),
      valueColor: colors.brandPrimary,
    );
  }
}

/// The display-name row — tap to open the rename dialog.
class _NameRow extends ConsumerWidget {
  const _NameRow({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);

    return _TappableRow(
      onTap: () => _rename(context, ref),
      leading: Icon(Icons.badge_outlined, size: 24, color: colors.textTertiary),
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

    final entered = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _RenameDialog(initial: current),
    );

    // Null is "cancelled"; an unchanged value is a no-op the user did not ask
    // for, so neither reaches the use case.
    if (entered == null || entered.trim() == current) return;

    final result = await ref.read(saveDisplayNameActionProvider)((
      displayName: entered,
    ));

    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.fold(
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
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// The rename dialog: one field, validated on submit by the use case.
///
/// The dialog itself does not validate — [SaveDisplayName] owns the rules, and
/// duplicating them here is how the two drift apart. It only enforces the length
/// cap on the field so the user cannot type past it.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return AlertDialog(
      title: Text(strings('profileEditName')),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: SaveDisplayName.maxLength,
        textInputAction: TextInputAction.done,
        // Submits on Enter, so a keyboard user never has to reach for the button.
        onSubmitted: (value) => Navigator.of(context).pop(value),
        decoration: InputDecoration(
          labelText: strings('profileNameLabel'),
          hintText: strings('profileNameHint'),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings('actionCancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(strings('actionSave')),
        ),
      ],
    );
  }
}

/// A row with a leading glyph, a label and a trailing value.
///
/// Local to this feature: `SettingsPage`'s equivalent carries sheet/segmented
/// behaviour this page does not need, and sharing it would mean exporting a
/// widget whose only two call sites want different halves of it.
class _TappableRow extends StatelessWidget {
  const _TappableRow({
    required this.onTap,
    required this.leading,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final VoidCallback onTap;
  final Widget leading;
  final String label;
  final String value;
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
              Icon(Icons.chevron_right, size: 20, color: colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
