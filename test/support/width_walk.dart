import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:material_ui/material_ui.dart';

/// Hosts one page at a given surface [width] and text scale.
///
/// Implementations are the `host()` helpers the screen tests already have; the
/// parameters are optional there so the same function can serve a golden (which
/// varies `brightness`) and the walk below (which varies width and scale).
typedef PageHost = Future<void> Function(
  WidgetTester tester, {
  double width,
  double textScale,
});

/// Registers the `every mandated width` group for [pageName].
///
/// `docs/Agent.md` §6 and `docs/Design.md` §8 make this a hard requirement:
/// every screen must be verified at 360 / 390 / 430 / 768 / 1024 / 1440 px, at
/// text scale 1.0 **and** 2.0, with zero overflow. It is the one DoD bullet that
/// no amount of golden coverage satisfies — a golden pins a single width, so a
/// screen that only breaks at 360 px (or only at large type) passes every golden
/// it has.
///
/// That is not hypothetical. Adding this walk to the nine screens that lacked it
/// found **eleven** overflow sites, every one of them at 360 px with text scale
/// 2.0 — invisible to the goldens those screens already had.
///
/// **Coverage caveat.** The walk only sees what actually gets laid out, and a
/// page whose body is a lazy list builds just the viewport. A widget below the
/// fold is never measured, so neither this walk nor the golden can catch its
/// overflow — `TopCategoriesCard` on the insights page was exactly that case and
/// needed a focused widget test instead. Extending the walk to scroll each page
/// to the bottom would close the gap.
///
/// Each width is pumped into a **fresh** tree: the app is unmounted between
/// iterations. Re-pumping on top of the previous tree trips a framework
/// assertion in `_RenderObjectSemantics._collectChildMergeUpAndSiblingGroup`
/// ("!childSemantics.renderObject._needsLayout is not true") — a lazy scrollable
/// carrying `MergeSemantics` rows has its semantics updated while a render
/// object is still dirty. Unmounting is what a separate `testWidgets` per width
/// would do for free.
///
/// `pumpAndSettle` cannot be used: the first paint is a skeleton whose shimmer
/// never settles. So the frames are pumped explicitly — the loading frame, then
/// two timed frames that let an overridden stream deliver — and the assertion
/// runs after **each**, so a failure names the frame it happened on instead of
/// only the width.
void widthWalkGroup({required String pageName, required PageHost host}) {
  group('every mandated width', () {
    testWidgets('should_lay_out_without_overflowing_at_any_width', (
      tester,
    ) async {
      await _walkAtEveryWidth(
        tester,
        pageName: pageName,
        host: host,
        textScale: 1,
      );
    });

    testWidgets('should_lay_out_without_overflowing_at_text_scale_2', (
      tester,
    ) async {
      await _walkAtEveryWidth(
        tester,
        pageName: pageName,
        host: host,
        textScale: 2,
      );
    });
  });
}

/// The frames the walk checks, in order.
///
/// 0 ms is the loading skeleton, 100 ms is the frame an overridden
/// `Stream`/`Future` provider lands on, and 400 ms covers anything that resolves
/// through a second hop. Content that needs longer than this is not covered —
/// deliberately, because a page that takes 400 ms to show data has a different
/// problem.
const List<Duration> _frames = <Duration>[
  Duration.zero,
  Duration(milliseconds: 100),
  Duration(milliseconds: 400),
];

Future<void> _walkAtEveryWidth(
  WidgetTester tester, {
  required String pageName,
  required PageHost host,
  required double textScale,
}) async {
  for (final width in TestWidths.all) {
    await host(tester, width: width, textScale: textScale);

    for (var i = 0; i < _frames.length; i++) {
      final frame = _frames[i];
      await tester.pump(frame);

      // `takeException` reports only the overflow amount, not the widget, so
      // the reason names the configuration instead. To see the offending
      // widget, comment this `expect` out — the framework then prints the full
      // `FlutterErrorDetails`, including the creator chain and constraints.
      final probe = tester.takeException();
      expect(
        probe,
        isNull,
        reason:
            '$pageName laid out with an error at ${width}px '
            '(text scale $textScale, frame ${frame.inMilliseconds}ms).',
      );
    }

    // Unmount so the next width starts from a clean tree.
    await tester.pumpWidget(const SizedBox.shrink());
  }
}
