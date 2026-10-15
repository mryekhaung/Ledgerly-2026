import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_provider_type.dart';
import 'package:material_ui/material_ui.dart';

/// Guest-to-Account Linking Banner (Design.md §6.6 / Roadmap Phase 2).
///
/// Extracted from `account_page.dart` (`docs/Conventions.md` §1).
class AccountLinkingBanner extends StatelessWidget {
  /// Creates an [AccountLinkingBanner].
  const AccountLinkingBanner({
    required this.isLoading,
    required this.onLink,
    super.key,
  });

  /// Whether an auth request is in flight.
  final bool isLoading;

  /// Called with the chosen provider.
  final ValueChanged<AuthProviderType> onLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.brandPrimary.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(AppIcons.cloudSync, size: 24, color: colors.brandPrimary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  strings('accountLinkBannerTitle'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            strings('accountLinkBannerBody'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: isLoading ? null : () => onLink(AuthProviderType.google),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              minimumSize: const Size.fromHeight(44),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.borderMd,
              ),
            ),
            icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
            label: Text(strings('accountLinkGoogle')),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: isLoading ? null : () => onLink(AuthProviderType.apple),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              minimumSize: const Size.fromHeight(44),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.borderMd,
              ),
            ),
            icon: const Icon(Icons.apple_rounded, size: 22),
            label: Text(strings('accountLinkApple')),
          ),
        ],
      ),
    );
  }
}
