import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Horizontal swipe area that turns a drag into a month change.
///
/// Extracted from `calendar_page.dart` so the page stays a composition root
/// (`docs/Conventions.md` §1 — one public class per file, ~200 lines each).
class MonthSwipeArea extends StatefulWidget {
  /// Creates a [MonthSwipeArea].
  const MonthSwipeArea({
    required this.onPrevious,
    required this.onNext,
    required this.child,
    super.key,
  });

  /// Called on a right flick / drag.
  final VoidCallback onPrevious;

  /// Called on a left flick / drag.
  final VoidCallback onNext;

  /// The content that owns horizontal gestures.
  final Widget child;

  @override
  State<MonthSwipeArea> createState() => _MonthSwipeAreaState();
}

class _MonthSwipeAreaState extends State<MonthSwipeArea> {
  /// Fraction of the widget's width a slow drag must cover to count.
  static const double _distanceFraction = 0.15;

  /// Logical px/s above which a flick counts regardless of distance.
  static const double _velocityThreshold = 250;

  /// Total horizontal distance travelled during the current drag.
  ///
  /// Accumulated from `onHorizontalDragUpdate` rather than read off
  /// `DragEndDetails.localPosition`, because that field is the pointer's final
  /// *position*, not the distance moved — comparing an absolute coordinate
  /// against a width fraction would fire at the wrong place on the screen.
  double _dragged = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // `translucent` so the gesture is picked up over the grid's gaps, where
      // there is no painted child to hit-test against.
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _dragged = 0,
      onHorizontalDragUpdate: (details) => _dragged += details.delta.dx,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        final threshold = MediaQuery.sizeOf(context).width * _distanceFraction;
        final draggedFarEnough = _dragged.abs() > threshold;

        // Negative = finger moved left = advance to the next month. Matches
        // every calendar the user has ever used.
        if (velocity < -_velocityThreshold ||
            (velocity < 0 && draggedFarEnough)) {
          AppFeedback.selection();
          widget.onNext();
        } else if (velocity > _velocityThreshold ||
            (velocity > 0 && draggedFarEnough)) {
          AppFeedback.selection();
          widget.onPrevious();
        }
      },
      child: widget.child,
    );
  }
}
