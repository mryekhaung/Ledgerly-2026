import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Button visual variants (docs/Design.md §5.7).
enum AppButtonVariant {
  /// `brandPrimary` fill, `textOnBrand`, height 52, `radius.full`. One per screen max.
  primary,

  /// Transparent fill, `borderStrong` hairline, `textPrimary`, height 52, `radius.full`.
  secondary,

  /// Text only, `brandPrimary`. Inline actions.
  ghost,

  /// `moneyOut` text, no fill. Destructive actions.
  destructive,
}

/// Standard adaptive button (docs/Design.md §5.7).
class AppButton extends StatefulWidget {
  /// Creates an [AppButton].
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.semanticsLabel,
    super.key,
  });

  /// Button text.
  final String label;

  /// Callback when pressed. When null or [isLoading] is true, the button is disabled.
  final VoidCallback? onPressed;

  /// Visual variant.
  final AppButtonVariant variant;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether the button is in a loading state.
  final bool isLoading;

  /// Whether the button expands to fill horizontal width.
  final bool isExpanded;

  /// Screen reader label.
  final String? semanticsLabel;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  void _handleTapDown(TapDownDetails _) {
    if (!_isEnabled) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (!_isEnabled) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (!_isEnabled) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final platform = AppPlatform.resolve();

    final (
      Color backgroundColor,
      Color foregroundColor,
      BorderSide? borderSide,
      double minHeight,
    ) = switch (widget.variant) {
      AppButtonVariant.primary => (
        colors.brandPrimary,
        colors.textOnBrand,
        null,
        52.0,
      ),
      AppButtonVariant.secondary => (
        Colors.transparent,
        colors.textPrimary,
        BorderSide(color: colors.borderStrong, width: 1.0),
        52.0,
      ),
      AppButtonVariant.ghost => (
        Colors.transparent,
        colors.brandPrimary,
        null,
        AppHitTarget.minimum,
      ),
      AppButtonVariant.destructive => (
        Colors.transparent,
        colors.moneyOut,
        null,
        AppHitTarget.minimum,
      ),
    };

    final textStyle = AppTypography.title.copyWith(
      color: foregroundColor,
      fontWeight: FontWeight.w600,
    );

    Widget childContent = widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: widget.isExpanded
                ? MainAxisSize.max
                : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (widget.icon != null) ...<Widget>[
                Icon(widget.icon, size: 20, color: foregroundColor),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                widget.label,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: AppRadius.borderFull,
      side: borderSide ?? BorderSide.none,
    );

    Widget button = Container(
      constraints: BoxConstraints(
        minHeight: minHeight,
        minWidth: widget.isExpanded
            ? double.infinity
            : AppHitTarget.comfortable,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      decoration: ShapeDecoration(color: backgroundColor, shape: shape),
      child: Center(child: childContent),
    );

    if (platform.usesLiquidGlass) {
      button = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _isEnabled
            ? () {
                if (widget.variant == AppButtonVariant.destructive) {
                  AppFeedback.destructive();
                } else {
                  AppFeedback.selection();
                }
                widget.onPressed?.call();
              }
            : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          opacity: !_isEnabled ? 0.4 : (_isPressed ? 0.92 : 1.0),
          duration: AppMotion.micro,
          curve: AppMotion.standard,
          child: button,
        ),
      );
    } else {
      button = Material(
        color: Colors.transparent,
        shape: shape,
        child: InkWell(
          onTap: _isEnabled
              ? () {
                  if (widget.variant == AppButtonVariant.destructive) {
                    AppFeedback.destructive();
                  } else {
                    AppFeedback.selection();
                  }
                  widget.onPressed?.call();
                }
              : null,
          customBorder: shape,
          child: Opacity(opacity: _isEnabled ? 1.0 : 0.4, child: button),
        ),
      );
    }

    if (widget.semanticsLabel != null) {
      button = Semantics(
        label: widget.semanticsLabel,
        button: true,
        enabled: _isEnabled,
        child: button,
      );
    }

    return button;
  }
}
