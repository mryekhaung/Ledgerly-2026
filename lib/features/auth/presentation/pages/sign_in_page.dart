import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/auth/presentation/providers/auth_providers.dart';
import 'package:ledgerly/features/auth/presentation/widgets/sign_in/email_form.dart';
import 'package:ledgerly/features/auth/presentation/widgets/sign_in/header.dart';
import 'package:ledgerly/features/auth/presentation/widgets/sign_in/provider_buttons.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Email + provider sign-in page.
///
/// Composition root only: header, form and provider buttons live in
/// `widgets/sign_in/` (`docs/Conventions.md` §1).
class SignInPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  bool _isSignUp = false;

  Future<void> _submitEmail(String email, String password, String name) async {
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
      _goHome();
    } else {
      final failure = ref.read(authNotifierProvider).failure;
      AppFeedback.failure(
        context,
        message:
            failure?.message ?? AppStrings.of(context)('authErrorSignInFailed'),
      );
    }
  }

  void _goHome() {
    if (GoRouter.maybeOf(context) != null) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.calendar);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final success = await ref
        .read(authNotifierProvider.notifier)
        .signInWithGoogle();
    if (!mounted) return;
    if (success) _goHome();
  }

  Future<void> _signInWithApple() async {
    final success = await ref
        .read(authNotifierProvider.notifier)
        .signInWithApple();
    if (!mounted) return;
    if (success) _goHome();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final authState = ref.watch(authNotifierProvider);

    return AppScaffold(
      title: _isSignUp ? strings('signUpTitle') : strings('signInTitle'),
      useSafeArea: false,
      // Declared on the scaffold so the title lines up with the column it caps
      // (`AppScaffold.contentMaxWidth`). The extra `Center` this used to carry
      // was redundant: the scaffold's own column already centres the body.
      contentMaxWidth: AppSpacing.proseMaxWidth,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal(
              MediaQuery.sizeOf(context).width,
            ),
            vertical: AppSpacing.lg,
          ),
          children: <Widget>[
            SignInHeader(isSignUp: _isSignUp),
            SignInEmailForm(
              isSignUp: _isSignUp,
              isLoading: authState.isLoading,
              onSubmit: _submitEmail,
              onToggleMode: () {
                setState(() {
                  _isSignUp = !_isSignUp;
                });
              },
            ),
            ProviderButtons(
              isLoading: authState.isLoading,
              onGoogle: _signInWithGoogle,
              onApple: _signInWithApple,
            ),
          ],
        ),
      ),
    );
  }
}
