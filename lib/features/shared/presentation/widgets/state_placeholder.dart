import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/widgets/app_button.dart';
import 'package:ledgerly/core/widgets/app_skeleton.dart';
import 'package:material_ui/material_ui.dart';

/// A centred empty/loading/error placeholder.
///
/// One widget for the three "nothing to show" states so every page renders them
/// identically — `docs/Design.md` §5 defines them as a single family, and a page
/// that hand-rolls its own is how an app ends up with four different error
/// layouts (`docs/Agent.md` §6: empty/loading/error states).
///
/// Deliberately takes already-localized strings: this widget must not know about
/// ARB keys or which feature is asking.
class StatePlaceholder extends StatelessWidget {
  /// A placeholder with an icon, a heading and supporting body text.
  const StatePlaceholder({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    super.key,
  });

  /// The leading glyph. Rendered in a tinted circle so it reads as intentional
  /// rather than as a broken image.
  final IconData icon;

  /// Short heading. Localized by the caller.
  final String title;

  /// Supporting sentence. Localized by the caller.
  final String body;

  /// Optional call to action — e.g. "New category" on an empty list.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.proseMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              if (action != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A skeleton list for a first-load state (docs/Design.md §5.11).
///
/// §5.11: *"Loading (first paint): skeleton matching final layout
/// (`surfaceSubtle` shimmer), **never a centered spinner**."* So this is not a
/// spinner with a friendlier name — it draws the shape of the rows that are
/// about to arrive, which removes the layout jump the spinner caused.
///
/// It lives here, next to [StatePlaceholder], because the loading/empty/error
/// trio is one family in §5.11 and splitting them across files is how they
/// drift apart.
class LoadingPlaceholder extends StatelessWidget {
  /// Creates a loading placeholder.
  const LoadingPlaceholder({this.rows = 5, super.key});

  /// How many skeleton rows to draw. Pick the count that fills the viewport
  /// for the screen in question so the skeleton does not itself scroll.
  final int rows;

  @override
  Widget build(BuildContext context) => AppSkeletonList(rows: rows);
}

/// An inline error banner with a retry affordance.
///
/// Inline rather than full-screen when it sits above content that is still
/// usable — a failed refresh should not blank a screen that already has rows.
class ErrorBanner extends StatelessWidget {
  /// Creates an error banner.
  const ErrorBanner({
    required this.message,
    this.onRetry,
    this.retryLabel,
    super.key,
  });

  /// Localized error text.
  final String message;

  /// Retry callback. Null hides the button (a non-retryable failure).
  final VoidCallback? onRetry;

  /// Localized retry label.
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.warningSubtle,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: colors.warning),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(AppIcons.error, color: colors.warning, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          if (onRetry case final onRetry?) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              variant: AppButtonVariant.ghost,
              onPressed: onRetry,
              label: retryLabel ?? '',
            ),
          ],
        ],
      ),
    );
  }
}
