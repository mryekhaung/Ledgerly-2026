import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/features/auth/presentation/providers/auth_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:material_ui/material_ui.dart';

/// Sign In and Sign Up page for email and social authentication.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    final notifier = ref.read(authNotifierProvider.notifier);
    final success = _isSignUp
        ? await notifier.signUpWithEmail(
            email: email,
            password: password,
            displayName: name.isEmpty ? null : name,
          )
        : await notifier.signInWithEmail(email: email, password: password);

    if (!mounted) return;

    if (success) {
      if (GoRouter.maybeOf(context) != null) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.calendar);
        }
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      final failure = ref.read(authNotifierProvider).failure;
      AppFeedback.failure(
        context,
        message: failure?.message ?? 'Authentication failed',
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    final success = await ref
        .read(authNotifierProvider.notifier)
        .signInWithGoogle();
    if (!mounted) return;
    if (success) {
      if (GoRouter.maybeOf(context) != null) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.calendar);
        }
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _signInWithApple() async {
    final success = await ref
        .read(authNotifierProvider.notifier)
        .signInWithApple();
    if (!mounted) return;
    if (success) {
      if (GoRouter.maybeOf(context) != null) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.calendar);
        }
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSignUp ? strings('signUpTitle') : strings('signInTitle'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedPane(
            maxWidth: AppSpacing.proseMaxWidth,
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal(
                  MediaQuery.sizeOf(context).width,
                ),
                vertical: AppSpacing.lg,
              ),
              children: <Widget>[
                Text(
                  _isSignUp ? strings('signUpTitle') : strings('signInTitle'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (_isSignUp) ...<Widget>[
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: strings('displayNameLabel'),
                            prefixIcon: const Icon(Icons.person_outline),
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
                          prefixIcon: const Icon(Icons.email_outlined),
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
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
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

                      if (authState.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else ...<Widget>[
                        FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.brandPrimary,
                            foregroundColor: colors.textOnBrand,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isSignUp
                                ? strings('signUpTitle')
                                : strings('signInTitle'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                            });
                          },
                          child: Text(
                            _isSignUp
                                ? strings('haveAccountPrompt')
                                : strings('noAccountPrompt'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: <Widget>[
                    Expanded(child: Divider(color: colors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        'OR',
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
                  onPressed: authState.isLoading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.borderStrong),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
                  label: Text(strings('signInWithGoogle')),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: authState.isLoading ? null : _signInWithApple,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.borderStrong),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.apple_rounded, size: 22),
                  label: Text(strings('signInWithApple')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
