import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/period/period_calculator.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/core/widgets/app_skeleton.dart';
import 'package:ledgerly/features/auth/presentation/providers/auth_providers.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/responsive_layout.dart';
import 'package:material_ui/material_ui.dart';

/// The onboarding and welcome page (Phase 2, docs/Design.md §6.6).
///
/// Introduces Ledgerly, lets the user pick their pay-cycle start day (default: 1),
/// and offers guest mode, Sign in with Apple, Google, or Email.
class WelcomePage extends ConsumerStatefulWidget {
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
        message: failure?.message ?? 'Sign in failed. Please try again.',
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
        message: failure?.message ?? 'Google Sign-in failed.',
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
        message: failure?.message ?? 'Apple Sign-in failed.',
      );
    }
  }

  Future<void> _skip() async {
    await _continueAsGuest();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
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
            style: AppTypography.body.copyWith(color: colors.textSecondary),
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
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colors.brandSubtle,
                      borderRadius: AppRadius.borderLg,
                      border: Border.all(
                        color: colors.brandPrimary.withAlpha(50),
                      ),
                    ),
                    child: Icon(
                      AppIcons.wallet,
                      size: 40,
                      color: colors.brandPrimary,
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

                // First-Run Question: Month start day (Design.md §6.6)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle,
                    borderRadius: AppRadius.borderLg,
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            AppIcons.calendar,
                            size: 20,
                            color: colors.brandPrimary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              strings('welcomeMonthStartQuestion'),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        strings('welcomeMonthStartHelp'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Day chips 1–28
                      _DayGridSelector(
                        selectedDay: _selectedDay,
                        onSelect: (day) {
                          setState(() {
                            _selectedDay = day;
                          });
                          AppFeedback.selection();
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Live preview text
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: AppRadius.borderSm,
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              AppIcons.info,
                              size: 16,
                              color: colors.brandPrimary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                AppStrings.fill(
                                  context,
                                  'monthStartsOnCurrentPeriod',
                                  {'range': periodStr},
                                ),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Auth Action Buttons
                if (authState.isLoading)
                  // Skeletons the size of the two buttons they replace, so the
                  // layout does not jump when auth resolves
                  // (docs/Design.md §5.11).
                  const Column(
                    children: <Widget>[
                      AppSkeleton(height: 50, radius: AppRadius.md),
                      SizedBox(height: AppSpacing.md),
                      AppSkeleton(height: 50, radius: AppRadius.md),
                    ],
                  )
                else ...<Widget>[
                  FilledButton.icon(
                    onPressed: _continueAsGuest,
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
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _signInWithGoogle,
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
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _signInWithApple,
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
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: () async {
                      await _persistMonthStartDay();
                      if (context.mounted) {
                        await context.pushNamed(AppRoutes.signInName);
                      }
                    },
                    icon: const Icon(AppIcons.email, size: 20),
                    label: Text(strings('signInWithEmail')),
                  ),
                ],
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

class _DayGridSelector extends StatelessWidget {
  const _DayGridSelector({required this.selectedDay, required this.onSelect});

  final int selectedDay;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 7;
        const totalSpacing = AppSpacing.xs * (columns - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / columns;
        final chipSize = itemWidth < 38 ? 38.0 : itemWidth;

        return Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (var day = 1; day <= 28; day++)
              _SelectorDayChip(
                day: day,
                isSelected: day == selectedDay,
                size: chipSize,
                colors: colors,
                theme: theme,
                onTap: () => onSelect(day),
              ),
          ],
        );
      },
    );
  }
}

class _SelectorDayChip extends StatelessWidget {
  const _SelectorDayChip({
    required this.day,
    required this.isSelected,
    required this.size,
    required this.colors,
    required this.theme,
    required this.onTap,
  });

  final int day;
  final bool isSelected;
  final double size;
  final AppColors colors;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? colors.brandPrimary : colors.surface;
    final fg = isSelected ? colors.textOnBrand : colors.textPrimary;
    final border = isSelected ? colors.brandPrimary : colors.border;

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Day $day',
      child: Material(
        color: bg,
        borderRadius: AppRadius.borderSm,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderSm,
          child: Container(
            width: size,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: border),
            ),
            child: Text(
              '$day',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
