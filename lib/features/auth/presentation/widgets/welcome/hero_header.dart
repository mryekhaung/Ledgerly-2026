import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:material_ui/material_ui.dart';

/// App icon, title and subtitle hero.
///
/// Extracted from `welcome_page.dart` (`docs/Conventions.md` §1).
class HeroHeader extends StatelessWidget {
  /// Creates a [HeroHeader].
  const HeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return Column(
      children: <Widget>[
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.brandSubtle,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: colors.brandPrimary.withAlpha(50)),
            ),
            child: Icon(
              AppIcons.wallet,
              size: 40,
              // `onBrandSubtle`: the icon sits on a `brandSubtle` tile, where
              // `brandPrimary` measured 3.90:1 light (Roadmap §K.1-2).
              color: colors.onBrandSubtle,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          strings('welcomeTitle'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          strings('welcomeSubtitle'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
