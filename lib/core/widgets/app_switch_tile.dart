import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show IOS26Switch, PlatformInfo;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoSwitch;
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// An adaptive switch list row (docs/Design.md §5).
///
/// * iOS 26+: Native iOS 26 UISwitch with Liquid Glass ([IOS26Switch]).
/// * iOS < 26: Cupertino-style switch ([CupertinoSwitch]).
/// * Material / Web: Material 3 Switch with subtle track tint.
class AppSwitchTile extends StatelessWidget {
  /// Creates an [AppSwitchTile].
  const AppSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.contentPadding,
    this.enabled = true,
    this.activeColor,
    this.platform,
    this.isIOS26,
    super.key,
  });

  /// Primary label widget.
  final Widget title;

  /// Optional subtitle widget.
  final Widget? subtitle;

  /// Whether the switch is currently on.
  final bool value;

  /// Called when the user flips the switch.
  final ValueChanged<bool>? onChanged;

  /// Optional custom padding.
  final EdgeInsetsGeometry? contentPadding;

  /// Whether the tile is interactive.
  final bool enabled;

  /// Optional active tint color. Defaults to `colors.brandPrimary`.
  final Color? activeColor;

  /// Forces a platform so tests can render Cupertino or Material chrome on any
  /// host — the same idiom `SegmentedTabs` and `AppOverflowMenu` use.
  final AppPlatform? platform;

  /// Optional override for iOS 26+ native switch mode.
  final bool? isIOS26;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final resolvedPlatform = platform ?? AppPlatform.resolve();
    final effectiveIsIOS26 = isIOS26 ?? PlatformInfo.isIOS26OrHigher();

    if (resolvedPlatform.usesCupertino) {
      final Widget switchWidget;
      if (effectiveIsIOS26) {
        switchWidget = SizedBox(
          width: 51,
          height: 31,
          child: IOS26Switch(
            value: value,
            onChanged: enabled
                ? (newVal) {
                    AppFeedback.selection();
                    onChanged?.call(newVal);
                  }
                : null,
            activeColor: activeColor ?? colors.brandPrimary,
          ),
        );
      } else {
        switchWidget = CupertinoSwitch(
          value: value,
          onChanged: enabled
              ? (newVal) {
                  AppFeedback.selection();
                  onChanged?.call(newVal);
                }
              : null,
          activeTrackColor: activeColor ?? colors.brandPrimary,
        );
      }

      return Padding(
        padding: contentPadding ?? const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DefaultTextStyle(
                    style: AppTypography.body.copyWith(
                      color: enabled ? colors.textPrimary : colors.textTertiary,
                    ),
                    child: title,
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 4),
                    DefaultTextStyle(
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            switchWidget,
          ],
        ),
      );
    }

    return SwitchListTile(
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: enabled
          ? (newVal) {
              AppFeedback.selection();
              onChanged?.call(newVal);
            }
          : null,
      activeThumbColor: activeColor ?? colors.brandPrimary,
      contentPadding: contentPadding,
    );
  }
}
