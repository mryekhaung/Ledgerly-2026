import 'dart:math' as math;

import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/window_size.dart';
import 'package:material_ui/material_ui.dart';

/// Shared responsive layout primitives (docs/Platform.md §5).
///
/// Every page that changes shape with the window goes through these rather than
/// re-deriving breakpoints from `MediaQuery` — the rules ("two panes at medium
/// and up", "forms cap at 560 px") exist in one place, so a page cannot quietly
/// disagree with the shell about when the layout splits.
///
/// Presentation-only: nothing here reads a provider or a route, so it is safe to
/// use from any feature (`docs/Agent.md` §3.2).
///
/// ## What is *not* here: the content cap
///
/// A prose-width ceiling used to live here as `ConstrainedPane`, and pages
/// applied it themselves. That was the cause of a real defect: `AppBar` insets
/// its title by a fixed `titleSpacing`, so a page-capped column and its own
/// heading disagreed by 55 px on any window wider than the cap. The cap now
/// belongs to the page frame — pass `AppScaffold.contentMaxWidth` — so the frame
/// can centre the column *and* put the title on its left edge. There is
/// deliberately no second way to cap a page's content.

/// Splits into two panes at medium and up, single column below.
///
/// The *content* is the caller's business; this widget owns only the geometry.
/// Below the breakpoint the two children are simply stacked in a scroll view, so
/// a page can hand over the same two widgets for both layouts and cannot end up
/// with a pane that exists only on tablets.
///
/// The pane ratio is fixed rather than proportional: a 40/60 split on a 768 px
/// tablet and a 1440 px desktop gives the detail pane the same *character* at
/// both sizes, where a strictly proportional split would make the left pane
/// unusably wide on the desktop.
///
/// ## Why the master has a floor as well as a ceiling
///
/// [masterMaxWidth] alone is not enough. A bare flex share has **no floor**, so
/// the master shrinks with the window without limit — and the content inside it
/// does not. Measured on the calendar at an 894 px window: the 4-of-10 split
/// left the month pane **252 px**, of which `MonthSwitcher` spends 120 px on two
/// chevrons and a caret, leaving the month label **108 px** to live in when the
/// shipped font needs up to 130. The label ellipsized — silently, since
/// `TextOverflow` never throws, which is why no test caught it.
///
/// [masterMinWidth] is that floor. The master is given its flex share of the
/// row, clamped to `[masterMinWidth, masterMaxWidth]`, and the detail pane takes
/// whatever is left — so a pane can be *too small for its own header* only if
/// the caller says so.
class TwoPaneLayout extends StatelessWidget {
  /// Creates a two-pane layout.
  ///
  /// [masterMinWidth] must not exceed [masterMaxWidth].
  const TwoPaneLayout({
    required this.master,
    required this.detail,
    this.masterFlex = 4,
    this.detailFlex = 6,
    this.masterMinWidth = 280,
    this.masterMaxWidth = 420,
    this.detailMinWidth = 280,
    this.stackSpacing = AppSpacing.lg,
    this.paneSpacing = AppSpacing.xl,
    super.key,
  }) : assert(
         masterMinWidth <= masterMaxWidth,
         'masterMinWidth must not exceed masterMaxWidth, or the clamp is empty.',
       );

  /// The narrowest body that can hold **both** panes at their floors.
  ///
  /// A split needs two usable panes, not one. Below this the layout stacks
  /// instead, because a 300 px master beside a 196 px detail is worse than the
  /// single column it replaced.
  double get minBodyWidth => masterMinWidth + paneSpacing + detailMinWidth;

  /// Whether a body [bodyWidth] px wide can hold both panes at their floors.
  ///
  /// The static twin of [minBodyWidth], for a page whose *stacked* layout is not
  /// this widget's `Column` — the calendar stacks into one combined scroll view
  /// rather than two panes, so it branches on this and only hands the split to
  /// [TwoPaneLayout]. Keeping the arithmetic here means the page cannot disagree
  /// with the layout about when the split happens.
  static bool fits(
    double bodyWidth, {
    double masterMinWidth = 280,
    double detailMinWidth = 280,
    double paneSpacing = AppSpacing.xl,
  }) => bodyWidth >= masterMinWidth + paneSpacing + detailMinWidth;

  /// The leading pane — the thing being chosen (a month grid, a category list).
  final Widget master;

  /// The trailing pane — the thing being shown (a day's transactions, a form).
  final Widget detail;

  /// Flex weight of [master] in the split.
  final int masterFlex;

  /// Flex weight of [detail] in the split.
  final int detailFlex;

  /// Floor for [master]'s width — the narrowest the leading pane may get before
  /// its own content starts to clip. See the class doc.
  final double masterMinWidth;

  /// Ceiling for [master]'s width, so a large desktop does not stretch a list of
  /// short labels across half the window.
  final double masterMaxWidth;

  /// Floor for [detail]'s width. Below `masterMinWidth + paneSpacing + this` the
  /// layout stacks rather than splitting — see [minBodyWidth].
  final double detailMinWidth;

  /// Vertical gap between the panes when stacked.
  final double stackSpacing;

  /// Horizontal gap between the panes when side by side.
  final double paneSpacing;

  @override
  Widget build(BuildContext context) {
    final sizeClass = WindowSizeClass.of(context);

    // An explicit width rather than `Flexible`, because the master needs a
    // *floor* and a flex share cannot express one: `Flexible` would happily hand
    // the pane less than its minimum. The detail then takes the remainder, so
    // the two panes always fill the row exactly — no gap, no overflow.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Stack when the window is too narrow *or* when the body cannot hold
        // both panes at their floors. A split is only better than one column
        // while both halves of it work; a 300 px master beside a 196 px detail
        // is not, and it is what a size class alone would have allowed.
        if (!sizeClass.isTwoPaneCapable ||
            constraints.maxWidth < minBodyWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              master,
              SizedBox(height: stackSpacing),
              detail,
            ],
          );
        }

        final available = math.max(0.0, constraints.maxWidth - paneSpacing);
        final share = available * masterFlex / (masterFlex + detailFlex);
        // The second clamp is defensive: a body too narrow for the floor gets a
        // smaller master rather than a `RenderFlex` overflow, which is the
        // failure this whole layout exists to avoid.
        final masterWidth = math.min(
          share.clamp(masterMinWidth, masterMaxWidth).toDouble(),
          available,
        );

        return Row(
          // `stretch`, not `start`: a pane may contain a scrollable — the
          // category editor's form body is a `ListView`, and the detail pane is
          // exactly where a form goes. `start` leaves each child at its
          // intrinsic height, so a scrollable there is handed an unbounded box
          // and throws "Vertical viewport was given unbounded height" as soon as
          // the pane appears. `stretch` gives both panes the row's full height,
          // which is also what makes each pane scroll independently — the
          // behaviour the two-pane layout exists to provide.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(width: masterWidth, child: master),
            SizedBox(width: paneSpacing),
            Expanded(child: detail),
          ],
        );
      },
    );
  }
}

/// Page padding that follows the size class
/// (docs/Design.md §4.1: 16 compact, 24 medium+).
///
/// A `EdgeInsets` factory rather than a widget so it composes with `ListView`,
/// `SliverPadding` and `Padding` alike — the three call sites that need it do not
/// share a widget shape.
abstract final class ResponsiveInsets {
  const ResponsiveInsets._();

  /// Symmetric horizontal page padding for the current window.
  static EdgeInsets pageHorizontal(BuildContext context) =>
      EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal(MediaQuery.sizeOf(context).width),
      );

  /// Page padding on every side, plus a bottom gap that clears the shell's nav.
  static EdgeInsets page(
    BuildContext context, {
    double bottom = AppSpacing.lg,
  }) {
    final horizontal = AppSpacing.pageHorizontal(
      MediaQuery.sizeOf(context).width,
    );
    return EdgeInsets.fromLTRB(horizontal, AppSpacing.lg, horizontal, bottom);
  }
}

/// The centred-column treatment for a full-screen form route.
///
/// On compact this is a plain full-width page. On medium and up the same route
/// renders as a modal-styled card in the centre of the viewport
/// (docs/Platform.md §5) — same route, same widgets, different presentation, so
/// the form itself never branches on the window size.
class ModalFormScaffold extends StatelessWidget {
  /// Creates a form scaffold.
  const ModalFormScaffold({
    required this.title,
    required this.child,
    this.actions,
    this.maxWidth = AppSpacing.proseMaxWidth,
    super.key,
  });

  /// App-bar title.
  final String title;

  /// The form body.
  final Widget child;

  /// Optional app-bar actions.
  final List<Widget>? actions;

  /// Ceiling for the modal card's width.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final sizeClass = WindowSizeClass.of(context);
    final colors = AppThemeColors.of(context);

    // Compact stays a plain `Scaffold`: a card floating in the middle of a phone
    // screen wastes the little width there is and fights the platform's own
    // full-screen form convention.
    if (!sizeClass.usesModalForms) {
      return Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
        body: child,
      );
    }

    // Medium and up: the same route and the same widgets, presented as a card on
    // a sunk background so the form reads as a visit rather than a destination.
    //
    // The body is intentionally **not** wrapped in a scroll view. A form body is
    // itself a `ListView` (that is how `CategoryFormBody` scrolls), and nesting
    // it in a `SingleChildScrollView` hands the inner viewport an unbounded box
    // — a scroll view sizes its child to intrinsic height, and a `ListView` has
    // none — so it throws "Vertical viewport was given unbounded height". The
    // card is capped by the window and the inner list scrolls within it, which
    // is also the better feel: the card frame stays put instead of scrolling
    // away with the fields.
    return Scaffold(
      backgroundColor: colors.surfaceSunken,
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: colors.border),
                boxShadow: AppElevation.floating(colors),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
