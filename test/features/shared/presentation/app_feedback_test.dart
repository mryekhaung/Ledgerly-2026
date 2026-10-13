import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/l10n/app_localization.dart';
import 'package:ledgerly/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_test_host.dart';

/// Fires every feedback entry point from a context with no `ScaffoldMessenger`,
/// then renders nothing.
///
/// Top-level (not an inline closure) so it can be `const` and so the `no
/// messenger` test reads as one idea: call them all, expect no throw.
Widget _noMessengerProbe(BuildContext context) {
  AppFeedback.confirm(context, message: 'Saved');
  AppFeedback.failure(context, message: 'Failed');
  AppFeedback.undoable(
    context,
    message: 'Deleted',
    undoLabel: 'Undo',
    onUndo: () {},
  );
  return const SizedBox.shrink();
}

/// The shared feedback layer.
///
/// Two things are worth asserting here rather than at each call site:
///
/// * **Replace, don't queue.** A burst of edits must show the latest result. If
///   `clearSnackBars` is dropped the user reads stale confirmations for seconds
///   after the last action.
/// * **The undo window is longer than a plain confirmation.** Undo is a
///   *recovery* action: the user must notice the record is gone, decide they
///   want it, then reach the button — so a 2-second window would make the
///   affordance decorative.
void main() {
  /// Hosts a button that fires [onTap] inside a real `Scaffold`, so
  /// `ScaffoldMessenger` resolves exactly as it does in the app.
  Widget host(void Function(BuildContext context) onTap) {
    return MaterialApp(
      theme: AppTheme.light(),
      supportedLocales: AppLocalization.supportedLocales
          .map(Locale.new)
          .toList(growable: false),
      localizationsDelegates: const <LocalizationsDelegate<Object?>>[
        ...GlobalMaterialLocalizations.delegates,
        AppLocalizations.delegate,
      ],
      builder: (context, child) => AppTestScopes(
        child: Scaffold(body: child ?? const SizedBox.shrink()),
      ),
      home: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => onTap(context),
            child: const Text('fire'),
          ),
        ),
      ),
    );
  }

  group('confirm', () {
    testWidgets('should_show_the_message', (tester) async {
      await tester.pumpWidget(
        host((context) => AppFeedback.confirm(context, message: 'Saved')),
      );

      await tester.tap(find.text('fire'));
      await tester.pump();

      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('should_replace_a_visible_snack_bar_rather_than_queue', (
      tester,
    ) async {
      var count = 0;
      await tester.pumpWidget(
        host((context) => AppFeedback.confirm(context, message: 'n${++count}')),
      );

      await tester.tap(find.text('fire'));
      await tester.pump();
      expect(find.text('n1'), findsOneWidget);

      // A second action while the first is still on screen.
      await tester.tap(find.text('fire'));
      await tester.pump();

      // Exactly one bar is visible, and it is the newer one.
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('n2'), findsOneWidget);
      expect(find.text('n1'), findsNothing);
    });

    testWidgets('should_show_a_trailing_action_when_given_a_label', (
      tester,
    ) async {
      var undone = false;
      await tester.pumpWidget(
        host(
          (context) => AppFeedback.confirm(
            context,
            message: 'Deleted',
            actionLabel: 'Undo',
            onAction: () => undone = true,
          ),
        ),
      );

      await tester.tap(find.text('fire'));
      // Settle, not a single pump: the bar animates in and its action is behind
      // an `IgnorePointer` until that finishes, so an immediate tap is reported
      // as a miss and the callback never fires.
      await tester.pumpAndSettle();

      await tester.tap(find.text('Undo'));
      await tester.pump();

      expect(undone, isTrue);
    });

    testWidgets('should_hide_the_action_when_only_one_half_is_given', (
      tester,
    ) async {
      // A label with no callback (or vice versa) would render a dead button, so
      // the pair is required and a half-supplied one shows nothing.
      await tester.pumpWidget(
        host(
          (context) =>
              AppFeedback.confirm(context, message: 'Saved', actionLabel: 'Ok'),
        ),
      );

      await tester.tap(find.text('fire'));
      await tester.pump();

      expect(find.text('Saved'), findsOneWidget);
      expect(find.byType(SnackBarAction), findsNothing);
    });
  });

  group('undoable', () {
    testWidgets('should_use_a_longer_window_than_a_plain_confirm', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          (context) => AppFeedback.undoable(
            context,
            message: 'Category deleted',
            undoLabel: 'Undo',
            onUndo: () {},
          ),
        ),
      );

      await tester.tap(find.text('fire'));
      await tester.pump();

      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(bar.duration, const Duration(seconds: 5));

      // And a plain confirm is shorter, which is the whole point of the pair.
      expect(const Duration(seconds: 2), lessThan(bar.duration));
    });

    testWidgets('should_invoke_the_undo_callback', (tester) async {
      var restored = false;
      await tester.pumpWidget(
        host(
          (context) => AppFeedback.undoable(
            context,
            message: 'Category deleted',
            undoLabel: 'Undo',
            onUndo: () => restored = true,
          ),
        ),
      );

      await tester.tap(find.text('fire'));
      // Settle rather than pump one frame: the snack bar animates in, and until
      // that finishes the action is behind an `IgnorePointer` and a tap reports
      // a miss instead of invoking the callback.
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'));
      await tester.pump();

      expect(restored, isTrue);
    });
  });

  group('failure', () {
    testWidgets('should_stay_up_longer_than_a_confirmation', (tester) async {
      await tester.pumpWidget(
        host((context) => AppFeedback.failure(context, message: 'Nope')),
      );

      await tester.tap(find.text('fire'));
      await tester.pump();

      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      // A message the user may need to act on should not vanish in 2 s.
      expect(bar.duration, const Duration(seconds: 4));
    });

    testWidgets('should_offer_a_retry_action_when_asked', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        host(
          (context) => AppFeedback.failure(
            context,
            message: 'Nope',
            retryLabel: 'Retry',
            onRetry: () => retried = true,
          ),
        ),
      );

      await tester.tap(find.text('fire'));
      // See the undo test: the action only becomes tappable once the bar has
      // finished animating in.
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retried, isTrue);
    });
  });

  group('no messenger', () {
    testWidgets('should_be_a_no_op_rather_than_throwing', (tester) async {
      // A context with no `ScaffoldMessenger` above it at all. Feedback is
      // best-effort, so this must not be the reason an action fails.
      //
      // Deliberately *not* wrapped in `MaterialApp`: `MaterialApp` always
      // installs a `ScaffoldMessenger`, and calling `showSnackBar` on one with
      // no descendant `Scaffold` asserts inside Material itself. The behaviour
      // under test is `ScaffoldMessenger.maybeOf` returning null, so the host
      // has to be a bare element with no messenger.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: _noMessengerProbe),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('haptics', () {
    testWidgets('should_record_a_selection_tap_as_a_haptic', (tester) async {
      // Captured through the platform channel rather than asserted as "it did
      // not throw": `HapticFeedback.selectionClick` is a fire-and-forget
      // platform call, so a no-op would be silently indistinguishable.
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      AppFeedback.selection();
      await tester.pump();
      AppFeedback.success();
      await tester.pump();
      AppFeedback.destructive();
      await tester.pump();

      expect(calls, hasLength(3));
      // Three distinct strengths, so a destructive action feels different from
      // a selection before the snack bar is read.
      expect(calls[0].arguments, 'HapticFeedbackType.selectionClick');
      expect(calls[1].arguments, 'HapticFeedbackType.lightImpact');
      expect(calls[2].arguments, 'HapticFeedbackType.mediumImpact');
    });
  });
}
