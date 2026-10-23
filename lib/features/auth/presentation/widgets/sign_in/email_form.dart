import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_button.dart';
import 'package:ledgerly/core/widgets/app_skeleton.dart';
import 'package:material_ui/material_ui.dart';

/// Email / password (/ name) form with submit and mode toggle.
///
/// Owns its controllers and form key so their lifetimes match the form —
/// controllers built in `build` reset the cursor on every keystroke.
///
/// Extracted from `sign_in_page.dart` (`docs/Conventions.md` §1).
class SignInEmailForm extends StatefulWidget {
  /// Creates a [SignInEmailForm].
  const SignInEmailForm({
    required this.isSignUp,
    required this.isLoading,
    required this.onSubmit,
    required this.onToggleMode,
    super.key,
  });

  /// Whether the form is in create-account mode.
  final bool isSignUp;

  /// Whether an auth request is in flight.
  final bool isLoading;

  /// Called with the trimmed field values on submit.
  final void Function(String email, String password, String name) onSubmit;

  /// Called to flip between sign-in and create-account.
  final VoidCallback onToggleMode;

  @override
  State<SignInEmailForm> createState() => _SignInEmailFormState();
}

class _SignInEmailFormState extends State<SignInEmailForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final usesCupertino = AppPlatform.resolve().usesCupertino;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (widget.isSignUp) ...<Widget>[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: strings('displayNameLabel'),
                prefixIcon: const Icon(AppIcons.person),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: strings('emailLabel'),
              prefixIcon: const Icon(AppIcons.email),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return strings('failureValidation');
              }
              if (!value.contains('@')) {
                return strings('failureValidation');
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: strings('passwordLabel'),
              prefixIcon: const Icon(AppIcons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? AppIcons.reveal : AppIcons.conceal,
                ),
                onPressed: () => setState(() {
                  _obscurePassword = !_obscurePassword;
                }),
              ),
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: (value) {
              if (value == null || value.length < 6) {
                return strings('failureValidation');
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          if (widget.isLoading)
            // A skeleton the size of the button it replaces, so the
            // page does not jump when auth resolves
            // (docs/Design.md §5.11).
            const AppSkeleton(height: 50, radius: AppRadius.md)
          else ...<Widget>[
            if (usesCupertino)
              AppButton(
                isExpanded: true,
                onPressed: _submit,
                label: widget.isSignUp
                    ? strings('signUpTitle')
                    : strings('signInTitle'),
              )
            else
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.brandPrimary,
                  foregroundColor: colors.textOnBrand,
                  minimumSize: const Size.fromHeight(50),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.borderMd,
                  ),
                ),
                child: Text(
                  widget.isSignUp
                      ? strings('signUpTitle')
                      : strings('signInTitle'),
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            if (usesCupertino)
              AppButton(
                variant: AppButtonVariant.ghost,
                onPressed: widget.onToggleMode,
                label: widget.isSignUp
                    ? strings('haveAccountPrompt')
                    : strings('noAccountPrompt'),
                isExpanded: true,
              )
            else
              TextButton(
                onPressed: widget.onToggleMode,
                child: Text(
                  widget.isSignUp
                      ? strings('haveAccountPrompt')
                      : strings('noAccountPrompt'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
