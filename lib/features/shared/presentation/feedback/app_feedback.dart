import 'dart:async';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show
        AdaptiveBlurView,
        AdaptiveButton,
        AdaptiveButtonSize,
        AdaptiveButtonStyle,
        AdaptiveSnackBar,
        AdaptiveSnackBarType,
        BlurStyle,
        PlatformInfo;
import 'package:flutter/services.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:material_ui/material_ui.dart';

/// The app's one place for transient feedback: haptics and snack bars.
///
/// Two reasons this is a single module rather than scattered `ScaffoldMessenger`
/// calls:
///
/// * **Consistency.** `docs/Design.md` §5 defines the snack bar as a single
///   treatment. When four pages each build their own, three of them forget
///   `clearSnackBars()` and the user gets a queue of stale confirmations after a
///   quick burst of edits.
/// * **One haptic vocabulary.** `docs/Platform.md` §6 specifies haptics at
///   exactly three strengths, and only the *meaningful* moments get one. If every
///   tap buzzed, the feedback would stop meaning anything — so the mapping from
///   intent to `HapticFeedback` call lives here, not at each call site.
///
/// Every method is safe to call with a `null` messenger or no platform channel:
/// haptics are best-effort and must never be the reason an action fails
/// (`docs/Agent.md` §6 — a missing vibration motor is not an error state).
abstract final class AppFeedback {
  static OverlayEntry? _ios26Entry;
  static Timer? _ios26Timer;

  /// A short, light tap for a state change that is *reversible* — selecting a
  /// segment, toggling a direction, picking a swatch.
  static void selection() => HapticFeedback.selectionClick();

  /// A firmer tap for an action that had a visible effect — saving a record,
  /// archiving a category.
  static void success() => HapticFeedback.lightImpact();

  /// A heavy tap reserved for a **destructive** action, so deleting feels
  /// different from saving before the snack bar is even read.
  static void destructive() => HapticFeedback.mediumImpact();

  /// Shows a confirmation snack bar, replacing any that is already up.
  ///
  /// `action` renders as a trailing text button — the undo affordance. Passing
  /// null shows a plain confirmation.
  static void confirm(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      type: AppPlatform.resolve().usesCupertino
          ? AdaptiveSnackBarType.success
          : AdaptiveSnackBarType.info,
    );
  }

  /// Shows a failure snack bar.
  ///
  /// Longer than a confirmation by default: a message the user has to *read* and
  /// possibly act on should not vanish in two seconds, and a retry action makes
  /// the extra time useful rather than annoying.
  static void failure(
    BuildContext context, {
    required String message,
    String? retryLabel,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message,
      duration: duration,
      actionLabel: retryLabel,
      onAction: onRetry,
      type: AppPlatform.resolve().usesCupertino
          ? AdaptiveSnackBarType.error
          : AdaptiveSnackBarType.info,
    );
  }

  /// Shows an undoable snack bar for a **soft delete**.
  ///
  /// The undo window is 5 seconds rather than 2 because undoing a delete is a
  /// recovery action: the user has to notice the record is gone, decide they
  /// want it back, and reach the button. Two seconds is enough to *read* a
  /// confirmation but not enough to *act* on one.
  static void undoable(
    BuildContext context, {
    required String message,
    required String undoLabel,
    required VoidCallback onUndo,
  }) => _show(
    context,
    message: message,
    duration: const Duration(seconds: 5),
    actionLabel: undoLabel,
    onAction: onUndo,
  );

  static void _show(
    BuildContext context, {
    required String message,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
    AdaptiveSnackBarType type = AdaptiveSnackBarType.info,
  }) {
    // Resolve the messenger *before* any await-free rebuild: calling
    // `ScaffoldMessenger.of` after the frame would just throw, and a feedback
    // helper is the wrong place to make every caller guard `context.mounted`.
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    // Clearing first means a rapid burst of edits shows the *latest* result
    // rather than a queue that lags seconds behind the user.
    messenger.clearSnackBars();
    if (AppPlatform.resolve().usesCupertino && PlatformInfo.isIOS26OrHigher()) {
      _showIOS26(
        context,
        message: message,
        duration: duration,
        actionLabel: actionLabel == null || onAction == null
            ? null
            : actionLabel,
        onAction: onAction,
        type: type,
      );
    } else if (AppPlatform.resolve().usesCupertino) {
      AdaptiveSnackBar.show(
        context,
        message: message,
        type: type,
        duration: duration,
        action: actionLabel == null || onAction == null ? null : actionLabel,
        onActionPressed: onAction,
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          action: actionLabel == null || onAction == null
              ? null
              : SnackBarAction(label: actionLabel, onPressed: onAction),
        ),
      );
    }
  }

  static void _showIOS26(
    BuildContext context, {
    required String message,
    required Duration duration,
    required AdaptiveSnackBarType type,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _ios26Timer?.cancel();
    _ios26Entry?.remove();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _IOS26FeedbackBanner(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () => _dismissIOS26(entry),
      ),
    );
    _ios26Entry = entry;
    Overlay.of(context).insert(entry);
    _ios26Timer = Timer(duration, () => _dismissIOS26(entry));
  }

  static void _dismissIOS26(OverlayEntry entry) {
    if (!identical(_ios26Entry, entry)) return;
    _ios26Timer?.cancel();
    _ios26Timer = null;
    _ios26Entry = null;
    entry.remove();
  }
}

class _IOS26FeedbackBanner extends StatelessWidget {
  const _IOS26FeedbackBanner({
    required this.message,
    required this.type,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AdaptiveSnackBarType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final iconColor = switch (type) {
      AdaptiveSnackBarType.info => colors.brandPrimary,
      AdaptiveSnackBarType.success => colors.moneyIn,
      AdaptiveSnackBarType.warning => colors.warning,
      AdaptiveSnackBarType.error => colors.moneyOut,
    };

    final icon = switch (type) {
      AdaptiveSnackBarType.info => AppIcons.info,
      AdaptiveSnackBarType.success => AppIcons.success,
      AdaptiveSnackBarType.warning => AppIcons.warning,
      AdaptiveSnackBarType.error => AppIcons.error,
    };

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.borderLg,
            child: AdaptiveBlurView(
              blurStyle: BlurStyle.systemUltraThinMaterial,
              borderRadius: AppRadius.borderLg,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.borderLg,
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.35),
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(icon, color: iconColor),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          message,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.textPrimary),
                        ),
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...<Widget>[
                      const SizedBox(width: AppSpacing.xs),
                      AdaptiveButton(
                        onPressed: () {
                          onAction!();
                          onDismiss();
                        },
                        label: actionLabel!,
                        textColor: colors.brandPrimary,
                        style: AdaptiveButtonStyle.plain,
                        size: AdaptiveButtonSize.small,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reads the localized "Undo" label, for the [AppFeedback.undoable] call sites.
///
/// A tiny helper rather than inlining `AppStrings.of(context)('transactionUndo')`
/// at each call site so the key is named once and a rename breaks in one place.
String undoLabelFor(BuildContext context) =>
    AppStrings.of(context)('transactionUndo');
