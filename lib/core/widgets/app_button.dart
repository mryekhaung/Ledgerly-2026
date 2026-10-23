import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveButton, AdaptiveButtonStyle, PlatformInfo;
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
    this.color,
    this.platform,
    this.isIOS26,
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

  /// Optional tint for a primary action, such as income/expense feedback.
  final Color? color;

  /// Platform override for tests.
  final AppPlatform? platform;

  /// iOS 26+ override for tests.
  final bool? isIOS26;

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
    final platform = widget.platform ?? AppPlatform.resolve();
    final isIOS26 = widget.isIOS26 ?? PlatformInfo.isIOS26OrHigher();

    final (
      Color backgroundColor,
      Color foregroundColor,
      BorderSide? borderSide,
      double minHeight,
    ) = switch (widget.variant) {
      AppButtonVariant.primary => (
        widget.color ?? colors.brandPrimary,
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

    final childContent = widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        // A label long enough to exceed the button at 2× type
        // (`docs/Design.md` §8) has to be allowed to take less than its
        // intrinsic width. `Flexible` is loose, so a label that does fit still
        // hugs its content under `MainAxisSize.min`.
        //
        // This is also safe where `AppButton` is a non-flex child of a `Row`
        // (`data_transfer/widgets/import_tab.dart`), which measures it with an
        // unbounded main axis: `RenderFlex` only allocates space to flexible
        // children when the main axis is bounded, and otherwise lays them out
        // exactly as if they were non-flex. So the label falls back to its
        // intrinsic width rather than collapsing.
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
              Flexible(
                child: Text(
                  widget.label,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: AppRadius.borderFull,
      side: borderSide ?? BorderSide.none,
    );

    if (platform.usesCupertino && isIOS26) {
      final adaptiveStyle = switch (widget.variant) {
        AppButtonVariant.primary => AdaptiveButtonStyle.prominentGlass,
        AppButtonVariant.secondary => AdaptiveButtonStyle.bordered,
        AppButtonVariant.ghost ||
        AppButtonVariant.destructive => AdaptiveButtonStyle.plain,
      };
      final adaptiveButton = SizedBox(
        width: widget.isExpanded ? double.infinity : null,
        child: AdaptiveButton.child(
          onPressed: _isEnabled
              ? () {
                  if (widget.variant == AppButtonVariant.destructive) {
                    AppFeedback.destructive();
                  } else {
                    AppFeedback.selection();
                  }
                  widget.onPressed?.call();
                }
              : null,
          enabled: _isEnabled,
          style: adaptiveStyle,
          color: widget.variant == AppButtonVariant.primary
              ? backgroundColor
              : foregroundColor,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          minSize: Size(
            widget.isExpanded ? 0 : AppHitTarget.comfortable,
            minHeight,
          ),
          borderRadius: AppRadius.borderFull,
          useSmoothRectangleBorder: false,
          child: childContent,
        ),
      );
      return widget.semanticsLabel == null
          ? adaptiveButton
          : Semantics(
              label: widget.semanticsLabel,
              button: true,
              enabled: _isEnabled,
              child: adaptiveButton,
            );
    }

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

    if (platform.usesCupertino) {
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
