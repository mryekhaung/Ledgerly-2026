import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:material_ui/material_ui.dart';

/// Single item in a [SegmentedTabs] control.
class SegmentedTab<T> {
  /// Creates a [SegmentedTab].
  const SegmentedTab({
    required this.value,
    required this.label,
    this.icon,
    this.semanticsLabel,
  });

  /// The associated value.
  final T value;

  /// Display text.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Screen reader label.
  final String? semanticsLabel;
}

/// Adaptive segmented tabs control (docs/Design.md §5.5).
///
/// * Pill shape (`radius.full`), fixed height 32 px.
/// * Label uses `AppTypography.label` token.
/// * Selected: `brandSubtle` fill + `brandPrimary` label.
/// * Unselected: `textSecondary`, transparent fill.
/// * Sliding indicator animates with `AppMotion.short` (180 ms).
/// * Max **3** segments supported; more must use a chip row (docs/Design.md §5.5).
class SegmentedTabs<T> extends StatelessWidget {
  /// Creates [SegmentedTabs].
  const SegmentedTabs({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    this.isExpanded = true,
    super.key,
  }) : assert(
         tabs.length >= 2 && tabs.length <= 3,
         'SegmentedTabs requires 2 to 3 tabs (docs/Design.md §5.5).',
       );

  /// The tab items.
  final List<SegmentedTab<T>> tabs;

  /// The currently selected value.
  final T selected;

  /// Callback when a new tab is selected.
  final ValueChanged<T> onChanged;

  /// Whether the control stretches to fill its parent's width.
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final selectedIndex = tabs.indexWhere((tab) => tab.value == selected);

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = isExpanded
            ? constraints.maxWidth
            : (tabs.length * 100.0);
        final tabWidth = (totalWidth - 4.0) / tabs.length;
        final activeIndex = selectedIndex >= 0 ? selectedIndex : 0;

        return Container(
          height: 32,
          width: isExpanded ? double.infinity : totalWidth,
          padding: const EdgeInsets.all(AppSpacing.xxs),
          decoration: BoxDecoration(
            color: colors.surfaceSubtle,
            borderRadius: AppRadius.borderFull,
          ),
          child: Stack(
            children: <Widget>[
              // Sliding active indicator
              AnimatedPositioned(
                duration: AppMotion.short,
                curve: AppMotion.standard,
                left: activeIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.brandSubtle,
                    borderRadius: AppRadius.borderFull,
                  ),
                ),
              ),
              // Interactive tabs
              Row(
                mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
                children: <Widget>[
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      flex: isExpanded ? 1 : 0,
                      child: _SegmentItem<T>(
                        tab: tabs[i],
                        isSelected: tabs[i].value == selected,
                        onTap: () {
                          if (tabs[i].value != selected) {
                            AppFeedback.selection();
                            onChanged(tabs[i].value);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );

    return content;
  }
}

class _SegmentItem<T> extends StatelessWidget {
  const _SegmentItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final SegmentedTab<T> tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final textColor = isSelected ? colors.brandPrimary : colors.textSecondary;

    return Semantics(
      label: tab.semanticsLabel ?? tab.label,
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 28,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (tab.icon != null) ...<Widget>[
                  Icon(tab.icon, size: 14, color: textColor),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  tab.label,
                  style: AppTypography.label.copyWith(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
