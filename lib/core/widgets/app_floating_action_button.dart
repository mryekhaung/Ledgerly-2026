import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show
        AdaptiveButton,
        AdaptiveButtonSize,
        AdaptiveButtonStyle,
        AdaptiveFloatingActionButton,
        PlatformInfo;
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart'
    show
        BuildContext,
        Color,
        Icon,
        IconData,
        Semantics,
        StatelessWidget,
        Tooltip,
        VoidCallback,
        Widget;

/// A floating action that uses Liquid Glass on iOS 26+ and native platform
/// button styling elsewhere.
class AppFloatingActionButton extends StatelessWidget {
  /// Creates a floating action button.
  const AppFloatingActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  /// Called when the button is pressed.
  final VoidCallback onPressed;

  /// The icon to display.
  final IconData icon;

  /// The accessible name and tooltip.
  final String label;

  /// Optional tint for the button background.
  final Color? backgroundColor;

  /// Optional tint for the button icon.
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final resolvedBackground = backgroundColor ?? colors.brandPrimary;
    final resolvedForeground = foregroundColor ?? colors.textOnBrand;

    if (PlatformInfo.isIOS26OrHigher()) {
      return Semantics(
        label: label,
        button: true,
        onTap: onPressed,
        excludeSemantics: true,
        child: AdaptiveButton.icon(
          onPressed: onPressed,
          icon: icon,
          color: resolvedBackground,
          iconColor: resolvedForeground,
          style: AdaptiveButtonStyle.glass,
          size: AdaptiveButtonSize.large,
          useSmoothRectangleBorder: false,
        ),
      );
    }

    return Semantics(
      label: label,
      button: true,
      onTap: onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: AdaptiveFloatingActionButton(
          onPressed: onPressed,
          backgroundColor: resolvedBackground,
          foregroundColor: resolvedForeground,
          child: Icon(icon),
        ),
      ),
    );
  }
}
