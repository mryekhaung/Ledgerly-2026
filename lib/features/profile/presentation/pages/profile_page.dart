import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/auth/presentation/providers/auth_providers.dart';
import 'package:ledgerly/features/profile/presentation/providers/profile_providers.dart';
import 'package:ledgerly/features/profile/presentation/widgets/profile/identity_card.dart';
import 'package:ledgerly/features/profile/presentation/widgets/profile/profile_group.dart';
import 'package:ledgerly/features/profile/presentation/widgets/profile/profile_rows.dart';
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
///
/// Composition root only: card, group and rows live in `widgets/profile/`
/// (`docs/Conventions.md` §1).
class ProfilePage extends ConsumerWidget {
  /// Creates the page.
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final profile = ref.watch(currentUserProfileProvider);

    return AppScaffold(
      title: strings('profileTitle'),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal(
            MediaQuery.sizeOf(context).width,
          ),
          vertical: AppSpacing.lg,
        ),
        children: <Widget>[
          IdentityCard(profile: profile),
          const SizedBox(height: AppSpacing.lg),
          ProfileGroup(
            children: <Widget>[
              AvatarRow(profile: profile),
              const ProfileGroupDivider(),
              NameRow(profile: profile),
              const ProfileGroupDivider(),
              TappableRow(
                onTap: () => context.pushNamed(AppRoutes.accountName),
                leading: Icon(
                  AppIcons.manageAccount,
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
