import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_skeleton.dart';
import 'package:material_ui/material_ui.dart';

/// Guest / Google / Apple / Email sign-in actions with a loading skeleton.
///
/// Extracted from `welcome_page.dart` (`docs/Conventions.md` §1).
class AuthButtons extends StatelessWidget {
  /// Creates an [AuthButtons].
  const AuthButtons({
    required this.isLoading,
    required this.onGuest,
    required this.onGoogle,
    required this.onApple,
    required this.onEmail,
    super.key,
  });

  /// Whether an auth request is in flight.
  final bool isLoading;

  /// Continue as guest.
  final VoidCallback onGuest;

  /// Sign in with Google.
  final VoidCallback onGoogle;

  /// Sign in with Apple.
  final VoidCallback onApple;

  /// Go to the email sign-in page.
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    if (isLoading) {
      // Skeletons the size of the two buttons they replace, so the
      // layout does not jump when auth resolves
      // (docs/Design.md §5.11).
      return const Column(
        children: <Widget>[
          AppSkeleton(height: 50, radius: AppRadius.md),
          SizedBox(height: AppSpacing.md),
          AppSkeleton(height: 50, radius: AppRadius.md),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FilledButton.icon(
          onPressed: onGuest,
          style: FilledButton.styleFrom(
            backgroundColor: colors.brandPrimary,
            foregroundColor: colors.textOnBrand,
            minimumSize: const Size.fromHeight(50),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.borderMd,
            ),
          ),
          icon: const Icon(AppIcons.person),
          label: Text(
            strings('continueAsGuest'),
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: onGoogle,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.textPrimary,
            side: BorderSide(color: colors.borderStrong),
            minimumSize: const Size.fromHeight(50),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.borderMd,
            ),
          ),
          icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
          label: Text(
            strings('signInWithGoogle'),
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onApple,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.textPrimary,
            side: BorderSide(color: colors.borderStrong),
            minimumSize: const Size.fromHeight(50),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.borderMd,
            ),
          ),
          icon: const Icon(Icons.apple_rounded, size: 24),
          label: Text(
            strings('signInWithApple'),
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: onEmail,
          icon: const Icon(AppIcons.email, size: 20),
          label: Text(strings('signInWithEmail')),
        ),
      ],
    );
  }
}
