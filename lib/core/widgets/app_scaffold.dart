import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:material_ui/material_ui.dart';

/// The shared page frame (docs/Design.md §5.1).
///
/// Owns:
/// * Background: `surface` token.
/// * Max content width: `ConstrainedBox(maxWidth: 1200)` (centered on wide displays).
/// * Adaptive top bar: Cupertino style on iOS; M3 Top App Bar on Android/Web.
/// * Safe area and bottom navigation insets.
class AppScaffold extends StatelessWidget {
  /// Creates an [AppScaffold].
  const AppScaffold({
    required this.body,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.isScrollable = false,
    this.useSafeArea = true,
    this.contentPadding,
    this.backgroundColor,
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

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final platform = AppPlatform.resolve();

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

    final appBar = (resolvedTitle != null || leading != null || actions != null)
        ? AppBar(
            title: resolvedTitle,
            leading: leading,
            actions: actions,
            centerTitle: platform.usesLiquidGlass,
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
        physics: platform.usesLiquidGlass
            ? const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              )
            : const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
        child: content,
      );
    }

    // Centered content capped at contentMaxWidth (1200 px) for wide screens.
    content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
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
