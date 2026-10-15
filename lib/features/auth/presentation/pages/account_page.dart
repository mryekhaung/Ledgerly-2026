import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/core/widgets/list_row.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_provider_type.dart';
import 'package:ledgerly/features/auth/presentation/providers/auth_providers.dart';
import 'package:ledgerly/features/profile/presentation/providers/profile_providers.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:material_ui/material_ui.dart';

/// Account management page (Phase 2, docs/Roadmap.md).
///
/// Surfaces identity status (Guest vs Synced), guest-to-account linking,
/// sign out, and store-compliant account deletion.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  Future<void> _linkAccount(
    BuildContext context,
    WidgetRef ref,
    AuthProviderType provider,
  ) async {
    final success = await ref
        .read(authNotifierProvider.notifier)
        .linkAccount(targetProvider: provider);
    if (!context.mounted) return;
    if (success) {
      AppFeedback.selection();
      AppFeedback.confirm(context, message: 'Account successfully linked');
    } else {
      final failure = ref.read(authNotifierProvider).failure;
      AppFeedback.failure(
        context,
        message: failure?.message ?? 'Account linking failed',
      );
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings('accountSignOut')),
        content: Text(strings('accountSignOutConfirm')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings('actionCancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings('accountSignOut')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref.read(authNotifierProvider.notifier).signOut();
    if (!context.mounted) return;
    if (success) {
      if (GoRouter.maybeOf(context) != null) {
        context.go(AppRoutes.welcome);
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings('accountDeleteTitle')),
        content: Text(strings('accountDeleteBody')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings('actionCancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppThemeColors.of(ctx).moneyOut,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings('accountDeleteConfirm')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref
        .read(authNotifierProvider.notifier)
        .deleteAccount();
    if (!context.mounted) return;
    if (success) {
      AppFeedback.destructive();
      AppFeedback.confirm(context, message: strings('accountDeletedSuccess'));
      if (GoRouter.maybeOf(context) != null) {
        context.go(AppRoutes.welcome);
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isGuest = authState.isGuest;
    final avatarConfig = ref.watch(currentAvatarProvider);

    return AppScaffold(
      title: strings('accountTitle'),
      body: ConstrainedPane(
        maxWidth: AppSpacing.proseMaxWidth,
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal(
              MediaQuery.sizeOf(context).width,
            ),
            vertical: AppSpacing.lg,
          ),
          children: <Widget>[
            // Identity Card
            Container(
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
                    user?.displayName ?? (isGuest ? 'Guest User' : 'User'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
                      borderRadius: BorderRadius.circular(20),
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
                          color: isGuest
                              ? colors.textSecondary
                              : colors.brandPrimary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          isGuest
                              ? strings('accountGuestBadge')
                              : strings('accountLinkedBadge'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isGuest
                                ? colors.textSecondary
                                : colors.brandPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Guest-to-Account Linking Banner (Design.md §6.6 / Roadmap §Phase 2)
            if (isGuest) ...<Widget>[
              Container(
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
                        Icon(
                          AppIcons.cloudSync,
                          size: 24,
                          color: colors.brandPrimary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            strings('accountLinkBannerTitle'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
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
                      onPressed: authState.isLoading
                          ? null
                          : () => _linkAccount(
                              context,
                              ref,
                              AuthProviderType.google,
                            ),
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
                      onPressed: authState.isLoading
                          ? null
                          : () => _linkAccount(
                              context,
                              ref,
                              AuthProviderType.apple,
                            ),
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
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Account Actions
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                // `AppRadius.borderMd` rather than a bare `circular(12)`, so the
                // value and the token cannot drift apart (docs/Design.md §4.2).
                borderRadius: AppRadius.borderMd,
                side: BorderSide(color: colors.border),
              ),
              child: Column(
                children: <Widget>[
                  ListRow(
                    leading: Icon(AppIcons.signOut, color: colors.textPrimary),
                    title: Text(
                      strings('accountSignOut'),
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    trailing: const Icon(AppIcons.chevronRight),
                    onTap: authState.isLoading
                        ? null
                        : () => _signOut(context, ref),
                    semanticsLabel: strings('accountSignOut'),
                  ),
                  Divider(height: 1, color: colors.border),
                  ListRow(
                    leading: Icon(AppIcons.destructive, color: colors.moneyOut),
                    title: Text(
                      strings('accountDeleteTitle'),
                      style: AppTypography.body.copyWith(
                        color: colors.moneyOut,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(
                      AppIcons.chevronRight,
                      color: colors.moneyOut,
                    ),
                    onTap: authState.isLoading
                        ? null
                        : () => _deleteAccount(context, ref),
                    semanticsLabel: strings('accountDeleteTitle'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
