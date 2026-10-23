import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// A shimmering placeholder block (docs/Design.md §5.11).
///
/// The building block for first-paint skeletons. §5.11 is explicit that a
/// first paint shows **a skeleton matching the final layout**, never a centred
/// spinner: the spinner tells the user only that *something* is happening,
/// while a skeleton tells them *what* is about to appear, and it removes the
/// layout jump when the data lands.
///
/// Compose these into a shape that mirrors the real content — [AppSkeletonList]
/// covers the common "n rows" case.
class AppSkeleton extends StatefulWidget {
  /// A single skeleton block.
  const AppSkeleton({
    this.width,
    this.height = 16,
    this.radius = AppRadius.sm,
    this.shape = BoxShape.rectangle,
    super.key,
  });

  /// Block width. Stretches to the parent when null.
  final double? width;

  /// Block height.
  final double height;

  /// Corner radius. Ignored when [shape] is [BoxShape.circle].
  final double radius;

  /// Block shape.
  final BoxShape shape;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    // Reduce Motion collapses the pulse to a static block rather than removing
    // the skeleton: the layout hint is the point, the shimmer is decoration.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final block = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        shape: widget.shape,
        borderRadius: widget.shape == BoxShape.circle
            ? null
            : BorderRadius.circular(widget.radius),
      ),
    );

    if (reduceMotion) return block;

    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.45,
        end: 1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: block,
    );
  }
}

/// A skeleton list that mirrors a column of rows (docs/Design.md §5.11).
///
/// Use on first paint for any list-shaped screen — transactions, accounts,
/// budgets, goals, recurring. Each row is a leading gem-sized circle, a short
/// title bar and a trailing amount bar, i.e. the shape of a real row, so the
/// swap to content does not reflow.
class AppSkeletonList extends StatelessWidget {
  /// Creates a skeleton list.
  const AppSkeletonList({
    this.rows = 6,
    this.padding,
    this.rowHeight = AppRowHeight.twoLine,
    super.key,
  });

  /// How many rows to draw.
  final int rows;

  /// Outer padding. Defaults to the page's horizontal inset.
  final EdgeInsetsGeometry? padding;

  /// Height of each row.
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal(
              MediaQuery.sizeOf(context).width,
            ),
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(
          rows,
          (index) => SizedBox(
            height: rowHeight,
            child: const Row(
              children: <Widget>[
                AppSkeleton(width: 40, height: 40, shape: BoxShape.circle),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppSkeleton(width: 140, height: 14),
                      SizedBox(height: AppSpacing.sm),
                      AppSkeleton(width: 88, height: 12),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                AppSkeleton(width: 72, height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A skeleton that mirrors a card with a title and a large figure
/// (docs/Design.md §5.11) — the summary-card shape on calendar/insights.
class AppSkeletonCard extends StatelessWidget {
  /// Creates a skeleton card.
  const AppSkeletonCard({this.height = 120, super.key});

  /// Overall card height.
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AppSkeleton(width: 96, height: 12),
          SizedBox(height: AppSpacing.md),
          AppSkeleton(width: 180, height: 28),
        ],
      ),
    );
  }
}
