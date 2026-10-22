import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
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
/// * iOS: Cupertino-style sliding segmented control — quiet haptic, no ink.
/// * Material/Web: pill track with a sliding `brandSubtle` thumb.
/// * Label uses `AppTypography.label` token.
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
    final platform = AppPlatform.resolve();
    if (platform.usesCupertino) {
      return _CupertinoSegmentedTabs<T>(
        tabs: tabs,
        selected: selected,
        onChanged: onChanged,
        isExpanded: isExpanded,
      );
    }
    return _MaterialSegmentedTabs<T>(
      tabs: tabs,
      selected: selected,
      onChanged: onChanged,
      isExpanded: isExpanded,
    );
  }
}

/// iOS implementation — a quiet sliding thumb, no ink, no border-radius trickery.
class _CupertinoSegmentedTabs<T> extends StatelessWidget {
  const _CupertinoSegmentedTabs({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    required this.isExpanded,
  });

  final List<SegmentedTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final selectedIndex = tabs.indexWhere((tab) => tab.value == selected);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = isExpanded
            ? constraints.maxWidth
            : (tabs.length * 96.0);
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
              AnimatedPositioned(
                duration: AppMotion.short,
                curve: AppMotion.standard,
                left: activeIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    borderRadius: AppRadius.borderFull,
                    border: Border.all(color: colors.border),
                    boxShadow: AppElevation.raised(colors),
                  ),
                ),
              ),
              Row(
                mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
                children: <Widget>[
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      flex: isExpanded ? 1 : 0,
                      child: _CupertinoSegmentItem<T>(
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
  }
}

class _CupertinoSegmentItem<T> extends StatelessWidget {
  const _CupertinoSegmentItem({
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
    final textColor = isSelected ? colors.textPrimary : colors.textSecondary;

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
              children: <Widget>[
                if (tab.icon != null) ...<Widget>[
                  Icon(tab.icon, size: 14, color: textColor),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    tab.label,
                    style: AppTypography.label.copyWith(
                      color: textColor,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Material/Web implementation — the M3 pill this control started as.
class _MaterialSegmentedTabs<T> extends StatelessWidget {
  const _MaterialSegmentedTabs({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    required this.isExpanded,
  });

  final List<SegmentedTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final selectedIndex = tabs.indexWhere((tab) => tab.value == selected);

    return LayoutBuilder(
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
              Row(
                mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
                children: <Widget>[
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      flex: isExpanded ? 1 : 0,
                      child: _MaterialSegmentItem<T>(
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
  }
}

class _MaterialSegmentItem<T> extends StatelessWidget {
  const _MaterialSegmentItem({
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
    final textColor = isSelected ? colors.onBrandSubtle : colors.textSecondary;

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
              children: <Widget>[
                if (tab.icon != null) ...<Widget>[
                  Icon(tab.icon, size: 14, color: textColor),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    tab.label,
                    style: AppTypography.label.copyWith(
                      color: textColor,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
