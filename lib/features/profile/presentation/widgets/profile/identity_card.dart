import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/profile/domain/entities/user_profile.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar.dart';
import 'package:material_ui/material_ui.dart';

/// The avatar, the display name and the guest badge.
///
/// Extracted from `profile_page.dart` (`docs/Conventions.md` §1).
class IdentityCard extends StatelessWidget {
  /// Creates an [IdentityCard].
  const IdentityCard({required this.profile, super.key});

  /// The profile to render.
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
        const GuestBadge(),
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
///
/// Extracted from `profile_page.dart` (`docs/Conventions.md` §1).
class GuestBadge extends StatelessWidget {
  /// Creates a [GuestBadge].
  const GuestBadge({super.key});

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
          // `onBrandSubtle` on the `brandSubtle` badge — `brandPrimary` on that
          // fill fails AA at 3.90:1 light (Roadmap §K.1-2).
          color: colors.onBrandSubtle,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
