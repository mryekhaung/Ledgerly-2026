import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/period/period_calculator.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/auth/presentation/providers/auth_providers.dart';
import 'package:ledgerly/features/auth/presentation/widgets/welcome/auth_buttons.dart';
import 'package:ledgerly/features/auth/presentation/widgets/welcome/hero_header.dart';
import 'package:ledgerly/features/auth/presentation/widgets/welcome/month_start_question.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:material_ui/material_ui.dart';

/// The onboarding and welcome page (Phase 2, docs/Design.md §6.6).
///
/// Introduces Ledgerly, lets the user pick their pay-cycle start day (default: 1),
/// and offers guest mode, Sign in with Apple, Google, or Email.
///
/// Composition root only: hero, question and buttons live in `widgets/welcome/`
/// (`docs/Conventions.md` §1).
class WelcomePage extends ConsumerStatefulWidget {
  /// Creates the page.
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  int _selectedDay = 1;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(currentSettingsProvider);
    _selectedDay = settings.monthStartDay;
  }

  Future<void> _persistMonthStartDay() async {
    final settings = ref.read(currentSettingsProvider);
    if (settings.monthStartDay != _selectedDay) {
      await ref.read(saveSettingsActionProvider).call((
        settings: settings.copyWith(monthStartDay: _selectedDay),
        partial: false,
      ));
    }
  }

  Future<void> _continueAsGuest() async {
    await _persistMonthStartDay();
    final success = await ref
        .read(authNotifierProvider.notifier)
        .signInAnonymously();
    if (!mounted) return;
    if (success) {
      if (GoRouter.maybeOf(context) != null) {
        context.go(AppRoutes.calendar);
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      final failure = ref.read(authNotifierProvider).failure;
      AppFeedback.failure(
        context,
        message:
            failure?.message ?? AppStrings.of(context)('authErrorSignInFailed'),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    await _persistMonthStartDay();
    final success = await ref
        .read(authNotifierProvider.notifier)
        .signInWithGoogle();
    if (!mounted) return;
    if (success) {
      if (GoRouter.maybeOf(context) != null) {
        context.go(AppRoutes.calendar);
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      final failure = ref.read(authNotifierProvider).failure;
      AppFeedback.failure(
        context,
        message:
            failure?.message ?? AppStrings.of(context)('authErrorSignInFailed'),
      );
    }
  }

  Future<void> _signInWithApple() async {
    await _persistMonthStartDay();
    final success = await ref
        .read(authNotifierProvider.notifier)
        .signInWithApple();
    if (!mounted) return;
    if (success) {
      if (GoRouter.maybeOf(context) != null) {
        context.go(AppRoutes.calendar);
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      final failure = ref.read(authNotifierProvider).failure;
      AppFeedback.failure(
        context,
        message:
            failure?.message ?? AppStrings.of(context)('authErrorSignInFailed'),
      );
    }
  }

  Future<void> _skip() async {
    await _continueAsGuest();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final authState = ref.watch(authNotifierProvider);

    final calculator = PeriodCalculator(_selectedDay);
    final today = LocalDate.fromDateTime(DateTime.now());
    final currentPeriod = calculator.containing(today);
    final locale = Localizations.localeOf(context);
    final periodStr = _formatPeriod(currentPeriod, locale);

    return AppScaffold(
      actions: <Widget>[
        TextButton(
          onPressed: authState.isLoading ? null : _skip,
          child: Text(
            strings('welcomeSkip'),
            style: AppTypography.body.copyWith(
              color: AppThemeColors.of(context).textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
      useSafeArea: false,
      body: SafeArea(
        child: Center(
          child: ConstrainedPane(
            maxWidth: AppSpacing.proseMaxWidth,
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal(
                  MediaQuery.sizeOf(context).width,
                ),
                vertical: AppSpacing.md,
              ),
              children: <Widget>[
                // App Hero Icon & Title
                const HeroHeader(),

                // First-Run Question: Month start day (Design.md §6.6)
                MonthStartQuestion(
                  selectedDay: _selectedDay,
                  onSelect: (day) {
                    setState(() {
                      _selectedDay = day;
                    });
                    AppFeedback.selection();
                  },
                  periodPreview: periodStr,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Auth Action Buttons
                AuthButtons(
                  isLoading: authState.isLoading,
                  onGuest: _continueAsGuest,
                  onGoogle: _signInWithGoogle,
                  onApple: _signInWithApple,
                  onEmail: () async {
                    await _persistMonthStartDay();
                    if (context.mounted) {
                      await context.pushNamed(AppRoutes.signInName);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatPeriod(BudgetPeriod period, Locale locale) {
    final startDt = period.start.toDateTime();
    final endDt = period.end.toDateTime();
    final localeStr = locale.toLanguageTag();
    if (period.start.year != period.end.year) {
      final startYear = DateFormat.yMMMd(localeStr).format(startDt);
      final endYear = DateFormat.yMMMd(localeStr).format(endDt);
      return '$startYear – $endYear';
    }
    final startFmt = DateFormat.MMMd(localeStr).format(startDt);
    final endFmt = DateFormat.MMMd(localeStr).format(endDt);
    return '$startFmt – $endFmt';
  }
}
