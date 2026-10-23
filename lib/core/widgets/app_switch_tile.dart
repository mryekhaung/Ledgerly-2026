import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoSwitch;
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// An adaptive switch list row (docs/Design.md §5).
///
/// * iOS: Cupertino-style switch ([CupertinoSwitch]).
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

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final resolvedPlatform = platform ?? AppPlatform.resolve();

    if (resolvedPlatform.usesCupertino) {
      final switchWidget = CupertinoSwitch(
        value: value,
        onChanged: enabled
            ? (newVal) {
                AppFeedback.selection();
                onChanged?.call(newVal);
              }
            : null,
        activeTrackColor: activeColor ?? colors.brandPrimary,
      );

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
