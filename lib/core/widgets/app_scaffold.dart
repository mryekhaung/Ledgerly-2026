import 'dart:math' as math;

import 'package:ledgerly/app/theme/app_icons.dart';
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

    PreferredSizeWidget? appBar;
    if (hasAppBar) {
      if (platform.usesCupertino) {
        appBar = _CupertinoAppBar(
          title: resolvedTitle,
          leading: leading,
          actions: actions,
          bottom: bottom,
          titleSpacing: contentMaxWidth == null ? null : gutter + inset,
          backgroundColor: colors.surface,
          iconColor: colors.textPrimary,
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

/// The iOS top bar — a quiet Cupertino-style navigation bar.
class _CupertinoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CupertinoAppBar({
    required this.title,
    required this.leading,
    required this.actions,
    required this.bottom,
    required this.titleSpacing,
    required this.backgroundColor,
    required this.iconColor,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double? titleSpacing;
  final Color backgroundColor;
  final Color iconColor;

  static const double _barHeight = 56;

  @override
  Size get preferredSize =>
      Size.fromHeight(_barHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.maybeOf(context)?.canPop() ?? false;
    final effectiveLeading =
        leading ?? (canPop ? _CupertinoBackButton(color: iconColor) : null);

    final trailing = actions == null
        ? null
        : Row(mainAxisSize: MainAxisSize.min, children: actions!);

    return Container(
      height: _barHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: AppThemeColors.of(context).border,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: NavigationToolbar(
          leading: effectiveLeading == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: effectiveLeading,
                ),
          middle: title,
          trailing: trailing,
          middleSpacing: titleSpacing ?? NavigationToolbar.kMiddleSpacing,
        ),
      ),
    );
  }
}

/// iOS-style back button — a chevron, not an arrow.
class _CupertinoBackButton extends StatelessWidget {
  const _CupertinoBackButton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.of(context).maybePop(),
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      width: AppHitTarget.minimum,
      height: AppHitTarget.minimum,
      child: Center(child: Icon(AppIcons.chevronLeft, color: color, size: 28)),
    ),
  );
}
