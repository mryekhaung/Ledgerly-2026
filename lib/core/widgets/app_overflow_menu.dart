import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:ledgerly/app/theme/app_colors.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:material_ui/material_ui.dart';

/// One action in an [AppOverflowMenu].
class OverflowMenuItem<T> {
  /// Creates an [OverflowMenuItem].
  const OverflowMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.destructive = false,
  });

  /// The value reported to [AppOverflowMenu.onSelected].
  final T value;

  /// The visible label (already localized by the caller).
  final String label;

  /// Optional leading glyph (Material branch only; the action sheet is
  /// text-first per HIG).
  final IconData? icon;

  /// Whether this action destroys data — red on both platforms.
  final bool destructive;
}

/// The row/card overflow menu: `···` button plus actions.
///
/// Platform-adaptive (`docs/Platform.md` §2 — only `core/widgets` branches on
/// platform): a Material popup menu where Material applies, a Cupertino action
/// sheet on iOS. Pages must not reach for a raw `PopupMenuButton`, which would
/// put a Material menu on iOS (enforced by Rule 12 in `design_rules_test.dart`).
class AppOverflowMenu<T> extends StatelessWidget {
  /// Creates an [AppOverflowMenu].
  const AppOverflowMenu({
    required this.items,
    required this.onSelected,
    required this.cancelLabel,
    this.icon = AppIcons.moreHorizontal,
    this.tooltip,
    this.platform,
    super.key,
  }) : assert(items.length >= 2, 'An overflow menu needs 2+ actions.');

  /// The actions.
  final List<OverflowMenuItem<T>> items;

  /// Called with the picked value.
  final ValueChanged<T> onSelected;

  /// The sheet's cancel label (already localized; iOS branch only).
  final String cancelLabel;

  /// The trigger glyph.
  final IconData icon;

  /// Accessibility hint for the trigger.
  final String? tooltip;

  /// Forces a platform so tests can render iOS chrome on any host — the same
  /// injectable-platform idiom `AppTheme.light(platform:)` uses. Null resolves
  /// the real host once via [AppPlatform.resolve].
  final AppPlatform? platform;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final resolvedPlatform = platform ?? AppPlatform.resolve();
    if (!resolvedPlatform.usesMaterial) {
      final button = CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showSheet(context, colors),
        child: Icon(icon, color: colors.textSecondary),
      );
      return tooltip == null
          ? button
          : Tooltip(message: tooltip!, child: button);
    }

    return PopupMenuButton<T>(
      icon: Icon(icon, color: colors.textSecondary),
      tooltip: tooltip,
      onSelected: onSelected,
      itemBuilder: (context) => <PopupMenuEntry<T>>[
        // Colors are resolved here, not inside the label: the popup route
        // builds above `MaterialApp`, so `AppThemeColors.of` has no scope
        // inside `itemBuilder` and would throw.
        for (final item in items)
          PopupMenuItem<T>(
            value: item.value,
            child: _MenuLabel(item: item, destructive: colors.moneyOut),
          ),
      ],
    );
  }

  Future<void> _showSheet(BuildContext context, AppColors colors) {
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        actions: <CupertinoActionSheetAction>[
          for (final item in items)
            CupertinoActionSheetAction(
              isDestructiveAction: item.destructive,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                onSelected(item.value);
              },
              child: Text(
                item.label,
                style: AppTypography.body.copyWith(
                  color: item.destructive ? colors.moneyOut : null,
                ),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: Text(cancelLabel),
        ),
      ),
    );
  }
}

/// Icon + label row for the Material branch (the pre-existing look).
class _MenuLabel<T> extends StatelessWidget {
  const _MenuLabel({required this.item, required this.destructive});

  final OverflowMenuItem<T> item;

  /// The destructive-action color, resolved by the parent (see above).
  final Color destructive;

  @override
  Widget build(BuildContext context) {
    final color = item.destructive ? destructive : null;

    if (item.icon == null) {
      return Text(item.label, style: AppTypography.body.copyWith(color: color));
    }
    return Row(
      children: <Widget>[
        Icon(item.icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Text(item.label, style: AppTypography.body.copyWith(color: color)),
      ],
    );
  }
}
