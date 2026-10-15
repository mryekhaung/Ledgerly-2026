import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/auth/presentation/providers/auth_providers.dart';
import 'package:ledgerly/features/profile/presentation/providers/profile_providers.dart';
import 'package:ledgerly/features/profile/presentation/widgets/avatar.dart';
import 'package:ledgerly/features/settings/presentation/widgets/nav_row.dart';
import 'package:ledgerly/features/settings/presentation/widgets/settings_group.dart';
import 'package:material_ui/material_ui.dart';

/// Account, profile, data-transfer, version and credits rows.
///
/// Extracted from `settings_page.dart` (`docs/Conventions.md` §1).
class AboutSection extends ConsumerWidget {
  /// Creates an [AboutSection].
  const AboutSection({
    required this.version,
    required this.onCreditsTap,
    super.key,
  });

  /// The app version string.
  final String version;

  /// Called when the credits row is tapped.
  final VoidCallback onCreditsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(label: strings('settingsAboutSection')),
        const SizedBox(height: AppSpacing.sm),
        SettingsGroup(
          children: <Widget>[
            SettingsNavRow(
              label: strings('accountTitle'),
              subtitle: ref.watch(isGuestProvider)
                  ? strings('accountGuestBadge')
                  : (ref.watch(currentUserProvider)?.email ??
                        strings('accountLinkedBadge')),
              leading: const Icon(AppIcons.manageAccount),
              onTap: () => context.pushNamed(AppRoutes.accountName),
            ),
            const GroupDivider(),
            SettingsNavRow(
              label: strings('profileTitle'),
              leading: Avatar(
                config: ref.watch(currentAvatarProvider),
                size: 32,
              ),
              onTap: () => context.pushNamed(AppRoutes.profileName),
            ),
            const GroupDivider(),
            SettingsNavRow(
              label: strings('settingsDataTransfer'),
              subtitle: strings('settingsDataTransferSubtitle'),
              leading: const Icon(AppIcons.syncAlt),
              onTap: () => context.pushNamed(AppRoutes.dataTransferName),
            ),
            const GroupDivider(),
            SettingsInfoRow(
              label: strings('settingsVersionLabel'),
              value: version,
            ),
            const GroupDivider(),
            SettingsNavRow(
              label: strings('settingsCreditsTitle'),
              subtitle: strings('settingsCreditsAvatar'),
              onTap: onCreditsTap,
            ),
          ],
        ),
      ],
    );
  }
}
