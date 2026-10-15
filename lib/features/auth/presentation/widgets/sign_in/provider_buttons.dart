import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:material_ui/material_ui.dart';

/// Divider + Google / Apple provider buttons.
///
/// Extracted from `sign_in_page.dart` (`docs/Conventions.md` §1).
class ProviderButtons extends StatelessWidget {
  /// Creates a [ProviderButtons].
  const ProviderButtons({
    required this.isLoading,
    required this.onGoogle,
    required this.onApple,
    super.key,
  });

  /// Whether an auth request is in flight.
  final bool isLoading;

  /// Sign in with Google.
  final VoidCallback onGoogle;

  /// Sign in with Apple.
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: <Widget>[
            Expanded(child: Divider(color: colors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                strings('signInOrDivider'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            Expanded(child: Divider(color: colors.border)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        OutlinedButton.icon(
          onPressed: isLoading ? null : onGoogle,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.textPrimary,
            side: BorderSide(color: colors.borderStrong),
            minimumSize: const Size.fromHeight(48),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.borderMd,
            ),
          ),
          icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
          label: Text(strings('signInWithGoogle')),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onApple,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.textPrimary,
            side: BorderSide(color: colors.borderStrong),
            minimumSize: const Size.fromHeight(48),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.borderMd,
            ),
          ),
          icon: const Icon(Icons.apple_rounded, size: 22),
          label: Text(strings('signInWithApple')),
        ),
      ],
    );
  }
}
