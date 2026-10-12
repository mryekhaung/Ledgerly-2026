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
class TwoPaneLayout extends StatelessWidget {
  /// Creates a two-pane layout.
  const TwoPaneLayout({
    required this.master,
    required this.detail,
    this.masterFlex = 4,
    this.detailFlex = 6,
    this.masterMaxWidth = 420,
    this.stackSpacing = AppSpacing.lg,
    this.paneSpacing = AppSpacing.xl,
    super.key,
  });

  /// The leading pane — the thing being chosen (a month grid, a category list).
  final Widget master;

  /// The trailing pane — the thing being shown (a day's transactions, a form).
  final Widget detail;

  /// Flex weight of [master] in the split.
  final int masterFlex;

  /// Flex weight of [detail] in the split.
  final int detailFlex;

  /// Ceiling for [master]'s width, so a large desktop does not stretch a list of
  /// short labels across half the window.
  final double masterMaxWidth;

  /// Vertical gap between the panes when stacked.
  final double stackSpacing;

  /// Horizontal gap between the panes when side by side.
  final double paneSpacing;

  @override
  Widget build(BuildContext context) {
    final sizeClass = WindowSizeClass.of(context);

    if (!sizeClass.isTwoPaneCapable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          master,
          SizedBox(height: stackSpacing),
          detail,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Flexible(
          flex: masterFlex,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: masterMaxWidth),
            child: master,
          ),
        ),
        SizedBox(width: paneSpacing),
        Expanded(flex: detailFlex, child: detail),
      ],
    );
  }
}

/// Caps and centres content at a readable width (docs/Design.md §8).
///
/// Applied to single-column prose and to forms, which must not stretch to the
/// full width of a desktop window — a 1200 px-wide text field is unreadable and
/// makes the label-to-input association hard to follow.
class ConstrainedPane extends StatelessWidget {
  /// Creates a width-capped pane.
  const ConstrainedPane({
    required this.child,
    this.maxWidth = AppSpacing.proseMaxWidth,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  /// The content.
  final Widget child;

  /// Ceiling in logical pixels. Defaults to the prose limit (560).
  final double maxWidth;

  /// Where to place the capped box in the available space.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
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
    return Scaffold(
      backgroundColor: colors.surfaceSunken,
      appBar: AppBar(title: Text(title), actions: actions),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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
