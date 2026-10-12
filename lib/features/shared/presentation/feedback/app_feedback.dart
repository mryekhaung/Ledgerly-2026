import 'package:flutter/services.dart';
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
  /// [action] renders as a trailing text button — the undo affordance. Passing
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
  }) {
    _show(
      context,
      message: message,
      duration: const Duration(seconds: 4),
      actionLabel: retryLabel,
      onAction: onRetry,
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
  }) {
    // Resolve the messenger *before* any await-free rebuild: calling
    // `ScaffoldMessenger.of` after the frame would just throw, and a feedback
    // helper is the wrong place to make every caller guard `context.mounted`.
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    // Clearing first means a rapid burst of edits shows the *latest* result
    // rather than a queue that lags seconds behind the user.
    messenger
      ..clearSnackBars()
      ..showSnackBar(
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

/// Reads the localized "Undo" label, for the [AppFeedback.undoable] call sites.
///
/// A tiny helper rather than inlining `AppStrings.of(context)('transactionUndo')`
/// at each call site so the key is named once and a rename breaks in one place.
String undoLabelFor(BuildContext context) =>
    AppStrings.of(context)('transactionUndo');
