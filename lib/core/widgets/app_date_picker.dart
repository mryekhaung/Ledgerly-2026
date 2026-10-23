import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveDatePicker, PlatformInfo;
import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoButton,
        CupertinoDatePicker,
        CupertinoDatePickerMode,
        showCupertinoModalPopup;
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:material_ui/material_ui.dart';

/// An adaptive date picker (docs/Design.md §5).
///
/// * iOS 26+: [AdaptiveDatePicker] with native iOS 26 wheel picker.
/// * iOS < 26: Cupertino modal wheel date picker.
/// * Material / Web: Material 3 date picker dialog.
class AppDatePicker {
  const AppDatePicker._();

  /// Shows an adaptive date picker dialog or bottom sheet.
  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String? cancelLabel,
    String? doneLabel,
    AppPlatform? platform,
    bool? isIOS26,
  }) async {
    final resolvedPlatform = platform ?? AppPlatform.resolve();
    final effectiveIsIOS26 = isIOS26 ?? PlatformInfo.isIOS26OrHigher();

    if (resolvedPlatform.usesCupertino) {
      if (effectiveIsIOS26) {
        return AdaptiveDatePicker.show(
          context: context,
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
        );
      }

      DateTime tempDate = initialDate;
      final colors = AppThemeColors.of(context);

      return showCupertinoModalPopup<DateTime>(
        context: context,
        builder: (sheetContext) {
          return Container(
            height: 300,
            color: colors.surfaceRaised,
            child: SafeArea(
              top: false,
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      CupertinoButton(
                        child: Text(cancelLabel ?? 'Cancel'),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                      CupertinoButton(
                        child: Text(doneLabel ?? 'Done'),
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(tempDate),
                      ),
                    ],
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: initialDate,
                      minimumDate: firstDate,
                      maximumDate: lastDate,
                      onDateTimeChanged: (date) => tempDate = date,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      cancelText: cancelLabel,
      confirmText: doneLabel,
    );
  }
}
