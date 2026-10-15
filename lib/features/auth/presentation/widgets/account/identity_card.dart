import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_user.dart';
import 'package:ledgerly/features/profile/domain/entities/avatar_config.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar.dart';
import 'package:material_ui/material_ui.dart';

/// The identity card: avatar, display name and guest/synced badge.
///
/// Extracted from `account_page.dart` (`docs/Conventions.md` §1).
class AccountIdentityCard extends StatelessWidget {
  /// Creates an [AccountIdentityCard].
  const AccountIdentityCard({
    required this.user,
    required this.isGuest,
    required this.avatarConfig,
    super.key,
  });

  /// The signed-in user, if any.
  final AuthUser? user;

  /// Whether the session is a guest session.
  final bool isGuest;

  /// The avatar configuration.
  final AvatarConfig avatarConfig;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: <Widget>[
          Avatar(config: avatarConfig, size: 72),
          const SizedBox(height: AppSpacing.md),
          Text(
            user?.displayName ??
                (isGuest
                    ? strings('accountGuestName')
                    : strings('accountUserFallback')),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          if (user?.email != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              user!.email!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isGuest ? colors.surface : colors.brandSubtle,
              borderRadius: AppRadius.borderLg,
              border: Border.all(
                color: isGuest
                    ? colors.border
                    : colors.brandPrimary.withAlpha(60),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  isGuest ? AppIcons.person : AppIcons.success,
                  size: 14,
                  color: isGuest ? colors.textSecondary : colors.brandPrimary,
                ),
                const SizedBox(width: AppSpacing.xs),
                // "Synced Account" at 2× type (`docs/Design.md` §8) is wider
                // than the card, so the badge label has to yield.
                Flexible(
                  child: Text(
                    isGuest
                        ? strings('accountGuestBadge')
                        : strings('accountLinkedBadge'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isGuest
                          ? colors.textSecondary
                          : colors.brandPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
