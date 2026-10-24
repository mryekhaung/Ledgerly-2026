import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show PlatformInfo;
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/widgets/app_bottom_sheet.dart';
import 'package:ledgerly/core/widgets/list_row.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
import 'package:material_ui/material_ui.dart';

/// How a [ChoiceRow] presents its options.
enum ChoiceLayout {
  /// Opens a bottom sheet. Right for a long list (10 currencies).
  sheet,

  /// Inline segments. Right for two or three options the user compares.
  segmented,
}

/// One selectable option.
///
/// Extracted from `settings_page.dart` (`docs/Conventions.md` §1).
class Choice<T> {
  /// Creates a [Choice].
  const Choice({required this.value, required this.label});

  /// The option value.
  final T value;

  /// The visible label.
  final String label;
}

/// A settings row that picks one value from a small set.
///
/// Generic over `T`, and deliberately tolerant of a **null** value: "follow the
/// device" for the locale is a genuine choice, so the row cannot treat null as
/// "nothing selected" without making that option unreachable.
///
/// Extracted from `settings_page.dart` (`docs/Conventions.md` §1).
class ChoiceRow<T> extends StatelessWidget {
  /// Creates a [ChoiceRow].
  const ChoiceRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.body,
    this.layout = ChoiceLayout.sheet,
    super.key,
  });

  /// Row label, or null when a section header already names the row.
  final String? label;

  /// Optional supporting line under the label.
  final String? body;

  /// The current value.
  final T value;

  /// The selectable options.
  final List<Choice<T>> options;

  /// Called with the picked value.
  final ValueChanged<T> onChanged;

  /// How options are presented.
  final ChoiceLayout layout;

  /// The option whose value equals [value], or null when nothing matches.
  Choice<T>? get _selected {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (layout == ChoiceLayout.segmented) return _buildSegmented(context);

    final colors = AppThemeColors.of(context);
    final selected = _selected;

    return InkWell(
      onTap: () => _openSheet(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppRowHeight.absoluteMinimum,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (label case final label?)
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: colors.textPrimary),
                      ),
                    if (body case final body?) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        body,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                selected?.label ?? '',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(AppIcons.chevronRight, size: 20, color: colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmented(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final selected = _selected;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (label case final label?)
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: colors.textPrimary),
            ),
          if (label != null) const SizedBox(height: AppSpacing.md),
          SegmentedTabs<int>(
            tabs: <SegmentedTab<int>>[
              for (var i = 0; i < options.length; i++)
                SegmentedTab<int>(value: i, label: options[i].label),
            ],
            // Index-based selection so T may be nullable and need no equality
            // contract beyond `==` (which `CurrencyCode` etc. already have).
            // -1 selects nothing, mirroring the old empty-set selection.
            selected: selected != null ? options.indexOf(selected) : -1,
            onChanged: (index) => onChanged(options[index].value),
          ),
        ],
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final colors = AppThemeColors.of(context);
    final selected = _selected;
    final isIOS26 = PlatformInfo.isIOS26OrHigher();

    await AppBottomSheet.show<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: colors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.radiusXl),
      ),
      builder: (sheetContext) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: isIOS26 ? Colors.transparent : colors.surfaceRaised,
            borderRadius: const BorderRadius.vertical(top: AppRadius.radiusXl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Ten currencies are taller than a short phone: without
              // this the sheet overflows and the last rows are unreachable (and
              // Flutter paints the yellow-and-black overflow stripes in debug).
              // `shrinkWrap` inside a `Flexible` keeps the sheet only as tall as
              // it needs to be *up to* the available space.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.65,
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    for (final option in options)
                      ListRow(
                        title: Text(option.label),
                        trailing: option.value == selected?.value
                            ? Icon(AppIcons.check, color: colors.brandPrimary)
                            : null,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          // Guard against a no-op save: re-picking the current
                          // value would still write four rows and show "Settings
                          // saved.", which reads like a bug.
                          if (option.value != value) onChanged(option.value);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
