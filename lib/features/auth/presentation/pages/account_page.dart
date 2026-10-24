import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_dialog.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/auth/domain/entities/auth_provider_type.dart';
import 'package:ledgerly/features/auth/presentation/providers/auth_providers.dart';
import 'package:ledgerly/features/auth/presentation/widgets/account/actions_card.dart';
import 'package:ledgerly/features/auth/presentation/widgets/account/identity_card.dart';
import 'package:ledgerly/features/auth/presentation/widgets/account/linking_banner.dart';
import 'package:ledgerly/features/profile/presentation/providers/profile_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Account management page (Phase 2, docs/Roadmap.md).
///
/// Surfaces identity status (Guest vs Synced), guest-to-account linking,
/// sign out, and store-compliant account deletion.
///
/// Composition root only: card, banner and actions live in `widgets/account/`
/// (`docs/Conventions.md` §1).
class AccountPage extends ConsumerWidget {
  /// Creates the page.
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
      AppFeedback.confirm(
        context,
        message: AppStrings.of(context)('accountLinkSuccess'),
      );
    } else {
      final failure = ref.read(authNotifierProvider).failure;
      AppFeedback.failure(
        context,
        message:
            failure?.message ?? AppStrings.of(context)('accountLinkFailed'),
      );
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final strings = AppStrings.of(context);
    final confirmed = await AppDialog.confirm(
      context: context,
      title: strings('accountSignOut'),
      message: strings('accountSignOutConfirm'),
      confirmLabel: strings('accountSignOut'),
      cancelLabel: strings('actionCancel'),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref.read(authNotifierProvider.notifier).signOut();
    if (!context.mounted) return;
    if (success) {
      if (GoRouter.maybeOf(context) != null) context.go(AppRoutes.welcome);
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final strings = AppStrings.of(context);
    final confirmed = await AppDialog.confirm(
      context: context,
      title: strings('accountDeleteTitle'),
      message: strings('accountDeleteBody'),
      confirmLabel: strings('accountDeleteConfirm'),
      cancelLabel: strings('actionCancel'),
      isDestructive: true,
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref
        .read(authNotifierProvider.notifier)
        .deleteAccount();
    if (!context.mounted) return;
    if (success) {
      AppFeedback.destructive();
      AppFeedback.confirm(context, message: strings('accountDeletedSuccess'));
      if (GoRouter.maybeOf(context) != null) context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isGuest = authState.isGuest;
    final avatarConfig = ref.watch(currentAvatarProvider);

    return AppScaffold(
      title: strings('accountTitle'),
      // The column is declared on the scaffold so the title lines up with it
      // (`AppScaffold.contentMaxWidth`); capping the body here instead would
      // make the cap a second owner of the column and let it drift from the
      // title's inset.
      contentMaxWidth: AppSpacing.proseMaxWidth,
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal(
            MediaQuery.sizeOf(context).width,
          ),
          vertical: AppSpacing.lg,
        ),
        children: <Widget>[
          // Identity Card
          AccountIdentityCard(
            user: user,
            isGuest: isGuest,
            avatarConfig: avatarConfig,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Guest-to-Account Linking Banner (Design.md §6.6 / Roadmap §Phase 2)
          if (isGuest) ...<Widget>[
            AccountLinkingBanner(
              isLoading: authState.isLoading,
              onLink: (provider) => _linkAccount(context, ref, provider),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Account Actions
          AccountActionsCard(
            isLoading: authState.isLoading,
            onSignOut: () => _signOut(context, ref),
            onDeleteAccount: () => _deleteAccount(context, ref),
          ),
        ],
      ),
    );
  }
}
