import 'dart:math' as math;

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart' as cupertino;
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
/// * Adaptive top bar: Cupertino-style on iOS; M3 Top App Bar on Android/Web.
/// * Safe area and bottom navigation insets.
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
  final List<Widget>? actions;

  /// A widget below the top app bar — typically a `TabBar`.
  final PreferredSizeWidget? bottom;

  /// Optional bottom navigation or dock.
  final Widget? bottomNavigationBar;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Whether the whole page scrolls as one block.
  final bool isScrollable;

  /// Whether to wrap the content in `SafeArea`.
  final bool useSafeArea;

  /// Extra padding applied to the whole content column.
  final EdgeInsetsGeometry? contentPadding;

  /// Optional override for the page background.
  final Color? backgroundColor;

  /// The maximum width of the content column. When `null`, the scaffold uses
  /// [AppSpacing.contentMaxWidth].
  final double? contentMaxWidth;

  /// The inset used to compute the title's left edge when [contentMaxWidth] is
  /// set. Defaults to the page's horizontal padding.
  final double? contentInset;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _page(context, constraints.maxWidth),
  );

  /// The page, laid out for the width the shell actually gave it — not the
  /// window width. On medium+ a rail or sidebar eats into the viewport.
  Widget _page(BuildContext context, double bodyWidth) {
    final colors = AppThemeColors.of(context);
    final platform = AppPlatform.resolve();

    final cap = contentMaxWidth ?? AppSpacing.contentMaxWidth;
    final gutter = math.max(0.0, (bodyWidth - cap) / 2);
    final inset =
        contentInset ??
        AppSpacing.pageHorizontal(MediaQuery.sizeOf(context).width);

    final resolvedTitle =
        titleWidget ??
        (title != null
            ? Text(
                title!,
                style:
                    (platform.usesCupertino
                            ? AppTypography.titleLarge
                            : AppTypography.title)
                        .copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null);

    final hasAppBar =
        resolvedTitle != null ||
        leading != null ||
        actions != null ||
        bottom != null;
    final useNativeToolbar =
        PlatformInfo.isIOS26OrHigher() &&
        title != null &&
        titleWidget == null &&
        leading == null &&
        actions == null &&
        bottom == null;

    PreferredSizeWidget? appBar;
    AdaptiveAppBar? adaptiveAppBar;
    if (hasAppBar) {
      if (platform.usesCupertino) {
        adaptiveAppBar = AdaptiveAppBar(
          title: title,
          useNativeToolbar: useNativeToolbar,
          cupertinoNavigationBar: useNativeToolbar
              ? null
              : _AppCupertinoBar(
                  middle: resolvedTitle,
                  leading: leading,
                  trailing: actions == null
                      ? null
                      : Row(mainAxisSize: MainAxisSize.min, children: actions!),
                  bottom: bottom,
                ),
        );
      } else {
        appBar = AppBar(
          title: resolvedTitle,
          leading: leading,
          actions: actions,
          bottom: bottom,
          titleSpacing: contentMaxWidth == null ? null : gutter + inset,
          centerTitle: platform.usesCupertino,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: colors.textPrimary),
        );
      }
    }

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

    content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cap),
        child: content,
      ),
    );

    if (useSafeArea) {
      content = SafeArea(
        // iOS delegates its chrome to `AdaptiveScaffold`, which measures the
        // CupertinoNavigationBar itself — only the Material path needs the
        // scaffold-aware top inset.
        top: !platform.usesCupertino && appBar == null,
        bottom: bottomNavigationBar == null,
        child: content,
      );
    }

    if (platform.usesCupertino) {
      // On iOS 26+ the shell's native `UITabBar` overlays the body rather than
      // consuming layout space, and the package only lifts its own FAB 16 px.
      // Give ours the tab-bar's height (~80 px) so it clears the glass bar.
      Widget? fab = floatingActionButton;
      if (fab != null && PlatformInfo.isIOS26OrHigher()) {
        fab = Padding(padding: const EdgeInsets.only(bottom: 80), child: fab);
      }
      return AdaptiveScaffold(
        appBar: adaptiveAppBar,
        body: Material(
          color: backgroundColor ?? colors.surface,
          child: content,
        ),
        backgroundColor: backgroundColor ?? colors.surface,
        floatingActionButton: fab,
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

/// The iOS top bar — a real `CupertinoNavigationBar` so the page inherits the
/// platform's back affordance, blur, and title behaviour instead of a
/// hand-drawn header. It keeps the app's custom widgets (tabs in [bottom],
/// icon buttons in [trailing]) because the iOS 26+ native `UIToolbar` can only
/// host SF-symbol actions.
class _AppCupertinoBar extends StatelessWidget
    implements cupertino.ObstructingPreferredSizeWidget {
  const _AppCupertinoBar({
    required this.middle,
    required this.leading,
    required this.trailing,
    required this.bottom,
  });

  final Widget? middle;
  final Widget? leading;
  final Widget? trailing;
  final PreferredSizeWidget? bottom;

  /// Matches `CupertinoNavigationBar`'s intrinsic height so the
  /// `CupertinoPageScaffold` insets the body correctly.
  static const double _barHeight = 44;

  @override
  Size get preferredSize =>
      Size.fromHeight(_barHeight + (bottom?.preferredSize.height ?? 0));

  @override
  bool shouldFullyObstruct(BuildContext context) => true;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final resolvedLeading =
        leading ??
        (navigator.canPop()
            ? cupertino.CupertinoNavigationBarBackButton(
                onPressed: navigator.pop,
              )
            : null);

    final navBar = cupertino.CupertinoNavigationBar(
      automaticallyImplyLeading: false,
      leading: resolvedLeading,
      middle: middle,
      trailing: trailing,
      border: null,
    );
    if (bottom == null) return navBar;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[navBar, bottom!],
    );
  }
}
