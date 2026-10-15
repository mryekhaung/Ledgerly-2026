import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Scope used to enforce the rule: **Never nest an [AppCard] inside another [AppCard]**
/// (docs/Design.md §5.2).
class _AppCardScope extends InheritedWidget {
  const _AppCardScope({required super.child});

  static bool isInside(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AppCardScope>() != null;

  @override
  bool updateShouldNotify(_AppCardScope oldWidget) => false;
}

/// The core container card (docs/Design.md §5.2).
///
/// * Surface: `surfaceRaised`, `radius.lg`, padding `lg`, elevation `raised`, no border.
/// * Optional [onTap] adds press state (`micro` fade to 96% opacity + light haptic on iOS;
///   smooth touch wash on Material/Web).
/// * **Never nest an [AppCard] inside another [AppCard]** (checked via debug assert).
class AppCard extends StatefulWidget {
  /// Creates an [AppCard].
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.borderRadius = AppRadius.borderLg,
    this.border,
    this.semanticsLabel,
    this.color,
    super.key,
  });

  /// The card's content.
  final Widget child;

  /// Optional tap handler. When provided, the card shows interactive press feedback.
  final VoidCallback? onTap;

  /// Internal padding. Defaults to `AppSpacing.lg` (16 px).
  final EdgeInsetsGeometry padding;

  /// Outer margin.
  final EdgeInsetsGeometry? margin;

  /// Corner radius. Defaults to `AppRadius.borderLg` (20 px).
  final BorderRadius borderRadius;

  /// Optional hairline border. Defaults to none per §5.2 (tint + shadow,
  /// not a box outline). Status-signalling borders (goal completed, recurring
  /// due) pass their `BorderSide` here instead of hand-rolling a `Card`.
  final BoxBorder? border;

  /// Optional semantic label for screen readers.
  final String? semanticsLabel;

  /// Background color override. When null, uses `colors.surfaceRaised`.
  final Color? color;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      !_AppCardScope.isInside(context),
      'Never nest an AppCard inside another AppCard (docs/Design.md §5.2).',
    );

    final colors = AppThemeColors.of(context);
    final platform = AppPlatform.resolve();
    final backgroundColor = widget.color ?? colors.surfaceRaised;
    final shadows = AppElevation.raised(colors);

    Widget content = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: widget.borderRadius,
        border: widget.border,
        boxShadow: shadows,
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      if (platform.usesLiquidGlass) {
        // iOS: micro fade to 96% opacity + light haptic, never a ripple (docs/Design.md §5.2).
        content = GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: () {
            AppFeedback.selection();
            widget.onTap?.call();
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedOpacity(
            opacity: _isPressed ? 0.96 : 1.0,
            duration: AppMotion.micro,
            curve: AppMotion.standard,
            child: content,
          ),
        );
      } else {
        // Material/Web: ink touch wash
        content = Material(
          color: Colors.transparent,
          borderRadius: widget.borderRadius,
          child: InkWell(
            onTap: () {
              AppFeedback.selection();
              widget.onTap?.call();
            },
            borderRadius: widget.borderRadius,
            splashColor: colors.brandSubtle,
            highlightColor: colors.surfaceSunken,
            child: content,
          ),
        );
      }
    }

    if (widget.margin != null) {
      content = Padding(padding: widget.margin!, child: content);
    }

    if (widget.semanticsLabel != null) {
      content = Semantics(
        label: widget.semanticsLabel,
        button: widget.onTap != null,
        child: content,
      );
    }

    return _AppCardScope(child: content);
  }
}
