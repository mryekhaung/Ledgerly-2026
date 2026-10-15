import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:material_ui/material_ui.dart';

/// Title + subtitle header.
///
/// Extracted from `sign_in_page.dart` (`docs/Conventions.md` §1).
class SignInHeader extends StatelessWidget {
  /// Creates a [SignInHeader].
  const SignInHeader({required this.isSignUp, super.key});

  /// Whether the form is in create-account mode.
  final bool isSignUp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          isSignUp ? strings('signUpTitle') : strings('signInTitle'),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          strings('welcomeSubtitle'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
