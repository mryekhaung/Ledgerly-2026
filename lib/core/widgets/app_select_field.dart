import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show PlatformInfo;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/widgets/app_bottom_sheet.dart';
import 'package:ledgerly/core/widgets/list_row.dart';
import 'package:material_ui/material_ui.dart';

/// One value shown by [AppSelectField].
class AppSelectOption<T> {
  /// Creates an option.
  const AppSelectOption({required this.value, required this.child});

  /// Value returned when this option is selected.
  final T value;

  /// Rich content displayed in the field and the option list.
  final Widget child;
}

/// A platform-adaptive form selector.
///
/// Material platforms retain the standard dropdown field. iOS uses a native
/// styled field that opens an adaptive sheet instead of a Material popup menu.
class AppSelectField<T> extends StatelessWidget {
  /// Creates a selector.
  const AppSelectField({
    required this.value,
    required this.options,
    required this.onChanged,
    this.decoration,
    this.platform,
    this.isIOS26,
    super.key,
  });

  /// Currently selected value.
  final T? value;

  /// Values the user may select.
  final List<AppSelectOption<T>> options;

  /// Called when an option is selected.
  final ValueChanged<T?> onChanged;

  /// Material decoration and the label/hint used by the iOS field.
  final InputDecoration? decoration;

  /// Platform override for tests.
  final AppPlatform? platform;

  /// iOS 26+ override for tests.
  final bool? isIOS26;

  AppSelectOption<T>? get _selected {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedPlatform = platform ?? AppPlatform.resolve();
    if (resolvedPlatform.usesMaterial) {
      return DropdownButtonFormField<T>(
        initialValue: value,
        decoration: decoration ?? const InputDecoration(),
        items: <DropdownMenuItem<T>>[
          for (final option in options)
            DropdownMenuItem<T>(value: option.value, child: option.child),
        ],
        onChanged: onChanged,
      );
    }

    final colors = AppThemeColors.of(context);
    final theme = Theme.of(context);
    final selected = _selected;
    final label = decoration?.labelText;
    final error = decoration?.errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Semantics(
          button: true,
          label: label,
          value: selected == null ? decoration?.hintText : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showOptions(context, resolvedPlatform),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: AppRadius.borderMd,
                border: Border.all(
                  color: error == null ? colors.border : colors.warning,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: DefaultTextStyle(
                      style: theme.textTheme.bodyLarge!.copyWith(
                        color: selected == null
                            ? colors.textTertiary
                            : colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child:
                          selected?.child ?? Text(decoration?.hintText ?? ''),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (error != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.warning),
          ),
        ],
      ],
    );
  }

  Future<void> _showOptions(
    BuildContext context,
    AppPlatform resolvedPlatform,
  ) async {
    final colors = AppThemeColors.of(context);
    final effectiveIsIOS26 = isIOS26 ?? PlatformInfo.isIOS26OrHigher();
    await AppBottomSheet.show<void>(
      context: context,
      platform: resolvedPlatform,
      isIOS26: effectiveIsIOS26,
      backgroundColor: colors.surfaceRaised,
      builder: (sheetContext) => Container(
        color: effectiveIsIOS26 ? Colors.transparent : colors.surfaceRaised,
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.65,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: <Widget>[
                for (final option in options)
                  ListRow(
                    title: option.child,
                    trailing: option.value == value
                        ? Icon(AppIcons.check, color: colors.brandPrimary)
                        : null,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      if (option.value != value) onChanged(option.value);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
