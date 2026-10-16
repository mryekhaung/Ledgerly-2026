import 'dart:math' as math;

import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:material_ui/material_ui.dart';

/// The shared page frame (docs/Design.md §5.1).
///
/// Owns:
/// * Background: `surface` token.
/// * Content column: capped at [AppSpacing.contentMaxWidth] (or the page's
///   [contentMaxWidth]), centred horizontally and **top-aligned** so a short
///   body does not float to the middle of a tall window. See the class doc.
/// * Adaptive top bar: Cupertino style on iOS; M3 Top App Bar on Android/Web.
/// * Safe area and bottom navigation insets.
///
/// ## The content column, and why the title knows about it
///
/// A page whose body is a centred, width-capped column declares that column with
/// [contentMaxWidth]. The scaffold then caps and centres the body itself, and
/// insets the app-bar **title** to the same column's left edge.
///
/// That second half is not cosmetic. `AppBar` puts its title at
/// `titleSpacing` (16 px) from the toolbar's leading edge, while a centred
/// column sits at `(bodyWidth - cap) / 2`. The two only agree when the column is
/// as wide as the body — so on any window wider than the cap the title floated
/// to the left of its own content. Measured at a 894 px window: the title sat at
/// 16 px and the content column at 71 px, a **55 px** disagreement that reads as
/// the page being indented under its own heading. Setting `titleSpacing` to the
/// column's inset removes it exactly, at every width.
class AppScaffold extends StatelessWidget {
  /// Creates an [AppScaffold].
  const AppScaffold({
    required this.body,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottom,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.isScrollable = false,
    this.useSafeArea = true,
    this.contentPadding,
    this.backgroundColor,
    this.contentMaxWidth,
    this.contentInset,
    super.key,
  });

  /// The main page body.
  final Widget body;

  /// Page title as a plain string.
  final String? title;

  /// Custom title widget. If provided, overrides [title].
  final Widget? titleWidget;

  /// Leading widget in the top app bar.
  final Widget? leading;

  /// Trailing action widgets in the top app bar.
  ///
  /// `AppBar` lays these out as direct children of a `Row(mainAxisSize: min)`,
  /// which measures non-flex children with an **unbounded** main axis. A label
  /// long enough to exceed the toolbar therefore overflows rather than
  /// shrinking, and the toolbar is only 56 px tall so it cannot wrap either —
  /// at 2× type (`docs/Design.md` §8) even a two-word action does it. Wrap the
  /// action in `Flexible` and ellipsize its label if it can be long.
  final List<Widget>? actions;

  /// A widget below the top app bar — typically a `TabBar`.
  ///
  /// Tabs are part of the app bar in M3, not part of the body: putting a
  /// `TabBar` in the body would scroll away with the content and lose the
  /// platform's own tab-bar treatment. Pages that do not pass [title],
  /// [leading] or [actions] still get a bar when [bottom] is set.
  final PreferredSizeWidget? bottom;

  /// Optional bottom navigation or dock.
  final Widget? bottomNavigationBar;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// When true, wraps the body in a [SingleChildScrollView].
  final bool isScrollable;

  /// Whether to wrap the content in a [SafeArea].
  final bool useSafeArea;

  /// Optional padding around the [body].
  final EdgeInsetsGeometry? contentPadding;

  /// Background color override. Defaults to `colors.surface`.
  final Color? backgroundColor;

  /// Cap for this page's content column, in logical pixels.
  ///
  /// Pass it when the body is a single centred column — a form, a settings
  /// list, prose — so the scaffold can cap and centre it *and* line the title up
  /// with it. The scaffold is the **only** owner of that column: a page that
  /// capped its own body would put the cap and the title back out of step, which
  /// is the defect this parameter exists to remove.
  ///
  /// Leave null when the page fills the body (a calendar, a grid, a two-pane
  /// split). The scaffold still applies its own [AppSpacing.contentMaxWidth]
  /// ceiling, and the title keeps the platform's default inset.
  final double? contentMaxWidth;

  /// Horizontal inset the page's content sits at *inside* [contentMaxWidth].
  ///
  /// Only used to place the title, and only defaults to the shared page padding
  /// ([AppSpacing.pageHorizontal]). Override it for the pages that inset
  /// differently, so the title still lands on the content rather than on a
  /// token the page does not use.
  final double? contentInset;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _page(context, constraints.maxWidth),
  );

  /// Builds the frame for a body [bodyWidth] px wide.
  ///
  /// Takes the width as a parameter rather than reading `MediaQuery`: inside the
  /// shell the app bar and the body already sit to the *right* of the navigation
  /// rail, so the window width is wider than the space a page actually gets, and
  /// a column centred on the window would be off by half the rail.
  Widget _page(BuildContext context, double bodyWidth) {
    final colors = AppThemeColors.of(context);
    final platform = AppPlatform.resolve();

    final cap = contentMaxWidth ?? AppSpacing.contentMaxWidth;
    // Where the column's left edge lands. Zero once the body is narrower than
    // the cap, which is the common case on a phone.
    final gutter = math.max(0.0, (bodyWidth - cap) / 2);
    final inset =
        contentInset ??
        AppSpacing.pageHorizontal(MediaQuery.sizeOf(context).width);

    final resolvedTitle =
        titleWidget ??
        (title != null
            ? Text(
                title!,
                style: AppTypography.title.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null);

    final appBar =
        (resolvedTitle != null ||
            leading != null ||
            actions != null ||
            bottom != null)
        ? AppBar(
            title: resolvedTitle,
            leading: leading,
            actions: actions,
            bottom: bottom,
            // `titleSpacing` pads *both* sides of the title, so setting it to
            // the column's inset puts the title's left edge exactly on the
            // content's. Only pages that declared a column get it; everyone else
            // keeps the platform default, so this cannot shift a page that did
            // not opt in.
            titleSpacing: contentMaxWidth == null ? null : gutter + inset,
            centerTitle: platform.usesCupertino,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: IconThemeData(color: colors.textPrimary),
          )
        : null;

    Widget content = body;

    if (contentPadding != null) {
      content = Padding(padding: contentPadding!, child: content);
    }

    if (isScrollable) {
      content = SingleChildScrollView(
        physics: platform.usesCupertino
            ? const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              )
            : const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
        child: content,
      );
    }

    // The content column: capped, centred in the body, and top-aligned so a
    // short body does not float to the middle of a tall window.
    content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cap),
        child: content,
      ),
    );

    if (useSafeArea) {
      content = SafeArea(
        top: appBar == null,
        bottom: bottomNavigationBar == null,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? colors.surface,
      appBar: appBar,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
